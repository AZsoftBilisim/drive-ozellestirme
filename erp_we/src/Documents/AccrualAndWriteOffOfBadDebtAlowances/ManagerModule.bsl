#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region Public

#Region Posting

// Describes the accounting mechanisms used in the document for registration in the transaction mechanism.
//
// Parameters:
//  DocumentMechanisms - Array - list of names of accounting mechanisms that will be
//              registered in the tracking mechanism.
//
Procedure RegisterAccountingMechanisms(DocumentMechanisms) Export
	DocumentMechanisms.Add("FinancialAccounting");
	DocumentMechanisms.Add("CirculatingRegistersOfManagementAccounting");
	DocumentMechanisms.Add("LossAllowance");
	DocumentMechanisms.Add("AccountingOfIncomeExpenses");
	DocumentMechanisms.Add("DocumentsRegistry");
	DocumentMechanisms.Add("AccountingForOtherAssetsLiabilities");
	
	AccrualAndWriteOffOfBadDebtAlowancesLocalization.RegisterAccountingMechanisms(DocumentMechanisms);
	
EndProcedure

// Returns tables for movements that are necessary for conducting a document through registers of accounting mechanisms.
//
// Parameters:
//  Document - DocumentRef, DocumentObject - link to the document or object for which you want to get data
//  Registers - Structure - a list of register names for which you want to table
//  AddlParameters - Structure - additional parameters for getting data that define the context of the event.
//
// Returns:
//  Structure - collection:
//     of Table elements<Register Name> - Assignment tables - a table of data to be reflected in the register.
//
Function DocumentDataForPosting(Document, Registers, AddlParameters = Undefined) Export
	
	If AddlParameters = Undefined Then
		AddlParameters = DocumentsPosting.AdditionalParametersDocumentDataForPosting();
	EndIf;
	
	If TypeOf(Document) = Type("DocumentObject.AccrualAndWriteOffOfBadDebtAlowances") Then
		DocumentRef = Document.Ref;
	Else
		DocumentRef = Document;
	EndIf;
	
	Query			= New Query;
	QueryTexts	= New ValueList;
	
	If Not AddlParameters.GetQueryTexts Then
		////////////////////////////////////////////////////////////////////////////
		// Create a motion initialization request
		
		FillInInitializationParameters(Query, DocumentRef);
		
		////////////////////////////////////////////////////////////////////////////
		// Let's form the request text
		
		QueryTextTableRecordsCounterpartyIncomeExpenses(Query, QueryTexts, Registers);
		QueryTextTableOtherIncome(Query, QueryTexts, Registers);
		QueryTextTableOtherExpenses(Query, QueryTexts, Registers);
		QueryTextTableLossAllowance(Query, QueryTexts, Registers);
		QueryTextTableDocumentsRegistry(Query, QueryTexts, Registers);
		
		AccrualAndWriteOffOfBadDebtAlowancesLocalization.AddRequestTexts(Query,
																									QueryTexts,
																									Registers);
	EndIf;
	
	////////////////////////////////////////////////////////////////////////////
	// We will get tables for movements
	
	Return DocumentsPosting.InitializeDocumentDataForPosting(Query, QueryTexts, AddlParameters);
	
EndFunction

#EndRegion

// Prepares the data about the receivables, necessary for the calculation of reserves on doubtful debts.
// They are collected from the remaining registers on the date passed in the parameters.
// Saves the resulting result (table of values) to the passed temporary storage address.
// 
// Parameters:
// 		FillParameters - Structure - a structure containing the following keys:
//			Date - Date and time - the date on which it is necessary to get the Balances on the registers;
//			Organization - Directory link.Organizations - the organization for which you need to get data;
//			Empty Document - Boolean - if True, then this month's document does not contain any account receivable lines.
//		StorageAddress - String - the address of the temporary storage where the data for filling out accounts receivable is placed.
//
Procedure PrepareAccountsReceivableData(FillParameters, StorageAddress) Export
	
	MeasurementDetails = PerformanceMonitor.StartTimeConsumingOperationMeasurement(
		"Document.AccrualAndWriteOffOfBadDebtAlowances.Form.DocumentForm.Command.FillInAccountsReceivable");
	
	Result = GetDataForFillingAccountsReceivable(FillParameters);
	Data = Result.Unload();
	
	PutToTempStorage(Data, StorageAddress);
	
	PerformanceMonitor.EndTimeConsumingOperationMeasurement(MeasurementDetails, Data.Count() / 10);
	
EndProcedure

// Returns information about the receivables, necessary for the calculation of reserves on doubtful debts.
// Collected from the remaining registers on the date passed in the parameters.
//
// Parameters:
// 		FillParameters - Structure - a structure containing the following keys:
//			Date - Date and time - the date on which it is necessary to get the Balances on the registers;
//			Organization - Directory link.Organizations - the organization for which you need to get data;
//			Empty Document - Boolean - if True, then this month's document does not contain any account receivable lines.
// Returns:
// 		QueryResult - Data of the query result.
//
Function GetDataForFillingAccountsReceivable(FillParameters, TempTablesManager = Undefined) Export
	
	Query = New Query;
	
	If TempTablesManager = Undefined Then
		TempTablesManager = New TempTablesManager();
	EndIf;
	Query.TempTablesManager = TempTablesManager;
	Query.Text = QueryTextAccountsReceivable();
	
	Query.SetParameter("Organization", FillParameters.Organization);
	Query.SetParameter("EndOfMonth", FillParameters.Date);
	Query.SetParameter("EndOfMonthBoundary", New Boundary(FillParameters.Date,
		BoundaryType.Including)); // To receive the balances of mutual settlements including the last second of the month
	Query.SetParameter("EmptyDocument", FillParameters.EmptyDocument);
	Query.SetParameter("NewOnlineARAPAccounting", GetFunctionalOption("NewOnlineARAPAccounting"));
	Query.SetParameter("UseLoanAndDepositContracts", GetFunctionalOption("UseLoanAndDepositContracts"));
	Query.SetParameter("LocalAccountingCurrency", SettingsValueCached.CurrencyOfOrganizationSRegulatedAccounting(FillParameters.Organization));
	Query.SetParameter("TypeOfClaims", Common.MetadataObjectID("Catalog.Complaints"));
	
	ARAPAccountingServer.CalculateCustomerPaymentDates(Query.TempTablesManager, FillParameters.Date);
	ARAPAccountingServer.CalculateSupplierPaymentDates(Query.TempTablesManager, FillParameters.Date);
	
	Return Query.Execute();
	
EndFunction

// Returns data on counter (payables) required for calculating reserves for doubtful debts.
// Required only from 01.01.2017 according to paragraph 1 of article 266 of the tax code of the Russian Federation (as amended). Federal law No. 401-FZ of 30.11.2016).
//
// Parameters:
// 		FillParameters - Structure - a structure containing the following keys:
//			Date - Date and time - the date on which it is necessary to get the Balances on the registers;
//			Link - Documentlink - a link to a document whose Balances do not need to be taken into account when receiving Balances by Registers;
//			Organization - Directory link.Organizations - the organization for which you need to get data;
//			An array of counterparties - An array is an array of counterparties for which you need to get data.
// Returns:
// 		QueryResult - Data of the query result.
//
Function GetDataForFillingAccountsPayable(FillParameters) Export
	
	Query = New Query;
	Query.Text = QueryTextAccountsPayable();
	
	For Each Item In FillParameters Do
		Query.SetParameter(Item.Key, Item.Value);
	EndDo;
	
	Query.SetParameter("EndOfMonthBoundary", New Boundary(FillParameters.Date, BoundaryType.Including));
	Query.SetParameter("NewOnlineARAPAccounting", GetFunctionalOption("NewOnlineARAPAccounting"));
	
	Return Query.Execute();
	
EndFunction

// Returns an empty debt assessment table 
// 
// Returns:
//  ValueTable - empty rating table
//
Function EmptyRatingTable() Export
	
	EvaluationTable = New ValueTable;
	EvaluationTable.Columns.Add("DebtKind", New TypeDescription("EnumRef.KindsOfDebt"));
	EvaluationTable.Columns.Add("LowerBoundOfInterval", New TypeDescription("Number"));
	EvaluationTable.Columns.Add("UpperBoundOfInterval", New TypeDescription("Number"));
	EvaluationTable.Columns.Add("Evaluation", New TypeDescription("Number"));
	
	Return EvaluationTable;
	
EndFunction

// Returns the table of debt assessment in accordance with article 266 of the tax code of the Russian Federation.
//
// Returns:
// 		ValueTable - empty rating table (See EmptyRatingTable)
//
Function TaRatingTable() Export
	
	EvaluationTable = EmptyRatingTable();
	
	EvaluationIntervals = New Array;
	EvaluationIntervals.Add(GetEvaluationInterval(1, 44, 0));
	EvaluationIntervals.Add(GetEvaluationInterval(45, 90, 50));
	EvaluationIntervals.Add(GetEvaluationInterval(91, 9999999999, 100));
	
	For Each EnumerationValue In Metadata.Enums.KindsOfDebt.EnumValues Do
		If EnumerationValue.Name = "ReceivablesFromCounterpartiesLocal" Then
			For Each Interval In EvaluationIntervals Do
				NewRow = EvaluationTable.Add();
				NewRow.DebtKind = Enums.KindsOfDebt[EnumerationValue.Name];
				NewRow.LowerBoundOfInterval = Interval.Lower;
				NewRow.UpperBoundOfInterval = Interval.Upper_;
				NewRow.Evaluation = Interval.Evaluation;
			EndDo;
		Else
			NewRow = EvaluationTable.Add();
			NewRow.DebtKind = Enums.KindsOfDebt[EnumerationValue.Name];
			NewRow.LowerBoundOfInterval = 1;
			NewRow.UpperBoundOfInterval = 9999999999;
			NewRow.Evaluation = 0;
		EndIf;
	EndDo;
	
	Return EvaluationTable;
	
EndFunction

// Returns an estimate (percentage) from the transferred debt estimation table, or if no estimate table is specified, it
// first retrieves the estimate table from the accounting policy of the transferred organization for the specified period.
//
// Parameters:
// 	DebtKind - EnumRef.KindsOfDebt - type of debt to get an estimate for
// 	DoubtfulDebtPeriod - Number - number of days outstanding
// 	AdditionalParameters - Structure - structure of additional parameters of the form:
// 		Valuation table - Assignment table - Table of the procedure for assessing debt (See EmptyRatingTable)
// 		Organization - Catalog.Organization - If the evaluation table is not transmitted, it will be received for this organization
// 		Period - Date - If the evaluation table is not transmitted, it will be received on this date.
//
// Returns:
// 	Number - debt assessment (percentage)
//
Function GetEstimate(DebtKind, DoubtfulDebtPeriod, AdditionalParameters) Export

	Evaluation = 0;

	If AdditionalParameters.Property("EvaluationTable") Then
		EvaluationTable = AdditionalParameters.EvaluationTable;
	ElsIf AdditionalParameters.Property("Organization") And AdditionalParameters.Property("Period") Then 
		EvaluationTable = AccrualAndWriteOffOfBadDebtAlowancesLocalization.ACRatingTable(AdditionalParameters.Organization,
			AdditionalParameters.Period);
	Else
		EvaluationTable = EmptyRatingTable();
	EndIf;

	FoundRows = EvaluationTable.FindRows(New Structure("DebtKind", DebtKind));
	For Each FoundRow In FoundRows Do
		If
			FoundRow.LowerBoundOfInterval > DoubtfulDebtPeriod Or
			FoundRow.UpperBoundOfInterval < DoubtfulDebtPeriod
		Then
			Continue;
		EndIf;

		Evaluation = FoundRow.Evaluation;
		Break;
	EndDo;

	Return Evaluation;

EndFunction

// Returns the period for calculating reserves, or Undefined
// if no reserves are accrued starting from this period.
//
// Parameters:
// 	Organization - CatalogRef.Companies - the organization for which you want to obtain the period of calculation of reserves
// 	Period - Date - the date on which you want to retrieve information
//
// Returns:
// 	Date, Undefined - the date of the beginning of accrual of reserves or Uncertain, if reserves are not accrued
//
Function PeriodOfCalculationOfProvisionsForDoubtfulDebts(Organization, Period) Export
	
	Result = AccrualAndWriteOffOfBadDebtAlowancesLocalization.PeriodOfCalculationOfProvisionsForDoubtfulDebts(Organization, Period);
	
	AccountingPolicyParameters = AccountingPoliciesTaxSettings.CurrentParametersOfTaxesAndAccountingPoliciesAsOfDate("FinancialAccountingPolicy",
		Organization,
		Period);
		
	FormReservesForDoubtfulDebtsOfMa = ?(Not AccountingPolicyParameters = Undefined,
		AccountingPolicyParameters.ToGenerateLossAllowance, False);
	
	If FormReservesForDoubtfulDebtsOfMa Then
		Return Period;
	ElsIf ValueIsFilled(Result) Then
		Return Result;
	Else
		Return Undefined;
	EndIf;
	
EndFunction

#Region InterfaceImplementation

// Defines a list of report commands.
//
// Parameters:
//   ReportsCommands - See ReportsOptionsOverridable.BeforeAddReportCommands.ReportsCommands
//   Parameters - See ReportsOptionsOverridable.BeforeAddReportCommands.Parameters
//
Procedure AddReportCommands(ReportsCommands, Parameters) Export
	
	
	
EndProcedure

// StandardSubsystems.AccessManagement

// See AccessManagementOverridable.OnFillListsWithAccessRestriction
//
Procedure OnFillAccessRestriction(Restriction) Export
	
	Restriction.Text =
	"AllowReadUpdate
	|WHERE
	|	ValueAllowed(Organization)";
	
EndProcedure

// End StandardSubsystems.AccessManagement

// StandardSubsystems.ObjectsVersioning

// Defines object settings for the object Versioning subsystem.
//
// Parameters:
//  Settings - Structure - subsystem settings.
//
Procedure OnDefineObjectVersioningSettings(Settings) Export
	
	
	
EndProcedure

// End StandardSubsystems.ObjectsVersioning

#EndRegion

#EndRegion

#Region Private

#Region Posting

Procedure FillInInitializationParameters(Query, DocumentRef)
	
	Query.TempTablesManager = New TempTablesManager;
	Query.SetParameter("Ref", DocumentRef);
	Query.Text = 
	"SELECT
	|	DocumentData.Date AS Period,
	|	BEGINOFPERIOD(DocumentData.Date, YEAR) AS BegOfYear,
	|	DocumentData.Ref AS Ref,
	|	DocumentData.Organization AS Organization,
	|	DocumentData.PostInFinancialAccounting,
	|	DocumentData.RecordInTaxAccounting,
	|	DocumentData.RecordInManagementAccounting,
	|	CASE WHEN DocumentData.PostInFinancialAccounting THEN 1 ELSE 0 END AS ACC,
	|	CASE WHEN DocumentData.RecordInTaxAccounting THEN 1 ELSE 0 END AS TA,
	|	CASE
	|		WHEN DocumentData.RecordInManagementAccounting
	|				OR DocumentData.PostInFinancialAccounting
	|			THEN 1
	|		ELSE 0
	|	END AS MA,
	|	DocumentData.PointInTime,
	|	DocumentData.Number AS Number,
	|	DocumentData.Comment AS Comment,
	|	DocumentData.Posted AS Posted,
	|	DocumentData.DeletionMark AS DeletionMark,
	|	DocumentData.EmployeeResponsible AS EmployeeResponsible
	|
	|FROM
	|	Document.AccrualAndWriteOffOfBadDebtAlowances AS DocumentData
	|WHERE
	|	DocumentData.Ref = &Ref";
	
	Result = Query.Execute();
	Attributes = Result.Select();
	Attributes.Next();
	
	For Each Column In Result.Columns Do
		Query.SetParameter(Column.Name, Attributes[Column.Name]);
	EndDo;
		
	// Working with currency and exchange rates.
	
	Query.SetParameter("LocalAccountingCurrency", SettingsValueCached.CurrencyOfOrganizationSRegulatedAccounting(Attributes.Organization));
	Query.SetParameter("ManagementAccountingCurrency", Constants.ManagementAccountingCurrency.Get());
	
	SetRequestParametersCurrencyCoefficients(Query);
	
	CostCalculationAppliedAlgorithms.FillInInitializationParameters(Query, Attributes);
	
	AccrualAndWriteOffOfBadDebtAlowancesLocalization.AddInitializationParameters(Query, Attributes);
	
	Query.SetParameter("MetadataIdentifier", Common.MetadataObjectID("Document.AccrualAndWriteOffOfBadDebtAlowances"));
	Query.SetParameter("NumberForPrinting", ObjectsPrefixesClientServer.NumberForPrinting(Attributes.Number));
	Query.SetParameter("HouseholdOperationForRegistry", Enums.BusinessTransactions.AccrualAndWriteOffOfBadDebtAlowances);
	
EndProcedure

Procedure SetRequestParametersCurrencyCoefficients(Query)
	
	If Query.Parameters.Property("TableOfConversionFactorsToManCurrency") Then
		Return;
	EndIf;
	
	TableOfCoefficients = New ValueTable;
	TableOfCoefficients.Columns.Add("Currency", New TypeDescription("CatalogRef.Currencies"));
	TableOfCoefficients.Columns.Add("Contract", New TypeDescription("CatalogRef.CounterpartyContracts, CatalogRef.IntercompanyContracts"));
	TableOfCoefficients.Columns.Add("ContractRateOption", New TypeDescription("EnumRef.ContractRateOptions"));
	TableOfCoefficients.Columns.Add("ZoomRatio", New TypeDescription("Number"));
	
	Query.Text = 
	"SELECT DISTINCT
	|	Rows.Currency AS Currency,
	|	ARAPObjects.Contract AS Contract,
	|	ISNULL(
	|		ARAPObjects.Contract.ContractRateOption, 
	|		VALUE(Enum.ContractRateOptions.Mutable)) AS ContractRateOption
	|FROM
	|	Document.AccrualAndWriteOffOfBadDebtAlowances.AccountsReceivable AS Rows
	|		LEFT JOIN Catalog.ARAPObjects AS ARAPObjects
	|		ON Rows.ARAPObject = ARAPObjects.Ref
	|WHERE
	|	Rows.Ref = &Ref
	|
	|UNION
	|
	|SELECT DISTINCT
	|	Rows.Currency AS Currency,
	|	ARAPObjects.Contract AS Contract,
	|	ISNULL(
	|		ARAPObjects.Contract.ContractRateOption, 
	|		VALUE(Enum.ContractRateOptions.Mutable)) AS ContractRateOption
	|FROM
	|	Document.AccrualAndWriteOffOfBadDebtAlowances.PaidOffDebt AS Rows
	|		LEFT JOIN Catalog.ARAPObjects AS ARAPObjects
	|		ON Rows.ARAPObject = ARAPObjects.Ref
	|WHERE
	|	Rows.Ref = &Ref";
	
	Selection = Query.Execute().Select();
	While Selection.Next() Do
		NewRow = TableOfCoefficients.Add();
		NewRow.Currency               = Selection.Currency;
		NewRow.Contract              = Selection.Contract;
		NewRow.ContractRateOption = Selection.ContractRateOption;
		ParametersOfContractCourseOption   = ProcessingOfExchangeRatesTM.ParametersOfContractCourseOption();
		ParametersOfContractCourseOption.ContractRateOption = Selection.ContractRateOption;
		ParametersOfContractCourseOption.ARAPCurrency = Selection.Currency;
		ParametersOfContractCourseOption.Contract              = Selection.Contract;
		NewRow.ZoomRatio        = ProcessingOfExchangeRatesTM.GetConversionFactorFromCurrencyToCurrency(
			Selection.Currency,
			Query.Parameters.ManagementAccountingCurrency, 
			Query.Parameters.Period,,
			ParametersOfContractCourseOption);
	EndDo;
	
	Query.SetParameter("TableOfConversionFactorsToManCurrency",  TableOfCoefficients);
	
EndProcedure

Procedure InitializeTrackingAnalyticsKeysForPartners(Query)
	
	If Query.Parameters.Property("PartnerAccountingAnalyticsKeysInitialized_") Then
		Return;
	EndIf;
	
	QueryAnalyst = New Query;
	QueryAnalyst.Text = 
	"SELECT DISTINCT
	|	&Organization AS Organization,
	|	Reserves.Partner AS Partner,
	|	Reserves.Counterparty AS Counterparty,
	|	CASE
	|		WHEN VALUETYPE(Reserves.Contract) = TYPE(Catalog.LoanAndDepositContracts)
	|			THEN VALUE(Catalog.CounterpartyContracts.EmptyRef)
	|		WHEN VALUETYPE(Reserves.Counterparty) = TYPE(Catalog.Companies) AND Reserves.Contract = UNDEFINED
	|			THEN VALUE(Catalog.IntercompanyContracts.EmptyRef)
	|		WHEN Reserves.Contract = UNDEFINED
	|			THEN VALUE(Catalog.CounterpartyContracts.EmptyRef)
	|		ELSE
	|			Reserves.Contract
	|	END AS Contract,
	|	Reserves.LineOfBusiness AS LineOfBusiness
	|FROM
	|	Document.AccrualAndWriteOffOfBadDebtAlowances.AccountsReceivable AS Reserves
	|	LEFT JOIN InformationRegister.AccountingDimensionByPartners AS Dimension
	|		ON &Organization = Dimension.Organization
	|		AND Reserves.Counterparty = Dimension.Counterparty
	|		AND Reserves.Partner = Dimension.Partner
	|		AND CASE
	|			WHEN VALUETYPE(Reserves.Contract) = TYPE(Catalog.LoanAndDepositContracts)
	|				THEN VALUE(Catalog.CounterpartyContracts.EmptyRef)
	|			WHEN VALUETYPE(Reserves.Counterparty) = TYPE(Catalog.Companies) AND Reserves.Contract = UNDEFINED
	|				THEN VALUE(Catalog.IntercompanyContracts.EmptyRef)
	|			WHEN Reserves.Contract = UNDEFINED
	|				THEN VALUE(Catalog.CounterpartyContracts.EmptyRef)
	|			ELSE
	|				Reserves.Contract
	|		END = Dimension.Contract
	|		AND Reserves.LineOfBusiness = Dimension.LineOfBusiness
	|WHERE
	|	Reserves.Ref = &Ref
	|	AND Dimension.DimensionKey IS NULL";
	
	QueryAnalyst.SetParameter("Ref", Query.Parameters.Ref);
	QueryAnalyst.SetParameter("Organization", Query.Parameters.Organization);
	
	Selection = QueryAnalyst.Execute().Select();
	While Selection.Next() Do
		InformationRegisters.AccountingDimensionByPartners.CreateAnalyticsKey(Selection);
	EndDo;
	
	Query.SetParameter("PartnerAccountingAnalyticsKeysInitialized_", True);
	
EndProcedure

Function QueryTextTableRecordsCounterpartyIncomeExpenses(Query, QueryTexts, Registers)
	
	RegisterName = "RecordsCounterpartyIncomeExpenses";
	
	If Not DocumentsPosting.RequiresTableForRegisteredRecords(RegisterName, Registers) Then
		Return "";
	EndIf;
	
	If Not DocumentsPosting.ThereIsQueryTable("Tt_ReservesAccruedRestored", QueryTexts) Then
		RequestTextTableTTReservesAccruedRestored(Query, QueryTexts);
	EndIf;
	
	QueryText =
	"SELECT
	|	&Period AS Period,
	|	VALUE(Enum.BusinessTransactions.AccrualOfLossAllowance) AS BusinessOperation,
	|	&Organization AS Organization,
	|	Tt_ReservesAccruedRestored.Department AS Department,
	|	Tt_ReservesAccruedRestored.LineOfBusiness AS CounterpartyLineOfBusiness,
	|	
	|	CASE WHEN VALUETYPE(Tt_ReservesAccruedRestored.Counterparty) = TYPE(Catalog.Companies)
	|		THEN VALUE(Catalog.Partners.OurEnterprise)
	|		ELSE Tt_ReservesAccruedRestored.Partner
	|	END AS Partner,
	|	Tt_ReservesAccruedRestored.Counterparty AS Counterparty,
	|	Tt_ReservesAccruedRestored.Contract AS Contract,
	|	Tt_ReservesAccruedRestored.ARAPObject AS ARAPObject,
	|	
	|	Tt_ReservesAccruedRestored.LineOfBusiness AS LineOfBusinessItems,
	|	VALUE(ChartOfCharacteristicTypes.ExpenseItems.GenerateLossAllowance) AS IncomeAndExpenseItem,
	|	UNDEFINED AS DimensionOfRevenue,
	|	&Organization AS DimensionOfExpenses,
	|	UNDEFINED AS AssetsLiabilitiesDimension,
	|	
	|	Tt_ReservesAccruedRestored.AccruedMan * CASE
	|		WHEN &CompanyManagementAccounting
	|			THEN 1
	|		ELSE 0
	|	END AS Sum,
	|	0 AS AmountExcludingVAT,
	|	Tt_ReservesAccruedRestored.AccruedAC AS SumCompl,
	|	0 AS LocalAmountExcludingVAT,
	|	
	|	Tt_ReservesAccruedRestored.Currency AS Currency,
	|	Tt_ReservesAccruedRestored.Accrued AS AmountInCurrency,
	|	UNDEFINED AS ARAPCurrency,
	|	0 AS AmountInARAPCurrency,
	|	Tt_ReservesAccruedRestored.ARAPObject AS SourceOfARAPFinancialAccountingGroup
	|FROM
	|	Tt_ReservesAccruedRestored AS Tt_ReservesAccruedRestored
	|WHERE
	|	NOT Tt_ReservesAccruedRestored.AccruedAC = 0
	|	OR NOT Tt_ReservesAccruedRestored.Accrued = 0
	|
	|UNION ALL
	|
	|SELECT
	|	&Period AS Period,
	|	VALUE(Enum.BusinessTransactions.ReverseOfLossAllowance) AS BusinessOperation,
	|	&Organization AS Organization,
	|	Tt_ReservesAccruedRestored.Department AS Department,
	|	Tt_ReservesAccruedRestored.LineOfBusiness AS CounterpartyLineOfBusiness,
	|	
	|	CASE WHEN VALUETYPE(Tt_ReservesAccruedRestored.Counterparty) = TYPE(Catalog.Companies)
	|		THEN VALUE(Catalog.Partners.OurEnterprise)
	|		ELSE Tt_ReservesAccruedRestored.Partner
	|	END AS Partner,
	|	Tt_ReservesAccruedRestored.Counterparty AS Counterparty,
	|	Tt_ReservesAccruedRestored.Contract AS Contract,
	|	Tt_ReservesAccruedRestored.ARAPObject AS ARAPObject,
	|	
	|	Tt_ReservesAccruedRestored.LineOfBusiness AS LineOfBusinessItems,
	|	VALUE(ChartOfCharacteristicTypes.IncomeItems.ClosingOfBadDebtAlowances) AS IncomeAndExpenseItem,
	|	&Organization AS DimensionOfRevenue,
	|	UNDEFINED AS DimensionOfExpenses,
	|	UNDEFINED AS AssetsLiabilitiesDimension,
	|	
	|	Tt_ReservesAccruedRestored.RestoredMan * CASE
	|		WHEN &CompanyManagementAccounting
	|			THEN 1
	|		ELSE 0
	|	END AS Sum,
	|	0 AS AmountExcludingVAT,
	|	Tt_ReservesAccruedRestored.RestoredAC AS SumCompl,
	|	0 AS LocalAmountExcludingVAT,
	|	
	|	Tt_ReservesAccruedRestored.Currency AS Currency,
	|	Tt_ReservesAccruedRestored.Restored AS AmountInCurrency,
	|	UNDEFINED AS ARAPCurrency,
	|	0 AS AmountInARAPCurrency,
	|	Tt_ReservesAccruedRestored.ARAPObject AS SourceOfARAPFinancialAccountingGroup
	|FROM
	|	Tt_ReservesAccruedRestored AS Tt_ReservesAccruedRestored
	|	LEFT JOIN TT_CurrencyConversionFactorsOfMan AS TT_CurrencyConversionFactorsOfMan
	|		ON Tt_ReservesAccruedRestored.Currency = TT_CurrencyConversionFactorsOfMan.Currency
	|			AND Tt_ReservesAccruedRestored.Contract = TT_CurrencyConversionFactorsOfMan.Contract
	|WHERE
	|	NOT Tt_ReservesAccruedRestored.RestoredAC = 0
	|	OR NOT Tt_ReservesAccruedRestored.Restored = 0";
	
	QueryTexts.Add(QueryText, RegisterName);
	
	Return QueryText;

EndFunction

Function QueryTextTableOtherIncome(Query, QueryTexts, Registers)
	
	RegisterName = "OtherIncome";
	
	If Not DocumentsPosting.RequiresTableForRegisteredRecords(RegisterName, Registers) Then
		Return "";
	EndIf;
	
	If Not DocumentsPosting.ThereIsQueryTable("Tt_ReservesAccruedRestored", QueryTexts) Then
		RequestTextTableTTReservesAccruedRestored(Query, QueryTexts);
	EndIf;
	
	QueryText =
	"SELECT
	|	&Period AS Period,
	|	&Organization AS Organization,
	|	Tt_ReservesAccruedRestored.Department AS Department,
	|	Tt_ReservesAccruedRestored.LineOfBusiness AS LineOfBusiness,
	|	VALUE(ChartOfCharacteristicTypes.IncomeItems.ClosingOfBadDebtAlowances) AS IncomeItem,
	|	&Organization AS DimensionOfRevenue,
	|	
	|	Tt_ReservesAccruedRestored.RestoredMan AS Sum,
	|	Tt_ReservesAccruedRestored.RestoredAC AS SumCompl,
	|	Tt_ReservesAccruedRestored.RestoredMan * CASE
	|		WHEN &CompanyManagementAccounting
	|			THEN 1
	|		ELSE 0
	|	END AS SumMan,
	|	&PD * (Tt_ReservesAccruedRestored.RestoredAC - Tt_ReservesAccruedRestored.RestoredTa) AS PermanentDifference,
	|	&TD * (Tt_ReservesAccruedRestored.RestoredAC - Tt_ReservesAccruedRestored.RestoredTa) AS CostTD,
	|	
	|	VALUE(Enum.BusinessTransactions.ReverseOfLossAllowance) AS BusinessOperation,
	|	Tt_ReservesAccruedRestored.RowID AS FinRecordID,
	|	VALUE(Catalog.BusinessTransactionsSettings.ReverseOfLossAllowance) AS BusinessTransactionSetting 
	|	
	|FROM
	|	Tt_ReservesAccruedRestored AS Tt_ReservesAccruedRestored
	|WHERE
	|	NOT Tt_ReservesAccruedRestored.RestoredAC = 0
	|	OR NOT Tt_ReservesAccruedRestored.Restored = 0";
	
	QueryTexts.Add(QueryText, RegisterName);
	
	Return QueryText;
	
EndFunction

Function QueryTextTableOtherExpenses(Query, QueryTexts, Registers)
	
	RegisterName = "OtherExpenses";
	
	If Not DocumentsPosting.RequiresTableForRegisteredRecords(RegisterName, Registers) Then
		Return "";
	EndIf;
	
	If Not DocumentsPosting.ThereIsQueryTable("TTOtherExpenses_", QueryTexts) Then
		QueryTextTableTTOtherExpenses_(Query, QueryTexts);
	EndIf;
	
	QueryText = AccumulationRegisters.OtherExpenses.QueryTextTableOtherExpenses();
	
	QueryTexts.Add(QueryText, RegisterName);
	
	Return QueryText;
	
EndFunction

Function QueryTextTableLossAllowance(Query, QueryTexts, Registers)
	
	RegisterName = "LossAllowance";
	
	If Not DocumentsPosting.RequiresTableForRegisteredRecords(RegisterName, Registers) Then
		Return "";
	EndIf;
	
	If Not DocumentsPosting.ThereIsQueryTable("Tt_ReservesAccruedRestored", QueryTexts) Then
		RequestTextTableTTReservesAccruedRestored(Query, QueryTexts);
	EndIf;
	
	QueryText =
	"SELECT
	|	&Period AS Period,
	|	VALUE(AccumulationRecordType.Expense) AS RecordType,
	|	Tt_ReservesAccruedRestored.AccountingDimensionByPartners AS AccountingDimensionByPartners,
	|	Tt_ReservesAccruedRestored.ARAPObject AS ARAPObject,
	|	Tt_ReservesAccruedRestored.ARAPDocument AS ARAPDocument,
	|	Tt_ReservesAccruedRestored.AmountType AS AmountType,
	|	Tt_ReservesAccruedRestored.Currency AS Currency,
	|	
	|	Tt_ReservesAccruedRestored.Accrued AS Sum,
	|	Tt_ReservesAccruedRestored.AccruedAC AS SumCompl,
	|	&TD * (Tt_ReservesAccruedRestored.AccruedAC - Tt_ReservesAccruedRestored.AccruedTa) AS CostTD,
	|	&PD * (Tt_ReservesAccruedRestored.AccruedAC - Tt_ReservesAccruedRestored.AccruedTa) AS PermanentDifference,
	|	Tt_ReservesAccruedRestored.AccruedMan * CASE
	|		WHEN &CompanyManagementAccounting
	|			THEN 1
	|		ELSE 0
	|	END AS SumMan,
	|	
	|	VALUE(Enum.BusinessTransactions.AccrualOfLossAllowance) AS BusinessOperation,
	|	Tt_ReservesAccruedRestored.RowID,
	|	
	|	Tt_ReservesAccruedRestored.RowID AS FinRecordID,
	|	VALUE(Catalog.BusinessTransactionsSettings.AccrualOfLossAllowance) AS BusinessTransactionSetting 
	|	
	|FROM
	|	Tt_ReservesAccruedRestored AS Tt_ReservesAccruedRestored
	|WHERE
	|	NOT Tt_ReservesAccruedRestored.AccruedAC = 0
	|	OR NOT Tt_ReservesAccruedRestored.AccruedTa = 0
	|	OR NOT Tt_ReservesAccruedRestored.Accrued = 0
	|
	|UNION ALL
	|
	|SELECT
	|	&Period AS Period,
	|	VALUE(AccumulationRecordType.Receipt) AS RecordType,
	|	Tt_ReservesAccruedRestored.AccountingDimensionByPartners AS AccountingDimensionByPartners,
	|	Tt_ReservesAccruedRestored.ARAPObject AS ARAPObject,
	|	Tt_ReservesAccruedRestored.ARAPDocument AS ARAPDocument,
	|	Tt_ReservesAccruedRestored.AmountType AS AmountType,
	|	Tt_ReservesAccruedRestored.Currency AS Currency,
	|	
	|	Tt_ReservesAccruedRestored.Restored AS Sum,
	|	Tt_ReservesAccruedRestored.RestoredAC AS SumCompl,
	|	&TD * (Tt_ReservesAccruedRestored.RestoredAC - Tt_ReservesAccruedRestored.RestoredTa) AS CostTD,
	|	&PD * (Tt_ReservesAccruedRestored.RestoredAC - Tt_ReservesAccruedRestored.RestoredTa) AS PermanentDifference,
	|	Tt_ReservesAccruedRestored.RestoredMan * CASE
	|		WHEN &CompanyManagementAccounting
	|			THEN 1
	|		ELSE 0
	|	END AS SumMan,
	|	
	|	VALUE(Enum.BusinessTransactions.ReverseOfLossAllowance) AS BusinessOperation,
	|	Tt_ReservesAccruedRestored.RowID,
	|	
	|	Tt_ReservesAccruedRestored.RowID AS FinRecordID,
	|	VALUE(Catalog.BusinessTransactionsSettings.ReverseOfLossAllowance) AS BusinessTransactionSetting 
	|	
	|FROM
	|	Tt_ReservesAccruedRestored AS Tt_ReservesAccruedRestored
	|WHERE
	|	NOT Tt_ReservesAccruedRestored.RestoredAC = 0
	|	OR NOT Tt_ReservesAccruedRestored.RestoredTa = 0
	|	OR NOT Tt_ReservesAccruedRestored.Restored = 0
	|	
	|UNION ALL
	|	
	|SELECT
	|	&Period,
	|	VALUE(AccumulationRecordType.Expense),
	|	Tt_ReservesAccruedRestored.AccountingDimensionByPartners,
	|	Tt_ReservesAccruedRestored.ARAPObject,
	|	Tt_ReservesAccruedRestored.ARAPDocument,
	|	Tt_ReservesAccruedRestored.AmountType,
	|	Tt_ReservesAccruedRestored.Currency,
	|
	|	0,
	|	0,
	|	Tt_ReservesAccruedRestored.AmountPermanentDifferences,
	|	-Tt_ReservesAccruedRestored.AmountPermanentDifferences,
	|	0,
	|
	|	VALUE(Enum.BusinessTransactions.AccrualOfLossAllowance),
	|	Tt_ReservesAccruedRestored.RowID,
	|
	|	Tt_ReservesAccruedRestored.RowID AS FinRecordID,
	|	VALUE(Catalog.BusinessTransactionsSettings.AccrualOfLossAllowance) AS BusinessTransactionSetting
	|
	|FROM
	|	Tt_ReservesAccruedRestored AS Tt_ReservesAccruedRestored
	|WHERE
	|	&ChangedTypeOfDifferences
	|	AND Tt_ReservesAccruedRestored.AmountPermanentDifferences <> 0";
	
	QueryTexts.Add(QueryText, RegisterName);
	
	Return QueryText;
	
EndFunction

// Table of accounting Analytics for business partners.
//
Function QueryTextTTTableAccountingAnalytics(Query, QueryTexts)
	
	RegisterName = "Tt_AccountingAnalytics";
	
	InitializeTrackingAnalyticsKeysForPartners(Query);
	
	QueryText = 
	"SELECT
	|	AccountingDimensionByPartners.DimensionKey,
	|	AccountingDimensionByPartners.Partner,
	|	AccountingDimensionByPartners.Counterparty,
	|	AccountingDimensionByPartners.Contract,
	|	AccountingDimensionByPartners.LineOfBusiness
	|INTO Tt_AccountingAnalytics
	|FROM
	|	InformationRegister.AccountingDimensionByPartners AS AccountingDimensionByPartners
	|WHERE
	|	AccountingDimensionByPartners.Organization = &Organization
	|INDEX BY
	|	DimensionKey";
	
	QueryTexts.Add(QueryText, RegisterName);
	
	Return QueryText;
	
EndFunction

// Table of conversion coefficients from the possible currencies of the document's debt to the currency of management accounting.
// The table of values is initialized as a parameter of the query "table of effectientsaccountcountercountercountercountercountercountercountercountercountercountercounter".
//
Function RequestTextTableTTConversionFactorsToManCurrency(Query, QueryTexts)
	
	RegisterName = "TT_CurrencyConversionFactorsOfMan";
	
	QueryText = 
	"SELECT
	|	TableOfCoefficients.Currency,
	|	TableOfCoefficients.Contract,
	|	TableOfCoefficients.ContractRateOption,
	|	TableOfCoefficients.ZoomRatio
	|INTO TT_CurrencyConversionFactorsOfMan
	|FROM
	|	&TableOfConversionFactorsToManCurrency AS TableOfCoefficients";
	
	QueryTexts.Add(QueryText, RegisterName);
	
	Return QueryText;
	
EndFunction

// The table of reserves corresponding to the table part accounts Receivable.
// One debt can have several lines for different periods.
// 
// Parameters:
// 	Query - Query -
// 	QueryTexts - ValueList -
// Returns:
// 	String - Query text
Function QueryTextTableTTReserves(Query, QueryTexts) Export
	
	RegisterName = "Tt_Reserves";
	
	If Not DocumentsPosting.ThereIsQueryTable("Tt_AccountingAnalytics", QueryTexts) Then
		QueryTextTTTableAccountingAnalytics(Query, QueryTexts);
	EndIf;
	
	QueryText = 
	"SELECT
	|	Dimension.DimensionKey AS AccountingDimensionByPartners,
	|	CASE
	|		WHEN Rows.DebtKind = VALUE(Enum.KindsOfDebt.Other)
	|				AND Rows.ARAPObject = UNDEFINED
	|			THEN CASE
	|					WHEN VALUETYPE(Rows.Contract) = TYPE(Catalog.LoanAndDepositContracts)
	|							OR VALUETYPE(Rows.Contract) = TYPE(Catalog.LeaseContract)
	|						THEN Rows.Contract
	|					ELSE Rows.ARAPObject
	|				END
	|		ELSE Rows.ARAPObject
	|	END AS ARAPObject,
	|	Rows.ARAPDocument,
	|	Rows.AmountType,
	|	Rows.Currency,
	|	
	|	Rows.DebtAmount,
	|	Rows.AmountOfDebtLocal,
	|	Rows.AmountOfSecurity,
	|	Rows.MutualDebt,
	|	Rows.Evaluation,
	|	&ACC * Rows.ACReserve * CASE WHEN Rows.DoNotAccrue THEN 0 ELSE 1 END AS ACReserve,
	|	&TA * Rows.TAReserve * CASE WHEN Rows.DoNotAccrue THEN 0 ELSE 1 END AS TAReserve,
	|	&TA * Rows.TAReserveWithinBorderOfLimit * CASE WHEN Rows.DoNotAccrue THEN 0 ELSE 1 END AS TAReserveWithinBorderOfLimit,
	|	&MA * Rows.Reserve * CASE WHEN Rows.DoNotAccrue THEN 0 ELSE 1 END AS Reserve,
	|	
	|	Rows.DateOfDebtOccurrence,
	|	Rows.DoubtfulDebtPeriod,
	|	
	|	Rows.Partner,
	|	Rows.Counterparty,
	|	Rows.Contract,
	|	Rows.LineOfBusiness,
	|	Rows.ARAPObject.Department AS Department,
	|	
	|	Rows.RowID,
	|	Rows.LineNumber,
	|	Rows.DoNotAccrue
	|
	|INTO Tt_Reserves
	|FROM
	|	Document.AccrualAndWriteOffOfBadDebtAlowances.AccountsReceivable AS Rows
	|	LEFT JOIN Tt_AccountingAnalytics AS Dimension
	|		ON Rows.Partner = Dimension.Partner
	|		AND Rows.Counterparty = Dimension.Counterparty
	|		AND CASE
	|			WHEN VALUETYPE(Rows.Contract) = TYPE(Catalog.LoanAndDepositContracts)
	|				THEN VALUE(Catalog.CounterpartyContracts.EmptyRef)
	|			WHEN VALUETYPE(Rows.Counterparty) = TYPE(Catalog.Companies) AND Rows.Contract = UNDEFINED
	|				THEN VALUE(Catalog.IntercompanyContracts.EmptyRef)
	|			WHEN Rows.Contract = UNDEFINED
	|				THEN VALUE(Catalog.CounterpartyContracts.EmptyRef)
	|			ELSE
	|				Rows.Contract
	|		END = Dimension.Contract
	|		AND Rows.LineOfBusiness = Dimension.LineOfBusiness
	|WHERE
	|	Rows.Ref = &Ref
	|
	|UNION ALL
	|
	|SELECT
	|	Rows.AccountingDimensionByPartners,
	|	Rows.ARAPObject,
	|	Rows.ARAPDocument,
	|	Rows.AmountType,
	|	Rows.Currency,
	|	
	|	0,
	|	0,
	|	0,
	|	0,
	|	0,
	|	0,
	|	0,
	|	0,
	|	0,
	|	
	|	DATETIME(1,1,1),
	|	0,
	|	
	|	Rows.AccountingDimensionByPartners.Partner,
	|	Rows.AccountingDimensionByPartners.Counterparty,
	|	CASE
	|		WHEN VALUETYPE(Rows.ARAPObject) = TYPE(Catalog.LoanAndDepositContracts)
	|			THEN Rows.ARAPObject
	|		ELSE
	|			Rows.AccountingDimensionByPartners.Contract
	|	END,
	|	Rows.AccountingDimensionByPartners.LineOfBusiness,
	|	Rows.ARAPObject.Department,
	|	
	|	Rows.RowID,
	|	Rows.LineNumber,
	|	NULL
	|FROM
	|	Document.AccrualAndWriteOffOfBadDebtAlowances.PaidOffDebt AS Rows
	|WHERE
	|	Rows.Ref = &Ref";
	
	QueryTexts.Add(QueryText, RegisterName);
	
	Return QueryText;
	
EndFunction

// A table of reserves collapsed to each debt.
// In terms of: partner accounting Analytics, settlement Object, Settlement document, amount Type, Currency.
//
Function RequestTextTableTTReservesSummary(Query, QueryTexts)
	
	RegisterName = "Tt_ReservesSummary";
	
	If Not DocumentsPosting.ThereIsQueryTable("Tt_Reserves", QueryTexts) Then
		QueryTextTableTTReserves(Query, QueryTexts);
	EndIf;
	
	QueryText = 
	"SELECT
	|	Tt_Reserves.AccountingDimensionByPartners,
	|	Tt_Reserves.ARAPObject,
	|	Tt_Reserves.ARAPDocument,
	|	Tt_Reserves.AmountType,
	|	Tt_Reserves.Currency,
	|	
	|	SUM(Tt_Reserves.DebtAmount) AS DebtAmount,
	|	SUM(Tt_Reserves.AmountOfDebtLocal) AS AmountOfDebtLocal,
	|	SUM(Tt_Reserves.AmountOfSecurity) AS AmountOfSecurity,
	|	SUM(Tt_Reserves.MutualDebt) AS MutualDebt,
	|	SUM(Tt_Reserves.ACReserve) AS ACReserve,
	|	SUM(Tt_Reserves.TAReserve) AS TAReserve,
	|	SUM(Tt_Reserves.TAReserveWithinBorderOfLimit) AS TAReserveWithinBorderOfLimit,
	|	SUM(Tt_Reserves.Reserve) AS Reserve,
	|	
	|	MAX(Tt_Reserves.Partner) AS Partner,
	|	MAX(Tt_Reserves.Counterparty) AS Counterparty,
	|	MAX(Tt_Reserves.Contract) AS Contract,
	|	MAX(Tt_Reserves.LineOfBusiness) AS LineOfBusiness,
	|	MAX(Tt_Reserves.Department) AS Department,
	|	
	|	MAX(Tt_Reserves.RowID) AS RowID,
	|	MIN(Tt_Reserves.LineNumber) AS LineNumber
	|INTO Tt_ReservesSummary
	|FROM
	|	Tt_Reserves AS Tt_Reserves
	|GROUP BY
	|	Tt_Reserves.AccountingDimensionByPartners,
	|	Tt_Reserves.ARAPObject,
	|	Tt_Reserves.ARAPDocument,
	|	Tt_Reserves.AmountType,
	|	Tt_Reserves.Currency";
	
	QueryTexts.Add(QueryText, RegisterName);
	
	Return QueryText;
	
EndFunction

// Table of reserve balances from the reserve accumulation register for doubtful Debts.
//
Function QueryTextTableTueReserveBalances(Query, QueryTexts)
	
	RegisterName = "TT_ReserveBalances";
	
	If Not DocumentsPosting.ThereIsQueryTable("Tt_AccountingAnalytics", QueryTexts) Then
		QueryTextTTTableAccountingAnalytics(Query, QueryTexts);
	EndIf;
	
	QueryText = 
	"SELECT
	|	ReserveBalances.AccountingDimensionByPartners,
	|	ReserveBalances.ARAPObject,
	|	ReserveBalances.ARAPDocument,
	|	ReserveBalances.AmountType,
	|	ReserveBalances.Currency,
	|	
	|	&ACC * -ReserveBalances.SumComplBalance AS AmountAccounting,
	|	&TA * -(ReserveBalances.SumComplBalance - ReserveBalances.CostTDBalance - ReserveBalances.PermanentDifferenceBalance) AS AmountFA,
	|	&MA * -ReserveBalances.SumManBalance AS SumMan,
	|	&MA * -ReserveBalances.SumBalance AS Sum,
	|	- ReserveBalances.PermanentDifferenceBalance AS AmountPermanentDifferences,
	|	
	|	ISNULL(-PreviousYearSReserveBalances.SumComplBalance, 0) AS PreviousYearSReserveBalance
	|INTO TT_ReserveBalances
	|FROM
	|	AccumulationRegister.LossAllowance.Balance(&PointInTime, AccountingDimensionByPartners IN
	|		(SELECT
	|			T.DimensionKey
	|		FROM
	|			Tt_AccountingAnalytics AS T)) AS ReserveBalances
	|	LEFT JOIN AccumulationRegister.LossAllowance.Balance(&BegOfYear, AccountingDimensionByPartners IN
	|		(SELECT
	|			T.DimensionKey
	|		FROM
	|			Tt_AccountingAnalytics AS T)) AS PreviousYearSReserveBalances
	|	ON &ApplyParagraph70OfOrder34N
	|		AND ReserveBalances.AccountingDimensionByPartners = PreviousYearSReserveBalances.AccountingDimensionByPartners
	|		AND ReserveBalances.ARAPObject = PreviousYearSReserveBalances.ARAPObject
	|		AND ReserveBalances.ARAPDocument = PreviousYearSReserveBalances.ARAPDocument
	|		AND ReserveBalances.AmountType = PreviousYearSReserveBalances.AmountType
	|		AND ReserveBalances.Currency = PreviousYearSReserveBalances.Currency";
	
	QueryTexts.Add(QueryText, RegisterName);
	
	Return QueryText;
	
EndFunction

// A collapsed table of reserves, supplemented with data on reserve balances and decomposed by the amount of accrual and recovery.
// In terms of: partner accounting Analytics, settlement Object, Settlement document, amount Type, Currency.
//
// Parameters:
// 	Query - Query -
// 	QueryTexts - ValueList -
// Returns:
// 	String - Query text
Function RequestTextTableTTReservesAccruedRestored(Query, QueryTexts) Export
	
	RegisterName = "Tt_ReservesAccruedRestored";
	
	If Not DocumentsPosting.ThereIsQueryTable("Tt_ReservesSummary", QueryTexts) Then
		RequestTextTableTTReservesSummary(Query, QueryTexts);
	EndIf;
	
	If Not DocumentsPosting.ThereIsQueryTable("TT_ReserveBalances", QueryTexts) Then
		QueryTextTableTueReserveBalances(Query, QueryTexts);
	EndIf;
	
	If Not DocumentsPosting.ThereIsQueryTable("TT_CurrencyConversionFactorsOfMan", QueryTexts) Then
		RequestTextTableTTConversionFactorsToManCurrency(Query, QueryTexts);
	EndIf;
	
	QueryText =
	"SELECT
	|	Tt_ReservesSummary.AccountingDimensionByPartners,
	|	Tt_ReservesSummary.ARAPObject,
	|	Tt_ReservesSummary.ARAPDocument,
	|	Tt_ReservesSummary.AmountType,
	|	Tt_ReservesSummary.Currency,
	|	
	|	ISNULL(TT_ReserveBalances.AmountAccounting, 0) AS AccruedEarlierAC,
	|	ISNULL(TT_ReserveBalances.AmountFA, 0) AS AccruedEarlierTa,
	|	ISNULL(TT_ReserveBalances.AmountPermanentDifferences, 0) AS AmountPermanentDifferences,
	|	
	|	// Accrued
	|	
	|	(Tt_ReservesSummary.Reserve - ISNULL(TT_ReserveBalances.Sum, 0)) * CASE
	|		WHEN Tt_ReservesSummary.Reserve > ISNULL(TT_ReserveBalances.Sum, 0)
	|			THEN 1
	|		ELSE 0
	|	END AS Accrued,
	|	(Tt_ReservesSummary.ACReserve - ISNULL(TT_ReserveBalances.AmountAccounting, 0)) * CASE
	|		WHEN Tt_ReservesSummary.ACReserve > ISNULL(TT_ReserveBalances.AmountAccounting, 0)
	|			THEN 1
	|		ELSE 0
	|	END AS AccruedAC,
	|	(Tt_ReservesSummary.TAReserveWithinBorderOfLimit - ISNULL(TT_ReserveBalances.AmountFA, 0)) * CASE
	|		WHEN Tt_ReservesSummary.TAReserveWithinBorderOfLimit > ISNULL(TT_ReserveBalances.AmountFA, 0)
	|			THEN 1
	|		ELSE 0
	|	END AS AccruedTa,
	|	CAST((Tt_ReservesSummary.Reserve - ISNULL(TT_ReserveBalances.Sum, 0)) * CASE
	|		WHEN Tt_ReservesSummary.Reserve > ISNULL(TT_ReserveBalances.Sum, 0)
	|			THEN 1
	|		ELSE 0
	|	END * CASE
	|		WHEN Tt_ReservesSummary.Currency = &ManagementAccountingCurrency
	|			THEN 1
	|		ELSE ISNULL(TT_CurrencyConversionFactorsOfMan.ZoomRatio, 0)
	|	END AS NUMBER(31,2)) AS AccruedMan,
	|	
	|	// Restored
	|	
	|	(Tt_ReservesSummary.Reserve - ISNULL(TT_ReserveBalances.Sum, 0)) * CASE
	|		WHEN Tt_ReservesSummary.Reserve > ISNULL(TT_ReserveBalances.Sum, 0)
	|			THEN 0
	|		ELSE -1
	|	END AS Restored,
	|	(Tt_ReservesSummary.ACReserve - ISNULL(TT_ReserveBalances.AmountAccounting, 0)) * CASE
	|		WHEN Tt_ReservesSummary.ACReserve > ISNULL(TT_ReserveBalances.AmountAccounting, 0)
	|			THEN 0
	|		ELSE -1
	|	END AS RestoredAC,
	|	(Tt_ReservesSummary.TAReserveWithinBorderOfLimit - ISNULL(TT_ReserveBalances.AmountFA, 0)) * CASE
	|		WHEN Tt_ReservesSummary.TAReserveWithinBorderOfLimit > ISNULL(TT_ReserveBalances.AmountFA, 0)
	|			THEN 0
	|		ELSE -1
	|	END AS RestoredTa,
	|	CAST((Tt_ReservesSummary.Reserve - ISNULL(TT_ReserveBalances.Sum, 0)) * CASE
	|		WHEN Tt_ReservesSummary.Reserve > ISNULL(TT_ReserveBalances.Sum, 0)
	|			THEN 0
	|		ELSE -1
	|	END * CASE
	|		WHEN Tt_ReservesSummary.Currency = &ManagementAccountingCurrency
	|			THEN 1
	|		ELSE ISNULL(TT_CurrencyConversionFactorsOfMan.ZoomRatio, 0)
	|	END AS NUMBER(31,2)) AS RestoredMan,
	|	
	|	// Attached
	|	
	|	CASE
	|		WHEN ISNULL(TT_ReserveBalances.PreviousYearSReserveBalance, 0) > Tt_ReservesSummary.ACReserve
	|			THEN Tt_ReservesSummary.ACReserve
	|		ELSE ISNULL(TT_ReserveBalances.PreviousYearSReserveBalance, 0)
	|	END AS AttachedAC,
	|	Tt_ReservesSummary.TAReserveWithinBorderOfLimit AS AccruedSinceBeginningOfYearTa,
	|	
	|	// Related analytics
	|	
	|	Tt_ReservesSummary.AccountingDimensionByPartners.Partner AS Partner,
	|	Tt_ReservesSummary.AccountingDimensionByPartners.Counterparty AS Counterparty,
	|	CASE
	|		WHEN Tt_ReservesSummary.ARAPObject REFS Catalog.ARAPObjects
	|			THEN Tt_ReservesSummary.ARAPObject.Contract
	|		WHEN Tt_ReservesSummary.ARAPObject = UNDEFINED
	|			THEN ISNULL(Tt_ReservesSummary.AccountingDimensionByPartners.Contract, VALUE(Catalog.CounterpartyContracts.EmptyRef))
	|		ELSE Tt_ReservesSummary.ARAPObject
	|	END AS Contract,
	|	Tt_ReservesSummary.ARAPObject.LineOfBusiness AS LineOfBusiness,
	|	Tt_ReservesSummary.ARAPObject.Department AS Department,
	|	
	|	Tt_ReservesSummary.RowID AS RowID,
	|	Tt_ReservesSummary.LineNumber
	|INTO Tt_ReservesAccruedRestored
	|FROM
	|	Tt_ReservesSummary AS Tt_ReservesSummary
	|	LEFT JOIN TT_ReserveBalances AS TT_ReserveBalances
	|		ON Tt_ReservesSummary.AccountingDimensionByPartners = TT_ReserveBalances.AccountingDimensionByPartners
	|		AND Tt_ReservesSummary.ARAPObject = TT_ReserveBalances.ARAPObject
	|		AND Tt_ReservesSummary.ARAPDocument = TT_ReserveBalances.ARAPDocument
	|		AND Tt_ReservesSummary.AmountType = TT_ReserveBalances.AmountType
	|		AND Tt_ReservesSummary.Currency = TT_ReserveBalances.Currency
	|	LEFT JOIN TT_CurrencyConversionFactorsOfMan AS TT_CurrencyConversionFactorsOfMan
	|		ON Tt_ReservesSummary.Currency = TT_CurrencyConversionFactorsOfMan.Currency
	|			AND Tt_ReservesSummary.AccountingDimensionByPartners.Contract = TT_CurrencyConversionFactorsOfMan.Contract
	|WHERE
	|	NOT Tt_ReservesSummary.ACReserve = ISNULL(TT_ReserveBalances.AmountAccounting, 0)
	|	OR NOT Tt_ReservesSummary.TAReserveWithinBorderOfLimit = ISNULL(TT_ReserveBalances.AmountFA, 0)
	|	OR NOT Tt_ReservesSummary.Reserve = ISNULL(TT_ReserveBalances.Sum, 0)";
	
	QueryTexts.Add(QueryText, RegisterName);
	
	Return QueryText;
	
EndFunction

Function QueryTextTableTTInitialOtherExpenses(Query, QueryTexts)
	
	RegisterName = "TTInitialOtherExpenses";
	
	If Not DocumentsPosting.ThereIsQueryTable("Tt_ReservesAccruedRestored", QueryTexts) Then
		RequestTextTableTTReservesAccruedRestored(Query, QueryTexts);
	EndIf;
	
	QueryText =
	AccumulationRegisters.OtherExpenses.TextDescriptionTTInitialOtherExpenses() +
	TMCommonUse.QuerySeparatorInJoin() +
	"SELECT
	|	&Period AS Period,
	|	VALUE(AccumulationRecordType.Receipt) AS RecordType,
	|	&Organization AS Organization,
	|	Tt_ReservesAccruedRestored.Department AS Department,
	|	VALUE(ChartOfCharacteristicTypes.ExpenseItems.GenerateLossAllowance) AS ExpenseItem,
	|	&Organization AS DimensionOfExpenses,
	|	Tt_ReservesAccruedRestored.LineOfBusiness AS LineOfBusiness,
	|	UNDEFINED AS VATActivityType,
	|	
	|	Tt_ReservesAccruedRestored.AccruedMan * CASE
	|		WHEN &CompanyManagementAccounting
	|			THEN 1
	|		ELSE 0
	|	END AS AmountIncludingVAT,
	|	Tt_ReservesAccruedRestored.AccruedMan * CASE
	|		WHEN &CompanyManagementAccounting
	|			THEN 1
	|		ELSE 0
	|	END AS AmountExcludingVAT,
	|	Tt_ReservesAccruedRestored.AccruedMan * CASE
	|		WHEN &CompanyManagementAccounting
	|			THEN 1
	|		ELSE 0
	|	END AS AmountExcludingVATMan,
	|	Tt_ReservesAccruedRestored.AccruedAC AS AmountIncludingVATCompl,
	|	Tt_ReservesAccruedRestored.AccruedAC AS AmountExcludingVATCompl,
	|	&PD * (Tt_ReservesAccruedRestored.AccruedAC - Tt_ReservesAccruedRestored.AccruedTa) AS PermanentDifference,
	|	&TD * (Tt_ReservesAccruedRestored.AccruedAC - Tt_ReservesAccruedRestored.AccruedTa) AS CostTD,
	|	
	|	VALUE(Enum.BusinessTransactions.AccrualOfLossAllowance) AS BusinessOperation,
	|	UNDEFINED AS ItemsLocationAttributes,
	|	
	|	Tt_ReservesAccruedRestored.RowID AS FinRecordID,
	|	VALUE(Catalog.BusinessTransactionsSettings.AccrualOfLossAllowance) AS BusinessTransactionSetting
	|	
	|FROM
	|	Tt_ReservesAccruedRestored AS Tt_ReservesAccruedRestored
	|WHERE
	|	NOT Tt_ReservesAccruedRestored.AccruedAC = 0
	|	OR NOT Tt_ReservesAccruedRestored.AccruedTa = 0
	|	OR NOT Tt_ReservesAccruedRestored.Accrued = 0";
	
	QueryTexts.Add(QueryText, RegisterName);
	
	Return QueryText;
	
EndFunction

Function QueryTextTableTTOtherExpenses_(Query, QueryTexts)
	
	RegisterName = "TTOtherExpenses_";
	
	If Not DocumentsPosting.ThereIsQueryTable("TTInitialOtherExpenses", QueryTexts) Then
		QueryTextTableTTInitialOtherExpenses(Query, QueryTexts);
	EndIf;
	
	QueryText = AccumulationRegisters.OtherExpenses.QueryTextTableTTOtherExpenses_();
	QueryTexts.Add(QueryText, RegisterName);
	Return QueryText;
	
EndFunction

Function QueryTextTableDocumentsRegistry(Query, QueryTexts, Registers)
	
	RegisterName = "DocumentsRegistry";
	
	If Not DocumentsPosting.RequiresTableForRegisteredRecords(RegisterName, Registers) Then
		Return "";
	EndIf;
	
	QueryText = "
	|SELECT
	|	&MetadataIdentifier AS RefType,
	|	&HouseholdOperationForRegistry AS BusinessOperation,
	|	&Organization AS Organization,
	|	UNDEFINED AS Partner,
	|	UNDEFINED AS StorageLocation,
	|	UNDEFINED AS Counterparty,
	|	UNDEFINED AS Department,
	|	&Period AS IBDocumentDate,
	|	&Ref AS Ref,
	|	&Number AS IBDocumentNumber,
	|	UNDEFINED AS Status,
	|	&EmployeeResponsible AS EmployeeResponsible,
	|	UNDEFINED AS Author,
	|	FALSE AS AdditionalRecord,
	|	UNDEFINED AS More,
	|	&Comment AS Comment,
	|	&Posted AS Posted,
	|	&DeletionMark AS DeletionMark,
	|	&Period AS SourceDocumentDate,
	|	&NumberForPrinting AS SourceDocumentNumber,
	|	0 AS Sum,
	|	UNDEFINED AS Currency,
	|	UNDEFINED AS Contract,
	|	UNDEFINED AS LineOfBusiness,
	|	FALSE AS ReverseTransactionCorrection,
	|	UNDEFINED AS ReversedDocument,
	|	UNDEFINED AS CorrectedDocument,
	|	&Period AS RecordingInAccountingDate,
	|	UNDEFINED AS Priority";
	
	QueryTexts.Add(QueryText, RegisterName);
	
	Return QueryText;
	
EndFunction

Function AdaptedCaseSensitiveQueryText(RegisterName) Export
	
	Query = New Query;
	QueryTexts = New ValueList;
	
	FullDocumentName = "Document.AccrualAndWriteOffOfBadDebtAlowances";
	ParameterValues = New Structure;
	ParameterValues.Insert("MetadataIdentifier", Common.MetadataObjectID("Document.AccrualAndWriteOffOfBadDebtAlowances"));
	ParameterValues.Insert("HouseholdOperationForRegistry", Enums.BusinessTransactions.AccrualAndWriteOffOfBadDebtAlowances);
	
	If RegisterName = "DocumentsRegistry" Then
		QueryText = QueryTextTableDocumentsRegistry(Query, QueryTexts, RegisterName);
		SynonymForDocumentTable = "";
	Else
		ExceptionText = NStr("vi = 'Trong chứng từ %FullDocumentName% không thực hiện yêu cầu tạo bản ghi kết chuyển theo biểu ghi %RegisterName%.';
							|ru = 'В документе %FullDocumentName% не реализована адаптация текста запроса формирования движений по регистру %RegisterName%.';
							|en = 'In document %FullDocumentName%, adaptation of request for generating records of register %RegisterName% is not implemented.'; fa = 'In document %FullDocumentName%, adaptation of request for generating records of register %RegisterName% is not implemented.';
							|it = 'Nel documento %FullDocumentName% non è stato effettuato l''adattamento di testo della richiesta di generazione di movimenti sul registro%RegisterName%.';
							|pl = 'W dokumencie %FullDocumentName% nie jest realizowana adaptacja tekstu zapytania tworzenia przepływów w rejestrze %RegisterName%.';
							|tr = '%FullDocumentName%belgesinde, %RegisterName% kaydında hareketlerin oluşturulması talebinin metninin uyarlanması uygulanmamıştır.'");
		ExceptionText = StrReplace(ExceptionText, "%FullDocumentName%", FullDocumentName);
		ExceptionText = StrReplace(ExceptionText, "%RegisterName%", RegisterName);
		Raise ExceptionText;
	EndIf;
	
	If RegisterName = "DocumentsRegistry" Then
		QueryText = InfobaseUpdateTM.AdaptRequestForIndependentRegister(
			QueryText, FullDocumentName, SynonymForDocumentTable, False);
	Else
		QueryText = InfobaseUpdateTM.AdaptRequestOfHoldingMechanism(
			QueryText, FullDocumentName, SynonymForDocumentTable);
	EndIf;
	
	Result = InfobaseUpdateTM.ResultOfRequestAdaptation();
	Result.ParameterValues = ParameterValues;
	Result.QueryText = QueryText;
	
	Return Result;
	
EndFunction

#EndRegion
#Region PostingsOfReglAccounting

// The function returns the request text to reflect the document in regulated accounting.
//
// Returns:
//	String - Query text
//
Function TextOfReflectionInLocalAccounting() Export
	
	Return AccrualAndWriteOffOfBadDebtAlowancesLocalization.TextOfReflectionInLocalAccounting();
	
EndFunction

// The function returns the request text for additional temporary tables
// that are required for reflection in regulated accounting.
//
// Returns:
//   String - the generated request text.
//
Function RequestTextTTReflectedInLocalAccounting() Export
	
	Return AccrualAndWriteOffOfBadDebtAlowancesLocalization.RequestTextTTReflectedInLocalAccounting();
	
EndFunction

#EndRegion
#Region Debt_

Function QueryTextAccountsReceivable()
	
	QueryTexts = New Array;
	
	#Region PreviousDocument
	
	QueryText =
	"SELECT TOP 1
	|	AccrualAndWriteOffOfBadDebtAlowances.Ref AS Ref,
	|	AccrualAndWriteOffOfBadDebtAlowances.PointInTime AS PointInTime
	|INTO TT_PreviousDocument
	|FROM
	|	Document.AccrualAndWriteOffOfBadDebtAlowances AS AccrualAndWriteOffOfBadDebtAlowances
	|WHERE
	|	AccrualAndWriteOffOfBadDebtAlowances.Organization = &Organization
	|	AND NOT AccrualAndWriteOffOfBadDebtAlowances.DeletionMark
	|	AND (AccrualAndWriteOffOfBadDebtAlowances.Date < &EndOfMonth AND AccrualAndWriteOffOfBadDebtAlowances.Posted
	|		OR AccrualAndWriteOffOfBadDebtAlowances.Date = &EndOfMonth AND NOT &EmptyDocument)
	|ORDER BY
	|	AccrualAndWriteOffOfBadDebtAlowances.PointInTime DESC";
	
	QueryTexts.Add(QueryText);
	
	#EndRegion
	
	#Region AccountsReceivableFromDocument
	
	QueryText =
	"SELECT
	|	DocumentData.Partner AS Partner,
	|	DocumentData.Counterparty AS Counterparty,
	|	DocumentData.Contract AS Contract,
	|	DocumentData.LineOfBusiness AS LineOfBusiness,
	|	DocumentData.ARAPObject AS ARAPObject,
	|	DocumentData.ARAPDocument AS ARAPDocument,
	|	DocumentData.AmountType AS AmountType,
	|	DocumentData.DateOfDebtOccurrence AS DateOfDebtOccurrence,
	|	DocumentData.DoubtfulDebtPeriod AS DoubtfulDebtPeriod,
	|	DocumentData.DebtAmount AS DebtAmount,
	|	DocumentData.AmountOfDebtLocal AS AmountOfDebtLocal,
	|	DocumentData.AmountOfSecurityByDimension AS AmountOfSecurityByDimension,
	|	DocumentData.Evaluation AS Evaluation,
	|	DocumentData.ACReserve AS ACReserve,
	|	DocumentData.Reserve AS Reserve,
	|	DocumentData.Currency AS Currency,
	|	CASE
	|		WHEN ISNULL(DocumentData.ARAPObject.RefType,
	|			VALUE(Catalog.MetadataObjectIDs.EmptyRef)) = &TypeOfClaims
	|		THEN VALUE(Enum.KindsOfDebt.Other)
	|		ELSE DocumentData.DebtKind
	|	END AS DebtKind,
	|	DocumentData.DoNotAccrue AS DoNotAccrue,
	|	DocumentData.ManualAdjustment AS ManualAdjustment
	|INTO Tt_DocumentData
	|FROM
	|	Document.AccrualAndWriteOffOfBadDebtAlowances.AccountsReceivable AS DocumentData
	|		INNER JOIN TT_PreviousDocument AS TT_PreviousDocument
	|		ON DocumentData.Ref = TT_PreviousDocument.Ref";
	
	QueryTexts.Add(QueryText);
	
	#EndRegion
	
	#Region AccountsReceivableFromRegisters
	
	#Region FinancialInstrumentsARAP
	
	QueryText =
	"SELECT ALLOWED
	|	LoanAndDepositContracts.Ref AS Ref,
	|	LoanAndDepositContracts.ARAPCurrency AS Currency,
	|	LoanAndDepositContracts.ContractKind AS ContractKind
	|INTO TT_LoanAndDepositContracts
	|FROM
	|	Catalog.LoanAndDepositContracts AS LoanAndDepositContracts
	|WHERE
	|	&UseLoanAndDepositContracts
	|	AND LoanAndDepositContracts.Organization = &Organization
	|	AND LoanAndDepositContracts.ContractKind IN (VALUE(Enum.ContractKindsOfFinancialInstruments.Deposit), VALUE(Enum.ContractKindsOfFinancialInstruments.IssuedBorrowing))
	|
	|INDEX BY
	|	Ref,
	|	Currency
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT ALLOWED
	|	TT_LoanAndDepositContracts.Ref AS Ref,
	|	TT_LoanAndDepositContracts.Currency AS Currency,
	|	TT_LoanAndDepositContracts.ContractKind AS ContractKind
	|INTO Tt_LoanAndDepositAgreementsIssued
	|FROM
	|	AccumulationRegister.FinancialInstrumentsARAP.Balance(
	|			&EndOfMonthBoundary,
	|			(Contract, Currency) IN
	|				(SELECT
	|					TT_LoanAndDepositContracts.Ref AS Ref,
	|					TT_LoanAndDepositContracts.Currency AS Currency
	|				FROM
	|					TT_LoanAndDepositContracts AS TT_LoanAndDepositContracts)) AS FinancialInstrumentsARAPBalance
	|		INNER JOIN TT_LoanAndDepositContracts AS TT_LoanAndDepositContracts
	|		ON FinancialInstrumentsARAPBalance.Contract = TT_LoanAndDepositContracts.Ref
	|			AND FinancialInstrumentsARAPBalance.Currency = TT_LoanAndDepositContracts.Currency
	|WHERE
	|	FinancialInstrumentsARAPBalance.SumBalance <> 0
	|
	|INDEX BY
	|	Ref,
	|	Currency
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|DROP TT_LoanAndDepositContracts
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT ALLOWED
	|	Calculations.Contract AS Contract,
	|	Calculations.Currency AS Currency,
	|	Calculations.AmountType AS AmountType,
	|	Calculations.SumExpense AS Sum
	|INTO Tt_ReceiptOfFunds
	|FROM
	|	AccumulationRegister.FinancialInstrumentsARAP.Turnovers(, &EndOfMonthBoundary,, Contract IN
	|		(SELECT
	|			T.Ref
	|		FROM
	|			Tt_LoanAndDepositAgreementsIssued AS T)) AS Calculations
	|WHERE
	|	Calculations.SumExpense > 0
	|;
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT ALLOWED
	|	Tt_LoanAndDepositAgreementsIssued.Ref AS Contract,
	|	Tt_LoanAndDepositAgreementsIssued.Currency,
	|	Tt_LoanAndDepositAgreementsIssued.ContractKind,
	|	VALUE(Enum.LoanAndDepositScheduleAmountTypes.PrincipalDebt) AS AmountType,
	|	Schedule.Period AS DateOfDebtOccurrence,
	|	CASE
	|		WHEN Schedule.AmountTotal - Schedule.Sum - ISNULL(Tt_ReceiptOfFunds.Sum, 0) < 0
	|			THEN Schedule.AmountTotal - ISNULL(Tt_ReceiptOfFunds.Sum, 0)
	|		ELSE Schedule.Sum
	|	END AS DebtAmount
	|INTO TT_DebtSettlementsOnFinancialInstruments
	|FROM
	|	InformationRegister.ScheduleOfPaymentForLoansAndDeposits AS Schedule
	|		INNER JOIN Tt_LoanAndDepositAgreementsIssued AS Tt_LoanAndDepositAgreementsIssued
	|		ON Schedule.ScheduleOption.Owner = Tt_LoanAndDepositAgreementsIssued.Ref
	|		LEFT JOIN Tt_ReceiptOfFunds AS Tt_ReceiptOfFunds
	|		ON Tt_ReceiptOfFunds.Contract = Tt_LoanAndDepositAgreementsIssued.Ref
	|		AND Tt_ReceiptOfFunds.Currency = Tt_LoanAndDepositAgreementsIssued.Currency
	|		AND Tt_ReceiptOfFunds.AmountType = VALUE(Enum.LoanAndDepositScheduleAmountTypes.PrincipalDebt)
	|WHERE
	|	Schedule.ScheduleOption.Used
	|	AND NOT Schedule.ScheduleOption.DeletionMark
	|	AND Schedule.Sum > 0
	|	AND Schedule.AmountTotal - ISNULL(Tt_ReceiptOfFunds.Sum, 0) > 0
	|	AND Schedule.Period <= &EndOfMonth
	|
	|UNION ALL
	|
	|SELECT
	|	Tt_LoanAndDepositAgreementsIssued.Ref,
	|	Tt_LoanAndDepositAgreementsIssued.Currency,
	|	Tt_LoanAndDepositAgreementsIssued.ContractKind,
	|	VALUE(Enum.LoanAndDepositScheduleAmountTypes.Interests),
	|	Schedule.Period,
	|	CASE
	|		WHEN Schedule.InterestTotal - Schedule.Interests - ISNULL(Tt_ReceiptOfFunds.Sum, 0) < 0
	|			THEN Schedule.InterestTotal - ISNULL(Tt_ReceiptOfFunds.Sum, 0)
	|		ELSE Schedule.Interests
	|	END
	|FROM
	|	InformationRegister.ScheduleOfPaymentForLoansAndDeposits AS Schedule
	|		INNER JOIN Tt_LoanAndDepositAgreementsIssued AS Tt_LoanAndDepositAgreementsIssued
	|		ON Schedule.ScheduleOption.Owner = Tt_LoanAndDepositAgreementsIssued.Ref
	|		LEFT JOIN Tt_ReceiptOfFunds AS Tt_ReceiptOfFunds
	|		ON Tt_ReceiptOfFunds.Contract = Tt_LoanAndDepositAgreementsIssued.Ref
	|		AND Tt_ReceiptOfFunds.Currency = Tt_LoanAndDepositAgreementsIssued.Currency
	|		AND Tt_ReceiptOfFunds.AmountType = VALUE(Enum.LoanAndDepositScheduleAmountTypes.Interests)
	|WHERE
	|	Schedule.ScheduleOption.Used
	|	AND NOT Schedule.ScheduleOption.DeletionMark
	|	AND Schedule.Interests > 0
	|	AND Schedule.InterestTotal - ISNULL(Tt_ReceiptOfFunds.Sum, 0) > 0
	|	AND Schedule.Period <= &EndOfMonth
	|;
	|////////////////////////////////////////////////////////////////////////////////
	|DROP Tt_LoanAndDepositAgreementsIssued
	|;
	|////////////////////////////////////////////////////////////////////////////////
	|DROP Tt_ReceiptOfFunds";
	
	QueryTexts.Add(QueryText);
	
	#EndRegion
	
	#Region DimensionAccounting_1
	
	QueryText =
	"SELECT ALLOWED
	|	AccountingDimensionByPartners.DimensionKey AS DimensionKey
	|INTO Tt_AccountingAnalytics
	|FROM
	|	InformationRegister.AccountingDimensionByPartners AS AccountingDimensionByPartners
	|WHERE
	|	AccountingDimensionByPartners.Organization = &Organization
	|INDEX BY
	|	DimensionKey";
	
	QueryTexts.Add(QueryText);
	
	#EndRegion
	
	#Region ExchangeRates
	
	// We will get the exchange rates for each date of occurrence of arrears
	// in the currency of mutual settlements and the currency of regulated accounting.
	
	QueryTextExchangeRates =
	"SELECT DISTINCT
	|	TT_DebtSettlementsOnFinancialInstruments.DateOfDebtOccurrence AS Period,
	|	TT_DebtSettlementsOnFinancialInstruments.Currency AS Currency
	|INTO TT_CurrencyPeriods
	|FROM
	|	TT_DebtSettlementsOnFinancialInstruments AS TT_DebtSettlementsOnFinancialInstruments
	|
	|UNION
	|
	|SELECT DISTINCT
	|	TT_DebtSettlementsOnFinancialInstruments.DateOfDebtOccurrence,
	|	&LocalAccountingCurrency
	|FROM
	|	TT_DebtSettlementsOnFinancialInstruments AS TT_DebtSettlementsOnFinancialInstruments
	|
	|INDEX BY
	|	Currency
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	TT_CurrencyPeriods.Period AS Period,
	|	TT_CurrencyPeriods.Currency AS Currency,
	|	MAX(ExchangeRates.Period) AS RatePeriod
	|INTO TT_CoursePeriods
	|FROM
	|	TT_CurrencyPeriods AS TT_CurrencyPeriods
	|		INNER JOIN InformationRegister.RelativeExchangeRates AS ExchangeRates
	|		ON TT_CurrencyPeriods.Currency = ExchangeRates.Currency
	|			AND TT_CurrencyPeriods.Period >= ExchangeRates.Period
	|			AND ExchangeRates.BaseCurrency = &LocalAccountingCurrency
	|
	|GROUP BY
	|	TT_CurrencyPeriods.Period,
	|	TT_CurrencyPeriods.Currency
	|
	|INDEX BY
	|	Currency,
	|	RatePeriod
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	TT_CoursePeriods.Period AS Period,
	|	TT_CoursePeriods.Currency AS Currency,
	|	ExchangeRates.CourseNumerator AS CourseNumerator,
	|	ExchangeRates.CourseDenominator AS CourseDenominator
	|INTO TT__ExchangeRates
	|FROM
	|	TT_CoursePeriods AS TT_CoursePeriods
	|		INNER JOIN InformationRegister.RelativeExchangeRates AS ExchangeRates
	|		ON TT_CoursePeriods.Currency = ExchangeRates.Currency
	|			AND TT_CoursePeriods.RatePeriod = ExchangeRates.Period
	|			AND ExchangeRates.BaseCurrency = &LocalAccountingCurrency";
	
	QueryTexts.Add(QueryTextExchangeRates);
	
	#EndRegion
	
	#Region CustomersARAPAccounting
	
	// The query uses a temporary table from the Mutual Settlement Server.Calculate the customer's payment.
	
	QueryText =
	"SELECT ALLOWED
	|	CustomersARAPAccountingByDueDatesBalance.AccountingDimensionByPartners AS AccountingDimensionByPartners,
	|	CustomersARAPAccountingByDueDatesBalance.ARAPObject AS ARAPObject,
	|	CustomersARAPAccountingByDueDatesBalance.ARAPDocument AS ARAPDocument,
	|	CustomersARAPAccountingByDueDatesBalance.Currency AS Currency,
	|	CustomersARAPAccountingByDueDatesBalance.PlannedRepaymentDate AS DateOfDebtOccurrence,
	|	CustomersARAPAccountingByDueDatesBalance.DebtLocalBalance AS AmountOfDebtLocal,
	|	CustomersARAPAccountingByDueDatesBalance.DebtBalance AS DebtAmount
	|INTO TT_DebtSettlementsWithCustomers
	|FROM
	|	AccumulationRegister.CustomersARAPAccountingByDueDates.Balance(&EndOfMonthBoundary, AccountingDimensionByPartners IN
	|		(SELECT
	|			T.DimensionKey
	|		FROM
	|			Tt_AccountingAnalytics AS T)
	|	AND NOT ARAPObject = UNDEFINED
	|	AND NOT PlannedRepaymentDate = DATETIME(1, 1, 1)) AS CustomersARAPAccountingByDueDatesBalance
	|WHERE
	|	CustomersARAPAccountingByDueDatesBalance.DebtLocalBalance > 0
	|	AND &NewOnlineARAPAccounting
	|
	|UNION ALL
	|
	|SELECT
	|	CustomersARAPAccountingByDocumentsBalance.AccountingDimensionByPartners AS AccountingDimensionByPartners,
	|	CustomersARAPAccountingByDocumentsBalance.SalesOrder AS ARAPObject,
	|	CustomersARAPAccountingByDocumentsBalance.ARAPDocument AS ARAPDocument,
	|	CustomersARAPAccountingByDocumentsBalance.Currency AS Currency,
	|	BEGINOFPERIOD(BalanceTable.PaymentDate, DAY) AS DateOfDebtOccurrence,
	|	CustomersARAPAccountingByDocumentsBalance.DebtLocalBalance AS AmountOfDebtLocal,
	|	CustomersARAPAccountingByDocumentsBalance.DebtBalance AS DebtAmount
	|FROM
	|	AccumulationRegister.CustomersARAPAccountingByDocuments.Balance(
	|			&EndOfMonthBoundary,
	|			AccountingDimensionByPartners IN (
	|				SELECT
	|					T.DimensionKey
	|				FROM
	|					Tt_AccountingAnalytics AS T)) AS CustomersARAPAccountingByDocumentsBalance
	|		INNER JOIN CustomerBalanceTable AS BalanceTable
	|		ON CustomersARAPAccountingByDocumentsBalance.AccountingDimensionByPartners = BalanceTable.AccountingDimensionByPartners
	|			AND CustomersARAPAccountingByDocumentsBalance.SalesOrder = BalanceTable.SalesOrder
	|			AND CustomersARAPAccountingByDocumentsBalance.ARAPDocument = BalanceTable.ARAPDocument
	|			AND CustomersARAPAccountingByDocumentsBalance.Currency = BalanceTable.Currency
	|WHERE
	|	CustomersARAPAccountingByDocumentsBalance.DebtLocalBalance > 0
	|	AND CustomersARAPAccountingByDocumentsBalance.SalesOrder.Object <> UNDEFINED
	|	AND NOT &NewOnlineARAPAccounting";
	
	QueryTexts.Add(QueryText);
	
	#EndRegion
	
	#Region VendorsARAPAccounting
	
	// Since at the moment there is no information about the planned date of offset of the advance,
	// we consider the date of receipt of the advance as the date of occurrence of the debt.
	
	QueryText =
	"SELECT ALLOWED
	|	VendorsARAPAccountingByDocumentsBalance.AccountingDimensionByPartners AS AccountingDimensionByPartners,
	|	VendorsARAPAccountingByDocumentsBalance.PurchaseOrder AS PurchaseOrder,
	|	VendorsARAPAccountingByDocumentsBalance.ARAPDocument AS ARAPDocument,
	|	VendorsARAPAccountingByDocumentsBalance.Currency AS Currency,
	|	VendorsARAPAccountingByDocumentsBalance.PrepaymentLocalBalance AS PrepaymentLocalBalance,
	|	VendorsARAPAccountingByDocumentsBalance.PrepaymentBalance AS PrepaymentBalance
	|INTO Tt_SettlementsWithSuppliersBasedOnDocumentsBalances
	|FROM
	|	AccumulationRegister.VendorsARAPAccountingByDocuments.Balance(
	|			&EndOfMonthBoundary,
	|			AccountingDimensionByPartners IN
	|					(SELECT
	|						T.DimensionKey
	|					FROM
	|						Tt_AccountingAnalytics AS T)
	|				AND NOT PurchaseOrder.Object = UNDEFINED) AS VendorsARAPAccountingByDocumentsBalance
	|WHERE
	|	VendorsARAPAccountingByDocumentsBalance.PrepaymentLocalBalance > 0
	|	AND NOT &NewOnlineARAPAccounting
	|
	|INDEX BY
	|	AccountingDimensionByPartners,
	|	PurchaseOrder,
	|	ARAPDocument,
	|	Currency
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT ALLOWED
	|	Balance.AccountingDimensionByPartners AS AccountingDimensionByPartners,
	|	Balance.PurchaseOrder AS PurchaseOrder,
	|	Balance.ARAPDocument AS ARAPDocument,
	|	Balance.Currency AS Currency,
	|	MIN(ISNULL(VendorsARAPAccountingByDocuments.Period, DATETIME(1, 1, 1))) AS Period
	|INTO TT_SupplierPeriods
	|FROM
	|	AccumulationRegister.VendorsARAPAccountingByDocuments AS VendorsARAPAccountingByDocuments
	|		LEFT JOIN Tt_SettlementsWithSuppliersBasedOnDocumentsBalances AS Balance
	|		ON VendorsARAPAccountingByDocuments.AccountingDimensionByPartners = Balance.AccountingDimensionByPartners
	|			AND VendorsARAPAccountingByDocuments.PurchaseOrder = Balance.PurchaseOrder
	|			AND VendorsARAPAccountingByDocuments.ARAPDocument = Balance.ARAPDocument
	|			AND VendorsARAPAccountingByDocuments.Currency = Balance.Currency
	|WHERE
	|	VendorsARAPAccountingByDocuments.RecordType = VALUE(AccumulationRecordType.Receipt)
	|	AND VendorsARAPAccountingByDocuments.PrepaymentLocal > 0
	|
	|GROUP BY
	|	Balance.AccountingDimensionByPartners,
	|	Balance.PurchaseOrder,
	|	Balance.Currency,
	|	Balance.ARAPDocument
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT ALLOWED
	|	VendorsARAPAccountingByDueDatesBalance.AccountingDimensionByPartners AS AccountingDimensionByPartners,
	|	VendorsARAPAccountingByDueDatesBalance.ARAPObject AS ARAPObject,
	|	VendorsARAPAccountingByDueDatesBalance.ARAPDocument AS ARAPDocument,
	|	VendorsARAPAccountingByDueDatesBalance.Currency AS Currency,
	|	CASE
	|		WHEN VendorsARAPAccountingByDueDatesBalance.PlannedRepaymentDate = DATETIME(1, 1, 1)
	|			THEN VendorsARAPAccountingByDueDatesBalance.OccurrenceDate
	|		ELSE VendorsARAPAccountingByDueDatesBalance.PlannedRepaymentDate
	|	END AS DateOfDebtOccurrence,
	|	VendorsARAPAccountingByDueDatesBalance.PrepaymentLocalBalance AS AmountOfDebtLocal,
	|	VendorsARAPAccountingByDueDatesBalance.PrepaymentBalance AS DebtAmount
	|INTO TT_DebtSettlementsWithSuppliers
	|FROM
	|	AccumulationRegister.VendorsARAPAccountingByDueDates.Balance(
	|			&EndOfMonthBoundary,
	|			AccountingDimensionByPartners IN
	|				(SELECT
	|					T.DimensionKey
	|				FROM
	|					Tt_AccountingAnalytics AS T)) AS VendorsARAPAccountingByDueDatesBalance
	|WHERE
	|	VendorsARAPAccountingByDueDatesBalance.PrepaymentLocalBalance > 0
	|	AND &NewOnlineARAPAccounting
	|
	|UNION ALL
	|
	|SELECT
	|	VendorsARAPAccountingByDocumentsBalance.AccountingDimensionByPartners,
	|	VendorsARAPAccountingByDocumentsBalance.PurchaseOrder,
	|	VendorsARAPAccountingByDocumentsBalance.ARAPDocument,
	|	VendorsARAPAccountingByDocumentsBalance.Currency,
	|	BEGINOFPERIOD(TT_SupplierPeriods.Period, DAY),
	|	VendorsARAPAccountingByDocumentsBalance.PrepaymentLocalBalance,
	|	VendorsARAPAccountingByDocumentsBalance.PrepaymentBalance
	|FROM
	|	Tt_SettlementsWithSuppliersBasedOnDocumentsBalances AS VendorsARAPAccountingByDocumentsBalance
	|		INNER JOIN TT_SupplierPeriods AS TT_SupplierPeriods
	|		ON VendorsARAPAccountingByDocumentsBalance.AccountingDimensionByPartners = TT_SupplierPeriods.AccountingDimensionByPartners
	|			AND VendorsARAPAccountingByDocumentsBalance.PurchaseOrder = TT_SupplierPeriods.PurchaseOrder
	|			AND VendorsARAPAccountingByDocumentsBalance.ARAPDocument = TT_SupplierPeriods.ARAPDocument
	|			AND VendorsARAPAccountingByDocumentsBalance.Currency = TT_SupplierPeriods.Currency
	|WHERE
	|	VendorsARAPAccountingByDocumentsBalance.PrepaymentLocalBalance > 0
	|	AND NOT &NewOnlineARAPAccounting";
	
	QueryTexts.Add(QueryText);
	
	#EndRegion
	
	#Region CalculationsAssociation
	
	QueryText =
	"SELECT ALLOWED
	|	Calculations.AccountingDimensionByPartners.Partner AS Partner,
	|	Calculations.AccountingDimensionByPartners.Counterparty AS Counterparty,
	|	Calculations.AccountingDimensionByPartners.Contract AS Contract,
	|	Calculations.AccountingDimensionByPartners.LineOfBusiness AS LineOfBusiness,
	|	Calculations.ARAPObject,
	|	Calculations.ARAPDocument,
	|	VALUE(Enum.LoanAndDepositScheduleAmountTypes.EmptyRef) AS AmountType,
	|	CASE
	|		WHEN Calculations.Currency = &LocalAccountingCurrency
	|			THEN VALUE(Enum.KindsOfDebt.ReceivablesFromCounterpartiesLocal)
	|		ELSE VALUE(Enum.KindsOfDebt.CounterpartyAccountsReceivablesInForeignCurrency)
	|	END AS DebtKind,
	|	Calculations.DateOfDebtOccurrence,
	|	Calculations.AmountOfDebtLocal,
	|	Calculations.DebtAmount,
	|	Calculations.Currency,
	|	CASE
	|		WHEN Calculations.Currency = &LocalAccountingCurrency
	|			THEN FALSE
	|		ELSE TRUE
	|	END AS DoNotAccrue
	|INTO TT_RegisterEntries
	|FROM
	|	TT_DebtSettlementsWithCustomers AS Calculations
	|
	|UNION ALL
	|
	|SELECT
	|	Calculations.AccountingDimensionByPartners.Partner AS Partner,
	|	Calculations.AccountingDimensionByPartners.Counterparty AS Counterparty,
	|	Calculations.AccountingDimensionByPartners.Contract AS Contract,
	|	Calculations.AccountingDimensionByPartners.LineOfBusiness AS LineOfBusiness,
	|	Calculations.ARAPObject,
	|	Calculations.ARAPDocument,
	|	VALUE(Enum.LoanAndDepositScheduleAmountTypes.EmptyRef),
	|	VALUE(Enum.KindsOfDebt.PrepaymentsToVendor_),
	|	Calculations.DateOfDebtOccurrence,
	|	Calculations.AmountOfDebtLocal,
	|	Calculations.DebtAmount,
	|	Calculations.Currency,
	|	TRUE
	|FROM
	|	TT_DebtSettlementsWithSuppliers AS Calculations
	|
	|UNION ALL
	|
	|SELECT
	|	Calculations.Contract.Partner,
	|	Calculations.Contract.Counterparty,
	|	Calculations.Contract,
	|	Calculations.Contract.LineOfBusiness,
	|	Calculations.Contract,
	|	UNDEFINED,
	|	Calculations.AmountType,
	|	CASE
	|		WHEN Calculations.ContractKind = VALUE(Enum.ContractKindsOfFinancialInstruments.Deposit)
	|			THEN VALUE(Enum.KindsOfDebt.PrepaymentsToVendor_)
	|		ELSE VALUE(Enum.KindsOfDebt.IssuedBorrowings)
	|	END,
	|	Calculations.DateOfDebtOccurrence,
	|	CASE
	|		WHEN Calculations.Currency = &LocalAccountingCurrency
	|			THEN Calculations.DebtAmount
	|		WHEN ExchangeRates.Period IS NULL
	|			THEN 0
	|		WHEN LocalExchangeRates.Period IS NULL
	|			THEN 0
	|		ELSE CAST(Calculations.DebtAmount
	|				* ISNULL(ExchangeRates.CourseNumerator, 0) / ISNULL(ExchangeRates.CourseDenominator, 0)
	|				/ ISNULL(LocalExchangeRates.CourseNumerator, 0) * ISNULL(LocalExchangeRates.CourseDenominator, 0) AS NUMBER(31, 2))
	|	END AS AmountOfDebtLocal,
	|	Calculations.DebtAmount,
	|	Calculations.Currency,
	|	TRUE
	|FROM
	|	TT_DebtSettlementsOnFinancialInstruments AS Calculations
	|	LEFT JOIN TT__ExchangeRates AS ExchangeRates
	|		ON Calculations.Currency = ExchangeRates.Currency
	|		AND Calculations.DateOfDebtOccurrence = ExchangeRates.Period
	|	LEFT JOIN TT__ExchangeRates AS LocalExchangeRates
	|		ON &LocalAccountingCurrency = LocalExchangeRates.Currency
	|		AND Calculations.DateOfDebtOccurrence = LocalExchangeRates.Period
	|;
	|////////////////////////////////////////////////////////////////////////////////
	|DROP TT_DebtSettlementsOnFinancialInstruments
	|;
	|////////////////////////////////////////////////////////////////////////////////
	|DROP Tt_AccountingAnalytics
	|;
	|////////////////////////////////////////////////////////////////////////////////
	|DROP TT_DebtSettlementsWithCustomers
	|;
	|////////////////////////////////////////////////////////////////////////////////
	|DROP TT_DebtSettlementsWithSuppliers
	|;
	|////////////////////////////////////////////////////////////////////////////////
	|DROP TT_CurrencyPeriods
	|;
	|////////////////////////////////////////////////////////////////////////////////
	|DROP TT_CoursePeriods
	|;
	|////////////////////////////////////////////////////////////////////////////////
	|DROP TT__ExchangeRates
	|;
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	TT_RegisterEntries.Partner,
	|	TT_RegisterEntries.Counterparty,
	|	TT_RegisterEntries.Contract,
	|	TT_RegisterEntries.LineOfBusiness,
	|	TT_RegisterEntries.ARAPObject,
	|	TT_RegisterEntries.ARAPDocument,
	|	TT_RegisterEntries.AmountType,
	|	CASE
	|		WHEN ISNULL(ARAPObjects.RefType,
	|			VALUE(Catalog.MetadataObjectIDs.EmptyRef)) = &TypeOfClaims
	|		THEN VALUE(Enum.KindsOfDebt.Other)
	|		ELSE TT_RegisterEntries.DebtKind
	|	END AS DebtKind,
	|	TT_RegisterEntries.DateOfDebtOccurrence,
	|	TT_RegisterEntries.Currency,
	|	SUM(TT_RegisterEntries.AmountOfDebtLocal) AS AmountOfDebtLocal,
	|	SUM(TT_RegisterEntries.DebtAmount) AS DebtAmount,
	|	MAX(TT_RegisterEntries.DoNotAccrue) AS DoNotAccrue
	|INTO TT_RegisterData
	|FROM
	|	TT_RegisterEntries AS TT_RegisterEntries
	|	LEFT JOIN Catalog.ARAPObjects AS ARAPObjects
	|		ON TT_RegisterEntries.ARAPObject = ARAPObjects.Ref
	|GROUP BY
	|	TT_RegisterEntries.Partner,
	|	TT_RegisterEntries.Counterparty,
	|	TT_RegisterEntries.Contract,
	|	TT_RegisterEntries.LineOfBusiness,
	|	TT_RegisterEntries.ARAPObject,
	|	TT_RegisterEntries.ARAPDocument,
	|	TT_RegisterEntries.AmountType,
	|	CASE
	|		WHEN ISNULL(ARAPObjects.RefType,
	|			VALUE(Catalog.MetadataObjectIDs.EmptyRef)) = &TypeOfClaims
	|		THEN VALUE(Enum.KindsOfDebt.Other)
	|		ELSE TT_RegisterEntries.DebtKind
	|	END,
	|	TT_RegisterEntries.DateOfDebtOccurrence,
	|	TT_RegisterEntries.Currency
	|;
	|////////////////////////////////////////////////////////////////////////////////
	|DROP TT_RegisterEntries";
	
	QueryTexts.Add(QueryText);
	
	#EndRegion
	
	#EndRegion
	
	#Region ManualAdjustments
	
	QueryText =
	"SELECT
	|	Tt_DocumentData.Counterparty AS Counterparty,
	|	Tt_DocumentData.Contract AS Contract,
	|	Tt_DocumentData.ARAPDocument AS ARAPDocument,
	|	Tt_DocumentData.ARAPObject AS ARAPObject,
	|	MAX(Tt_DocumentData.ManualAdjustment) AS ManualAdjustment,
	|	MAX(Tt_DocumentData.DoNotAccrue) AS DoNotAccrue,
	|	MAX(Tt_DocumentData.DebtKind) AS DebtKind,
	|	MAX(Tt_DocumentData.AmountOfSecurityByDimension) AS AmountOfSecurityByDimension
	|INTO Tt_DocumentAnalytics
	|FROM
	|	Tt_DocumentData AS Tt_DocumentData
	|WHERE
	|	NOT Tt_DocumentData.DebtKind = VALUE(Enum.KindsOfDebt.Other)
	|
	|GROUP BY
	|	Tt_DocumentData.Counterparty,
	|	Tt_DocumentData.Contract,
	|	Tt_DocumentData.ARAPDocument,
	|	Tt_DocumentData.ARAPObject
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	TT_RegisterData.Partner AS Partner,
	|	TT_RegisterData.Counterparty AS Counterparty,
	|	TT_RegisterData.Contract AS Contract,
	|	TT_RegisterData.LineOfBusiness AS LineOfBusiness,
	|	TT_RegisterData.ARAPObject AS ARAPObject,
	|	TT_RegisterData.ARAPDocument AS ARAPDocument,
	|	TT_RegisterData.AmountType AS AmountType,
	|	TT_RegisterData.DateOfDebtOccurrence AS DateOfDebtOccurrence,
	|	TT_RegisterData.AmountOfDebtLocal AS AmountOfDebtLocal,
	|	TT_RegisterData.DebtAmount AS DebtAmount,
	|	TT_RegisterData.Currency AS Currency,
	|	TT_AnalyticsManualAdjustment_Registers.DebtKind AS DebtKind,
	|	TT_AnalyticsManualAdjustment_Registers.DoNotAccrue AS DoNotAccrue
	|INTO TT_RegisterDataManualAdjustment
	|FROM
	|	TT_RegisterData AS TT_RegisterData
	|		INNER JOIN Tt_DocumentAnalytics AS TT_AnalyticsManualAdjustment_Registers
	|		ON TT_RegisterData.Counterparty = TT_AnalyticsManualAdjustment_Registers.Counterparty
	|			AND TT_RegisterData.Contract = TT_AnalyticsManualAdjustment_Registers.Contract
	|			AND TT_RegisterData.ARAPObject = TT_AnalyticsManualAdjustment_Registers.ARAPObject
	|			AND TT_RegisterData.ARAPDocument = TT_AnalyticsManualAdjustment_Registers.ARAPDocument
	|			AND (TT_AnalyticsManualAdjustment_Registers.ManualAdjustment)
	|
	|INDEX BY
	|	Counterparty,
	|	Contract,
	|	ARAPObject,
	|	ARAPDocument,
	|	AmountType,
	|	DateOfDebtOccurrence
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	Tt_DocumentData.Partner AS Partner,
	|	Tt_DocumentData.Counterparty AS Counterparty,
	|	Tt_DocumentData.Contract AS Contract,
	|	Tt_DocumentData.LineOfBusiness AS LineOfBusiness,
	|	Tt_DocumentData.ARAPObject AS ARAPObject,
	|	Tt_DocumentData.ARAPDocument AS ARAPDocument,
	|	Tt_DocumentData.AmountType AS AmountType,
	|	Tt_DocumentData.DateOfDebtOccurrence AS DateOfDebtOccurrence,
	|	0 AS AmountOfDebtLocal,
	|	0 AS DebtAmount,
	|	Tt_DocumentData.Currency AS Currency,
	|	TT_AnalyticsManualAdjustment_Document.AmountOfSecurityByDimension AS AmountOfSecurityByDimension,
	|	Tt_DocumentData.Evaluation AS Evaluation,
	|	Tt_DocumentData.ACReserve AS ACReserve,
	|	Tt_DocumentData.Reserve AS Reserve,
	|	TT_AnalyticsManualAdjustment_Document.DebtKind AS DebtKind,
	|	TT_AnalyticsManualAdjustment_Document.DoNotAccrue AS DoNotAccrue
	|INTO TT_DocumentDataManualCorrection
	|FROM
	|	Tt_DocumentData AS Tt_DocumentData
	|		INNER JOIN Tt_DocumentAnalytics AS TT_AnalyticsManualAdjustment_Document
	|		ON Tt_DocumentData.Counterparty = TT_AnalyticsManualAdjustment_Document.Counterparty
	|			AND Tt_DocumentData.Contract = TT_AnalyticsManualAdjustment_Document.Contract
	|			AND Tt_DocumentData.ARAPDocument = TT_AnalyticsManualAdjustment_Document.ARAPDocument
	|			AND Tt_DocumentData.ARAPObject = TT_AnalyticsManualAdjustment_Document.ARAPObject
	|			AND (TT_AnalyticsManualAdjustment_Document.ManualAdjustment)
	|
	|INDEX BY
	|	Counterparty,
	|	Contract,
	|	ARAPObject,
	|	ARAPDocument,
	|	AmountType,
	|	DateOfDebtOccurrence
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	ISNULL(TT_RegisterData.Partner, Tt_DocumentData.Partner) AS Partner,
	|	ISNULL(TT_RegisterData.Counterparty, Tt_DocumentData.Counterparty) AS Counterparty,
	|	ISNULL(TT_RegisterData.Contract, Tt_DocumentData.Contract) AS Contract,
	|	ISNULL(TT_RegisterData.LineOfBusiness, Tt_DocumentData.LineOfBusiness) AS LineOfBusiness,
	|	ISNULL(TT_RegisterData.ARAPObject, Tt_DocumentData.ARAPObject) AS ARAPObject,
	|	ISNULL(TT_RegisterData.ARAPDocument, Tt_DocumentData.ARAPDocument) AS ARAPDocument,
	|	ISNULL(TT_RegisterData.AmountType, Tt_DocumentData.AmountType) AS AmountType,
	|	ISNULL(TT_RegisterData.DateOfDebtOccurrence, Tt_DocumentData.DateOfDebtOccurrence) AS DateOfDebtOccurrence,
	|	ISNULL(TT_RegisterData.AmountOfDebtLocal, 0) AS AmountOfDebtLocal,
	|	ISNULL(TT_RegisterData.DebtAmount, 0) AS DebtAmount,
	|	ISNULL(TT_RegisterData.Currency, Tt_DocumentData.Currency) AS Currency,
	|	ISNULL(Tt_DocumentData.AmountOfSecurityByDimension, 0) AS AmountOfSecurityByDimension,
	|	ISNULL(Tt_DocumentData.Evaluation, 0) AS Evaluation,
	|	ISNULL(Tt_DocumentData.ACReserve, 0) AS ACReserve,
	|	ISNULL(Tt_DocumentData.Reserve, 0) AS Reserve,
	|	ISNULL(TT_RegisterData.DebtKind, Tt_DocumentData.DebtKind) AS DebtKind,
	|	ISNULL(TT_RegisterData.DoNotAccrue, Tt_DocumentData.DoNotAccrue) AS DoNotAccrue,
	|	TRUE AS ManualAdjustment,
	|	CASE
	|		WHEN ISNULL(TT_RegisterData.AmountOfDebtLocal, 0) = ISNULL(Tt_DocumentData.AmountOfDebtLocal, 0)
	|			THEN FALSE
	|		ELSE TRUE
	|	END AS CheckRequired
	|INTO TT_DataManualAdjustment
	|FROM
	|	TT_RegisterDataManualAdjustment AS TT_RegisterData
	|		FULL JOIN TT_DocumentDataManualCorrection AS Tt_DocumentData
	|		ON TT_RegisterData.Counterparty = Tt_DocumentData.Counterparty
	|			AND TT_RegisterData.Contract = Tt_DocumentData.Contract
	|			AND TT_RegisterData.ARAPObject = Tt_DocumentData.ARAPObject
	|			AND TT_RegisterData.ARAPDocument = Tt_DocumentData.ARAPDocument
	|			AND TT_RegisterData.AmountType = Tt_DocumentData.AmountType
	|			AND TT_RegisterData.DateOfDebtOccurrence = Tt_DocumentData.DateOfDebtOccurrence
	|;
	|////////////////////////////////////////////////////////////////////////////////
	|DROP TT_RegisterDataManualAdjustment
	|;
	|////////////////////////////////////////////////////////////////////////////////
	|DROP TT_DocumentDataManualCorrection";
	
	QueryTexts.Add(QueryText);
	
	#EndRegion
	
	#Region AccountsReceivableData
	
	QueryText =
	"	SELECT
	|	NestedQuery.Partner AS Partner,
	|	NestedQuery.Counterparty AS Counterparty,
	|	NestedQuery.Contract AS Contract,
	|	NestedQuery.LineOfBusiness AS LineOfBusiness,
	|	NestedQuery.ARAPObject AS ARAPObject,
	|	NestedQuery.ARAPDocument AS ARAPDocument,
	|	NestedQuery.AmountType AS AmountType,
	|	NestedQuery.DateOfDebtOccurrence AS DateOfDebtOccurrence,
	|	NestedQuery.AmountOfDebtLocal AS AmountOfDebtLocal,
	|	NestedQuery.DebtAmount AS DebtAmount,
	|	NestedQuery.Currency AS Currency,
	|	NestedQuery.AmountOfSecurityByDimension AS AmountOfSecurityByDimension,
	|	NestedQuery.Evaluation AS Evaluation,
	|	NestedQuery.ACReserve AS ACReserve,
	|	NestedQuery.Reserve AS Reserve,
	|	NestedQuery.DebtKind AS DebtKind,
	|	NestedQuery.DoNotAccrue AS DoNotAccrue,
	|	NestedQuery.ManualAdjustment AS ManualAdjustment,
	|	NestedQuery.CheckRequired AS CheckRequired
	|FROM
	|	(SELECT
	|		TT_DataManualAdjustment.Partner AS Partner,
	|		TT_DataManualAdjustment.Counterparty AS Counterparty,
	|		TT_DataManualAdjustment.Contract AS Contract,
	|		TT_DataManualAdjustment.LineOfBusiness AS LineOfBusiness,
	|		TT_DataManualAdjustment.ARAPObject AS ARAPObject,
	|		TT_DataManualAdjustment.ARAPDocument AS ARAPDocument,
	|		TT_DataManualAdjustment.AmountType AS AmountType,
	|		TT_DataManualAdjustment.DateOfDebtOccurrence AS DateOfDebtOccurrence,
	|		TT_DataManualAdjustment.AmountOfDebtLocal AS AmountOfDebtLocal,
	|		TT_DataManualAdjustment.DebtAmount AS DebtAmount,
	|		TT_DataManualAdjustment.Currency AS Currency,
	|		TT_DataManualAdjustment.AmountOfSecurityByDimension AS AmountOfSecurityByDimension,
	|		TT_DataManualAdjustment.Evaluation AS Evaluation,
	|		TT_DataManualAdjustment.ACReserve AS ACReserve,
	|		TT_DataManualAdjustment.Reserve AS Reserve,
	|		TT_DataManualAdjustment.DebtKind AS DebtKind,
	|		TT_DataManualAdjustment.DoNotAccrue AS DoNotAccrue,
	|		TT_DataManualAdjustment.ManualAdjustment AS ManualAdjustment,
	|		TT_DataManualAdjustment.CheckRequired AS CheckRequired
	|	FROM
	|		TT_DataManualAdjustment AS TT_DataManualAdjustment
	|	
	|	UNION ALL
	|	
	|	SELECT
	|		Tt_DocumentData.Partner,
	|		Tt_DocumentData.Counterparty,
	|		Tt_DocumentData.Contract,
	|		Tt_DocumentData.LineOfBusiness,
	|		Tt_DocumentData.ARAPObject,
	|		Tt_DocumentData.ARAPDocument,
	|		Tt_DocumentData.AmountType,
	|		Tt_DocumentData.DateOfDebtOccurrence,
	|		Tt_DocumentData.AmountOfDebtLocal,
	|		Tt_DocumentData.DebtAmount,
	|		Tt_DocumentData.Currency,
	|		Tt_DocumentData.AmountOfSecurityByDimension,
	|		Tt_DocumentData.Evaluation,
	|		Tt_DocumentData.ACReserve,
	|		Tt_DocumentData.Reserve,
	|		Tt_DocumentData.DebtKind,
	|		Tt_DocumentData.DoNotAccrue,
	|		Tt_DocumentData.ManualAdjustment,
	|		FALSE
	|	FROM
	|		Tt_DocumentData AS Tt_DocumentData
	|	WHERE
	|		Tt_DocumentData.DebtKind = VALUE(Enum.KindsOfDebt.Other)
	|	
	|	UNION ALL
	|	
	|	SELECT
	|		TT_RegisterData.Partner,
	|		TT_RegisterData.Counterparty,
	|		TT_RegisterData.Contract,
	|		TT_RegisterData.LineOfBusiness,
	|		TT_RegisterData.ARAPObject,
	|		TT_RegisterData.ARAPDocument,
	|		TT_RegisterData.AmountType,
	|		TT_RegisterData.DateOfDebtOccurrence,
	|		TT_RegisterData.AmountOfDebtLocal,
	|		TT_RegisterData.DebtAmount,
	|		TT_RegisterData.Currency,
	|		ISNULL(Tt_DocumentAnalytics.AmountOfSecurityByDimension, 0),
	|		0,
	|		0,
	|		0,
	|		TT_RegisterData.DebtKind,
	|		ISNULL(Tt_DocumentAnalytics.DoNotAccrue, TT_RegisterData.DoNotAccrue),
	|		FALSE,
	|		FALSE
	|	FROM
	|		TT_RegisterData AS TT_RegisterData
	|			LEFT JOIN Tt_DocumentAnalytics AS Tt_DocumentAnalytics
	|			ON TT_RegisterData.Counterparty = Tt_DocumentAnalytics.Counterparty
	|				AND TT_RegisterData.Contract = Tt_DocumentAnalytics.Contract
	|				AND TT_RegisterData.ARAPDocument = Tt_DocumentAnalytics.ARAPDocument
	|	WHERE
	|		NOT ISNULL(Tt_DocumentAnalytics.ManualAdjustment, FALSE)) AS NestedQuery
	|
	|GROUP BY
	|	NestedQuery.Partner,
	|	NestedQuery.Counterparty,
	|	NestedQuery.Contract,
	|	NestedQuery.LineOfBusiness,
	|	NestedQuery.ARAPObject,
	|	NestedQuery.ARAPDocument,
	|	NestedQuery.AmountType,
	|	NestedQuery.DateOfDebtOccurrence,
	|	NestedQuery.AmountOfDebtLocal,
	|	NestedQuery.DebtAmount,
	|	NestedQuery.Currency,
	|	NestedQuery.AmountOfSecurityByDimension,
	|	NestedQuery.Evaluation,
	|	NestedQuery.ACReserve,
	|	NestedQuery.Reserve,
	|	NestedQuery.DebtKind,
	|	NestedQuery.DoNotAccrue,
	|	NestedQuery.ManualAdjustment,
	|	NestedQuery.CheckRequired
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|DROP Tt_DocumentAnalytics";
	
	QueryTexts.Add(QueryText);
	
	#EndRegion
	
	QueryText = StrConcat(QueryTexts, Common.QueryBatchSeparator());
	
	Return QueryText;
	
EndFunction

Function QueryTextAccountsPayable()
	
	Return
	"SELECT ALLOWED
	|	AccountingDimensionByPartners.DimensionKey AS DimensionKey
	|INTO SelectionByOrganizationContractors
	|FROM
	|	InformationRegister.AccountingDimensionByPartners AS AccountingDimensionByPartners
	|WHERE
	|	AccountingDimensionByPartners.Organization = &Organization
	|	AND AccountingDimensionByPartners.Counterparty IN (&ArrayOfCounterparties)
	|	AND (&ProcessEverything
	|		OR AccountingDimensionByPartners.Counterparty = &Counterparty
	|		AND AccountingDimensionByPartners.Contract = &Contract
	|	)
	|INDEX BY
	|	DimensionKey
	|;
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT ALLOWED
	|	VendorsARAPAccountingByDueDatesBalance.AccountingDimensionByPartners.Partner AS Partner,
	|	VendorsARAPAccountingByDueDatesBalance.AccountingDimensionByPartners.Counterparty AS Counterparty,
	|	VendorsARAPAccountingByDueDatesBalance.AccountingDimensionByPartners.Contract AS Contract,
	|	VendorsARAPAccountingByDueDatesBalance.ARAPDocument AS ARAPDocument,
	|	VendorsARAPAccountingByDueDatesBalance.DebtLocalBalance AS Sum
	|INTO TT_IndebtednessToSuppliers
	|FROM
	|	AccumulationRegister.VendorsARAPAccountingByDueDates.Balance(&EndOfMonthBoundary, AccountingDimensionByPartners IN
	|		(SELECT
	|			T.DimensionKey
	|		FROM
	|			SelectionByOrganizationContractors AS T)
	|		AND (&ProcessEverything OR ARAPDocument = &ARAPDocument)) AS VendorsARAPAccountingByDueDatesBalance
	|WHERE
	|	&NewOnlineARAPAccounting
	|
	|UNION ALL
	|
	|SELECT
	|	VendorsARAPAccountingByDocumentsBalance.AccountingDimensionByPartners.Partner AS Partner,
	|	VendorsARAPAccountingByDocumentsBalance.AccountingDimensionByPartners.Counterparty AS Counterparty,
	|	VendorsARAPAccountingByDocumentsBalance.AccountingDimensionByPartners.Contract AS Contract,
	|	VendorsARAPAccountingByDocumentsBalance.ARAPDocument AS ARAPDocument,
	|	-VendorsARAPAccountingByDocumentsBalance.DebtLocalBalance AS Sum
	|FROM
	|	AccumulationRegister.VendorsARAPAccountingByDocuments.Balance(&EndOfMonthBoundary, AccountingDimensionByPartners IN
	|		(SELECT
	|			T.DimensionKey
	|		FROM
	|			SelectionByOrganizationContractors AS T)
	|		AND (&ProcessEverything OR ARAPDocument = &ARAPDocument)) AS VendorsARAPAccountingByDocumentsBalance
	|WHERE
	|	NOT &NewOnlineARAPAccounting
	|;
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT ALLOWED
	|	CustomersARAPAccountingByDueDatesBalance.AccountingDimensionByPartners.Partner AS Partner,
	|	CustomersARAPAccountingByDueDatesBalance.AccountingDimensionByPartners.Counterparty AS Counterparty,
	|	CustomersARAPAccountingByDueDatesBalance.AccountingDimensionByPartners.Contract AS Contract,
	|	CustomersARAPAccountingByDueDatesBalance.ARAPDocument AS ARAPDocument,
	|	CustomersARAPAccountingByDueDatesBalance.PrepaymentLocalBalance AS Sum
	|INTO TT_AdvancesReceivedFromCustomers
	|FROM
	|	AccumulationRegister.CustomersARAPAccountingByDueDates.Balance(&EndOfMonthBoundary, AccountingDimensionByPartners IN
	|		(SELECT
	|			T.DimensionKey
	|		FROM
	|			SelectionByOrganizationContractors AS T)
	|		AND (&ProcessEverything OR ARAPDocument = &ARAPDocument)) AS CustomersARAPAccountingByDueDatesBalance
	|WHERE
	|	&NewOnlineARAPAccounting
	|
	|UNION ALL
	|
	|SELECT
	|	CustomersARAPAccountingByDocumentsBalance.AccountingDimensionByPartners.Partner AS Partner,
	|	CustomersARAPAccountingByDocumentsBalance.AccountingDimensionByPartners.Counterparty AS Counterparty,
	|	CustomersARAPAccountingByDocumentsBalance.AccountingDimensionByPartners.Contract AS Contract,
	|	CustomersARAPAccountingByDocumentsBalance.ARAPDocument AS ARAPDocument,
	|	-CustomersARAPAccountingByDocumentsBalance.PrepaymentLocalBalance AS Sum
	|FROM
	|	AccumulationRegister.CustomersARAPAccountingByDocuments.Balance(&EndOfMonthBoundary, AccountingDimensionByPartners IN
	|		(SELECT
	|			T.DimensionKey
	|		FROM
	|			SelectionByOrganizationContractors AS T)
	|		AND (&ProcessEverything OR ARAPDocument = &ARAPDocument)) AS CustomersARAPAccountingByDocumentsBalance
	|WHERE
	|	NOT &NewOnlineARAPAccounting
	|;
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT ALLOWED
	|	FinancialInstrumentsARAPBalance.AccountingDimensionByPartners.Partner AS Partner,
	|	FinancialInstrumentsARAPBalance.AccountingDimensionByPartners.Counterparty AS Counterparty,
	|	FinancialInstrumentsARAPBalance.Contract AS Contract,
	|	-FinancialInstrumentsARAPBalance.SumComplBalance AS Sum
	|INTO Tt_LoansAndDepositsIssued
	|FROM
	|	AccumulationRegister.FinancialInstrumentsARAP.Balance(&EndOfMonthBoundary, AccountingDimensionByPartners IN
	|		(SELECT
	|			T.DimensionKey
	|		FROM
	|			SelectionByOrganizationContractors AS T)) AS FinancialInstrumentsARAPBalance
	|WHERE
	|	FinancialInstrumentsARAPBalance.SumComplBalance < 0
	|;
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	TT_IndebtednessToSuppliers.Partner AS Partner,
	|	TT_IndebtednessToSuppliers.Counterparty AS Counterparty,
	|	TT_IndebtednessToSuppliers.Contract AS Contract,
	|	TT_IndebtednessToSuppliers.ARAPDocument AS ARAPDocument,
	|	TT_IndebtednessToSuppliers.Sum AS Sum
	|INTO TT_Data
	|FROM
	|	TT_IndebtednessToSuppliers AS TT_IndebtednessToSuppliers
	|
	|UNION ALL
	|
	|SELECT
	|	TT_AdvancesReceivedFromCustomers.Partner,
	|	TT_AdvancesReceivedFromCustomers.Counterparty,
	|	TT_AdvancesReceivedFromCustomers.Contract,
	|	TT_AdvancesReceivedFromCustomers.ARAPDocument,
	|	TT_AdvancesReceivedFromCustomers.Sum
	|FROM
	|	TT_AdvancesReceivedFromCustomers AS TT_AdvancesReceivedFromCustomers
	|
	|UNION ALL
	|
	|SELECT
	|	Tt_LoansAndDepositsIssued.Partner,
	|	Tt_LoansAndDepositsIssued.Counterparty,
	|	Tt_LoansAndDepositsIssued.Contract,
	|	UNDEFINED,
	|	Tt_LoansAndDepositsIssued.Sum
	|FROM
	|	Tt_LoansAndDepositsIssued AS Tt_LoansAndDepositsIssued
	|;
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	TT_Data.Partner AS Partner,
	|	TT_Data.Counterparty AS Counterparty,
	|	TT_Data.Contract AS Contract,
	|	TT_Data.ARAPDocument AS ARAPDocument,
	|	SUM(TT_Data.Sum) AS Sum
	|FROM
	|	TT_Data AS TT_Data
	|GROUP BY
	|	TT_Data.Partner,
	|	TT_Data.Counterparty,
	|	TT_Data.Contract,
	|	TT_Data.ARAPDocument";
	
EndFunction

#EndRegion

#Region Evaluation

Function GetEvaluationInterval(Lower, Upper_, Evaluation)

	Return New Structure("Lower,Upper_,Evaluation", Lower, Upper_, Evaluation);

EndFunction

#EndRegion

#EndRegion

#EndIf
