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
	DocumentMechanisms.Add("FutureExpenseCommitments");
	DocumentMechanisms.Add("AccountingOfIncomeExpenses");
	DocumentMechanisms.Add("AccountingForOtherAssetsLiabilities");
	DocumentMechanisms.Add("FixedAssets");
	DocumentMechanisms.Add("DocumentsRegistry");
	
	FutureExpenseCommitmentsAccrualWriteOffLocalization.RegisterAccountingMechanisms(DocumentMechanisms);
	
EndProcedure

#EndRegion

// StandardSubsystems.ObjectsVersioning

// Defines object settings for the object Versioning subsystem.
//
// Parameters:
//  Settings - Structure - subsystem settings.
//
Procedure OnDefineObjectVersioningSettings(Settings) Export

EndProcedure

// End StandardSubsystems.ObjectsVersioning

// Defines a list of report commands.
//
// Parameters:
//   ReportsCommands - See ReportsOptionsOverridable.BeforeAddReportCommands.ReportsCommands
//   Parameters - See ReportsOptionsOverridable.BeforeAddReportCommands.Parameters
//
Procedure AddReportCommands(ReportsCommands, Parameters) Export
	
	ReportCommand = Reports.DetailedCalculationOfDiscountingOfProvisionsAndContingentLiabilities.AddReportCommand(ReportsCommands);
	If ReportCommand <> Undefined Then
		ReportCommand.VisibilityInForms = "DocumentForm,ListForm";
	EndIf;	
	
	FutureExpenseCommitmentsAccrualWriteOffLocalization.AddReportCommands(ReportsCommands, Parameters);

EndProcedure

// Returns data on the objects of accounting for reserves of upcoming expenses: the direction of activity, the balance on the register,
//	data on accrual and write-off. Data is filled in based on one of the following conditions:
//		- the date passed in the fill parameters is included in the period of validity of the reserve accounting object;
//		- there are balances on the register as of the date passed in the parameters.
//	Parameters:
//		FillParameters - Structure - a structure containing the following keys:
//			Date - date and time - the date on which it is necessary to obtain data from the register of "Reservesreferences";
//			Link - Documentlink - a link to a document whose Balances do not need to be taken into account when receiving data from the register;
//			Organization - Directory link.Organizations - The organization for which you need to get data;
//			Type of reserves - Directory Link.Reserves - The reserve for which you need to get data;
//		ProvisionObjects - CatalogRef.AccountingObjectsOfFutureExpenseCommitments - if set, data is returned only for this accounting object;
//
// Returns:
//		QueryResult - Data of the query result.
//
Function DataForFillingReserves(FillParameters, ProvisionObjects = Undefined) Export
	
	Query = New Query;
	Query.Text = 
	"SELECT
	|	FutureExpenseCommitmentsBalance.Organization AS Organization,
	|	FutureExpenseCommitmentsBalance.ReserveKind AS ReserveKind,
	|	FutureExpenseCommitmentsBalance.ProvisionObject AS ProvisionObject,
	|	-FutureExpenseCommitmentsBalance.SumComplBalance AS SumComplBalance,
	|	-FutureExpenseCommitmentsBalance.AmountFABalance AS AmountFABalance,
	|	-FutureExpenseCommitmentsBalance.SumManBalance AS SumManBalance
	|INTO BalancesOfProvisionsForUpcomingExpenses
	|FROM
	|	AccumulationRegister.FutureExpenseCommitments.Balance(
	|			&Boundary,
	|			Organization = &Organization
	|				AND ReserveKind = &ReserveKind
	|				AND (NOT &SelectionByReserveAccountingObject OR ProvisionObject IN (&ProvisionObjects))) AS FutureExpenseCommitmentsBalance
	|
	|INDEX BY
	|	Organization,
	|	ReserveKind,
	|	ProvisionObject
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	PeriodOfDiscountingOfProvisionsAndContingentLiabilities.ProvisionObject AS ProvisionObject,
	|	PeriodOfDiscountingOfProvisionsAndContingentLiabilities.CompletionDate AS CompletionDate
	|INTO TermsOfDiscountingReserves
	|FROM
	|	Catalog.AccountingObjectsOfFutureExpenseCommitments AS AccountingObjectsOfFutureExpenseCommitments
	|		INNER JOIN InformationRegister.PeriodOfDiscountingOfProvisionsAndContingentLiabilities.SliceLast(
	|			&CurDate,
	|			NOT &SelectionByReserveAccountingObject OR ProvisionObject IN (&ProvisionObjects)) AS PeriodOfDiscountingOfProvisionsAndContingentLiabilities
	|		ON (AccountingObjectsOfFutureExpenseCommitments.Ref = PeriodOfDiscountingOfProvisionsAndContingentLiabilities.ProvisionObject)
	|WHERE
	|	AccountingObjectsOfFutureExpenseCommitments.ReserveKind = &ReserveKind
	|
	|INDEX BY
	|	ProvisionObject
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	AccountingObjectsOfFutureExpenseCommitments.Ref AS ProvisionObject,
	|	AccountingObjectsOfFutureExpenseCommitments.LineOfBusiness AS LineOfBusiness,
	|	AccountingObjectsOfFutureExpenseCommitments.BusinessUnitAccruals AS BusinessUnitAccruals,
	|	AccountingObjectsOfFutureExpenseCommitments.LineOfBusinessAccruals AS LineOfBusinessAccruals,
	|	AccountingObjectsOfFutureExpenseCommitments.ExpenseItemAccruals AS ExpenseItemAccruals,
	|	AccountingObjectsOfFutureExpenseCommitments.ExpensesDimensionAccruals AS ExpensesDimensionAccruals,
	|	AccountingObjectsOfFutureExpenseCommitments.BusinessUnitWriteOffs AS BusinessUnitWriteOffs,
	|	AccountingObjectsOfFutureExpenseCommitments.LineOfBusinessExpenses AS LineOfBusinessExpenses,
	|	AccountingObjectsOfFutureExpenseCommitments.IncomeItemOfWriteOff AS IncomeItemOfWriteOff,
	|	AccountingObjectsOfFutureExpenseCommitments.IncomeDimensionOfWriteOff AS IncomeDimensionOfWriteOff,
	|	AccountingObjectsOfFutureExpenseCommitments.YouCanGenerateAccountingAndTaxAccountingProvisionsSeparately AS YouCanGenerateAccountingAndTaxAccountingProvisionsSeparately,
	|	ISNULL(FutureExpenseCommitmentsBalance.SumComplBalance, 0) AS CurrentAmountLocal,
	|	ISNULL(FutureExpenseCommitmentsBalance.AmountFABalance, 0) AS CurrentTAAmount,
	|	ISNULL(FutureExpenseCommitmentsBalance.SumManBalance, 0) AS CurrentAmountMan,
	|	ISNULL(TermsOfDiscountingReserves.CompletionDate, AccountingObjectsOfFutureExpenseCommitments.EndOfPeriod) AS CompletionDate
	|FROM
	|	Catalog.AccountingObjectsOfFutureExpenseCommitments AS AccountingObjectsOfFutureExpenseCommitments
	|		LEFT JOIN BalancesOfProvisionsForUpcomingExpenses AS FutureExpenseCommitmentsBalance
	|		ON (FutureExpenseCommitmentsBalance.ProvisionObject = AccountingObjectsOfFutureExpenseCommitments.Ref)
	|			AND (FutureExpenseCommitmentsBalance.Organization = AccountingObjectsOfFutureExpenseCommitments.Organization)
	|			AND (FutureExpenseCommitmentsBalance.ReserveKind = AccountingObjectsOfFutureExpenseCommitments.ReserveKind)
	|		LEFT JOIN TermsOfDiscountingReserves AS TermsOfDiscountingReserves
	|		ON (TermsOfDiscountingReserves.ProvisionObject = AccountingObjectsOfFutureExpenseCommitments.Ref)
	|WHERE
	|	AccountingObjectsOfFutureExpenseCommitments.Organization = &Organization
	|	AND AccountingObjectsOfFutureExpenseCommitments.ReserveKind = &ReserveKind
	|	AND CASE
	|			WHEN &SelectionByReserveAccountingObject
	|				THEN AccountingObjectsOfFutureExpenseCommitments.Ref IN (&ProvisionObjects)
	|			ELSE ISNULL(FutureExpenseCommitmentsBalance.SumComplBalance, 0) > 0
	|					OR ISNULL(FutureExpenseCommitmentsBalance.AmountFABalance, 0) > 0
	|					OR ISNULL(FutureExpenseCommitmentsBalance.SumManBalance, 0) > 0
	|					OR AccountingObjectsOfFutureExpenseCommitments.BeginOfPeriod <= &CurDate
	|						AND AccountingObjectsOfFutureExpenseCommitments.DeletionMark = FALSE
	|						AND (AccountingObjectsOfFutureExpenseCommitments.EndOfPeriod >= &CurDate
	|							OR AccountingObjectsOfFutureExpenseCommitments.EndOfPeriod = DATETIME(1, 1, 1))
	|		END;
	|
	|DROP BalancesOfProvisionsForUpcomingExpenses";
	
	DiscountingOfEstimatedObligation = False;
	If ValueIsFilled(FillParameters.ReserveKind) Then
		DiscountingOfEstimatedObligation = Common.ObjectAttributeValue(
			FillParameters.ReserveKind, "ProvisionDiscounting");
	EndIf;
	
	If DiscountingOfEstimatedObligation Then
		DateOfRemainingGoods = BegOfMonth(FillParameters.Date);
	Else
		DateOfRemainingGoods = New Boundary(New PointInTime(FillParameters.Date, FillParameters.Ref), BoundaryType.Excluding);
	EndIf;
	
	Query.SetParameter("Boundary", DateOfRemainingGoods);
	Query.SetParameter("CurDate", FillParameters.Date);
	Query.SetParameter("Organization", FillParameters.Organization);
	Query.SetParameter("ReserveKind", FillParameters.ReserveKind);
	Query.SetParameter("ProvisionObjects", ProvisionObjects);
	Query.SetParameter("SelectionByReserveAccountingObject", ProvisionObjects <> Undefined And ProvisionObjects.Count() > 0);
	
	Result = Query.Execute();
	
	Return Result;
	
EndFunction

#Region InterfaceImplementation

// StandardSubsystems.AccessManagement

// Parameters:
//   Restriction - See AccessManagementOverridable.OnFillAccessRestriction.Restriction.
//
Procedure OnFillAccessRestriction(Restriction) Export

	Restriction.Text =
	"AllowReadUpdate
	|WHERE
	|	ValueAllowed(Organization)";

EndProcedure

// End StandardSubsystems.AccessManagement

#EndRegion

// Returns parameters for selecting articles in the document.
// 
// Parameters:
// 	BusinessOperation - EnumRef.BusinessTransactions -See IncomeAndExpensesServer.ArticleSelectionAndAnalyticsOptions
//
// Returns:
//  Array of See IncomeAndExpensesServer.ArticleSelectionAndAnalyticsOptions -
//
Function ItemsAndDimensionsSelectionParameters(BusinessOperation) Export
	
	ChoiceParametersArray = New Array;
	
	#Region ReservesExpenseItemAccruals
	ChoiceParameters = IncomeAndExpensesServer.ArticleSelectionAndAnalyticsOptions();
	ChoiceParameters.DataPath = "Object.Reserves";
	ChoiceParameters.AssetRef      = "ExpenseItemAccruals";
	
	ChoiceParameters.ChoosingExpenseItem = True;
	ChoiceParameters.DimensionOfExpenses = "ExpensesDimensionAccruals";
	
	ChoiceParameters.FormItems.AssetRef.Add("ReservesExpenseItemAccruals");
	ChoiceParameters.FormItems.DimensionOfExpenses.Add("ReservesExpensesDimensionAccruals");
	
	ChoiceParametersArray.Add(ChoiceParameters);
	#EndRegion
	
	#Region OtherIncomeIncomeItem
	ChoiceParameters = IncomeAndExpensesServer.ArticleSelectionAndAnalyticsOptions();
	ChoiceParameters.DataPath =    "Object.Reserves";
	ChoiceParameters.AssetRef = "IncomeItemOfWriteOff";
	
	ChoiceParameters.ChoosingIncomeItem = True;
	ChoiceParameters.DimensionOfRevenue = "IncomeDimensionOfWriteOff";
	
	ChoiceParameters.FormItems.AssetRef.Add("ReservesIncomeItemOfWriteOff");	
	ChoiceParameters.FormItems.DimensionOfRevenue.Add("ReservesIncomeDimensionOfWriteOff");
	
	ChoiceParametersArray.Add(ChoiceParameters);
	#EndRegion
	
	Return ChoiceParametersArray;
	
EndFunction

#EndRegion

#Region Private

#Region Posting

Procedure GetDocumentData(Query)
	
	ListOfRequests = New Array;
	
	#Region DocumentDataDetails
	QueryText =
	"SELECT
	|	DocumentData.Ref AS Ref,
	|	DocumentData.Date AS Period,
	|	DocumentData.Number AS Number,
	|	DocumentData.Organization AS Organization
	|
	|INTO DocumentDataDetails
	|
	|FROM
	|	Document.FutureExpenseCommitmentsAccrualWriteOff AS DocumentData
	|
	|WHERE
	|	DocumentData.Ref = &Ref
	|
	|INDEX BY
	|	Ref
	|";
	ListOfRequests.Add(QueryText);
	#EndRegion
	
	Query.Text = StrConcat(ListOfRequests, Common.QueryBatchSeparator());
	Query.Execute();
	
EndProcedure

// Initializes tables of values containing data of the tabular parts of the document.
// The value tables are stored in the properties of the "Additional Properties" structure.
//
// Returns:
//  Map of String
//
Function AdditionalDataSourcesForRegisteredRecords(RegisterName) Export

	DataSources = New Map;

	Return DataSources; 

EndFunction

// Returns tables for movements that are necessary for conducting a document through registers of accounting mechanisms.
//
// Parameters:
//  Document - DocumentRef, DocumentObject - link to the document or object for which you want to get data
//  Registers - Structure - a list of register names for which you want to table
//  AddlParameters - Structure - additional parameters for getting data that define the context of the event.
//
// Returns:
//  See DocumentsPosting.InitializeDocumentDataForPosting
//
Function DocumentDataForPosting(Document, Registers, AddlParameters = Undefined) Export
	
	If AddlParameters = Undefined Then
		AddlParameters = DocumentsPosting.AdditionalParametersDocumentDataForPosting();
	EndIf;
	
	If TypeOf(Document) = Type("DocumentObject.FutureExpenseCommitmentsAccrualWriteOff") Then
		DocumentRef = Document.Ref;
	Else
		DocumentRef = Document;
	EndIf;
	
	Query			= New Query;
	QueryTexts	= New ValueList;
	
	If Not AddlParameters.GetQueryTexts Then
		////////////////////////////////////////////////////////////////////////////
		// Create a motion initialization request
		
		FillInInitializationParameters(Query, DocumentRef, AddlParameters);
		
		////////////////////////////////////////////////////////////////////////////
		// Let's form the request text
		
		QueryTextOtherExpenses(Query, QueryTexts, Registers);
		QueryTextOtherIncome(Query, QueryTexts, Registers);
		QueryTextFACost(Query, QueryTexts, Registers);
		QueryTextFutureExpenseCommitments(Query, QueryTexts, Registers);
		QueryTextProvisionDiscountingRates(Query, QueryTexts, Registers);
		QueryTextPeriodOfDiscountingOfProvisionsAndContingentLiabilities(Query, QueryTexts, Registers);
		QueryTextTableDocumentsRegistry(Query, QueryTexts, Registers);
		QueryTextTableFixedAssetsDocuments(Query, QueryTexts, Registers);
		QueryTextTableDocumentPostingInFinancialAccounting(QueryTexts, Registers);
		FutureExpenseCommitmentsAccrualWriteOffLocalization.AddRequestTexts(Query,
																									QueryTexts,
																									Registers);
	EndIf;
	
	////////////////////////////////////////////////////////////////////////////
	// We will get tables for movements
	
	Return DocumentsPosting.InitializeDocumentDataForPosting(Query, QueryTexts, AddlParameters);
	
EndFunction

// Generates tables of movements during deferred execution.
//
// Parameters:
//  DocumentRef - DocumentRef - link to the document for which the Registered Records are generated
//  TempTablesManager - TempTablesManager - Contains auxiliary temporary tables that can be used for forming movements.
//
// Returns:
//  See DocumentsPosting.InitializeDocumentDataForPosting
//
Function TablesOfDeferredMotionFormation(DocumentRef, TempTablesManager) Export

	Query = New Query;
	Query.TempTablesManager = TempTablesManager;
	FillInInitializationParameters(Query, DocumentRef, Undefined);
	
	QueryTexts = New ValueList;
	
	QueryTextOtherExpenses(Query, QueryTexts, Undefined);
	QueryTextOtherIncome(Query, QueryTexts, Undefined);
	QueryTextFACost(Query, QueryTexts, Undefined);
	QueryTextTableDocumentPostingInFinancialAccounting(QueryTexts);
	FutureExpenseCommitmentsAccrualWriteOffLocalization.TablesOfDeferredMotionFormation(QueryTexts);
	
	TablesForRegisteredRecords = DocumentsPosting.InitializeDocumentDataForPosting(
							Query, QueryTexts, Undefined);
	
	Return TablesForRegisteredRecords;
	
EndFunction

Procedure FillInInitializationParameters(Query, DocumentRef, AddlParameters)

	DocumentsPosting.FillInInitializationParameters(Query, DocumentRef, AddlParameters);
	
	GetDocumentData(Query);
	
	Query.Text = 
	"SELECT
	|	DocumentData.Date AS Period,
	|	BEGINOFPERIOD(DocumentData.Date, MONTH) AS BeginOfPeriod,
	|	ENDOFPERIOD(DocumentData.Date, MONTH) AS PeriodEnding,
	|	DocumentData.Ref AS Ref,
	|	DocumentData.Organization AS Organization,
	|	DocumentData.ReserveKind AS ReserveKind,
	|	ISNULL(DocumentData.ReserveKind.ReserveType = VALUE(Enum.TypesOfProvisionsAndContingentLiabilities.ResidualLiabilities), FALSE) AS TheseAreReservesOfLiquidationObligations,
	|	ISNULL(DocumentData.ReserveKind.ProvisionDiscounting, FALSE) AS DiscountingOfEstimatedObligation,
	|	ISNULL(DocumentData.ReserveKind.DepreciationComponentBookValueCanBeNegative, FALSE) AS NegativeCostIsPossible,
	|	DocumentData.DiscountRate AS DiscountRate,
	|	DocumentData.Number AS Number,
	|	DocumentData.Comment AS Comment,
	|	DocumentData.Posted AS Posted,
	|	DocumentData.DeletionMark AS DeletionMark,
	|	DocumentData.EmployeeResponsible AS EmployeeResponsible
	|FROM
	|	Document.FutureExpenseCommitmentsAccrualWriteOff AS DocumentData
	|WHERE
	|	DocumentData.Ref = &Ref";
	
	Result = Query.Execute();
	Attributes = Result.Select();
	Attributes.Next();
	
	For Each Column In Result.Columns Do
		Query.SetParameter(Column.Name, Attributes[Column.Name]);
	EndDo;
	
	Query.SetParameter("EndOfMonthBorder",
		New Boundary(Query.Parameters.PeriodEnding, BoundaryType.Including));

	FutureExpenseCommitmentsAccrualWriteOffLocalization.SetCostBalancePeriodParameter(Query, Attributes);
	
	If Not FutureExpenseCommitments.AccountingForDiscountingReservesIsUsed(Query.Parameters.PeriodEnding, Query.Parameters.Organization) Then
		Query.SetParameter("DiscountingOfEstimatedObligation", False);
	EndIf;
	
	CostCalculationAppliedAlgorithms.FillInInitializationParameters(Query, Attributes);
	
	Query.SetParameter("MetadataIdentifier", Common.MetadataObjectID("Document.FutureExpenseCommitmentsAccrualWriteOff"));
	Query.SetParameter("NumberForPrinting", ObjectsPrefixesClientServer.NumberForPrinting(Attributes.Number));
	Query.SetParameter("HouseholdOperationForRegistry", Enums.BusinessTransactions.FutureExpenseCommitmentsAccrualWriteOff);
	
EndProcedure

Function QueryTextTableTTAccruals(Query, QueryTexts)
	
	RegisterName = "TTAccruals";
	
	QueryTextTableTTRegisteredRecordsOfDiscounting(Query, QueryTexts);
	
	QueryText = 
	"SELECT
	|	Rows.BusinessUnitAccruals AS Department,
	|	Rows.LineOfBusinessAccruals AS LineOfBusinessAccruals,
	|	Rows.LineOfBusiness AS LineOfBusiness,
	|	Rows.ProvisionObject AS ProvisionObject,
	|	Rows.ExpenseItemAccruals AS ExpenseItem,
	|	Rows.ExpensesDimensionAccruals AS DimensionOfExpenses,
	|	CASE
	|		WHEN Rows.SetNewAmountLocal
	|				AND Rows.CurrentAmountLocal < Rows.NewAmountLocal
	|			THEN Rows.NewAmountLocal - Rows.CurrentAmountLocal - ISNULL(Discounting.DiscountingAmountCompl, 0)
	|		ELSE 0
	|	END AS SumCompl,
	|	CASE
	|		WHEN &TheseAreReservesOfLiquidationObligations
	|			THEN 0
	|		WHEN NOT Rows.ProvisionObject.YouCanGenerateAccountingAndTaxAccountingProvisionsSeparately
	|				AND Rows.SetNewAmountLocal
	|				AND Rows.CurrentAmountLocal < Rows.NewAmountLocal
	|			THEN Rows.NewAmountLocal - Rows.CurrentAmountLocal
	|		WHEN Rows.SetNewTAAmount
	|				AND Rows.CurrentTAAmount < Rows.NewAmountTA
	|			THEN Rows.NewAmountTA - Rows.CurrentTAAmount
	|		ELSE 0
	|	END AS AmountFA,
	|	CASE
	|		WHEN NOT &CompanyManagementAccounting
	|			THEN 0
	|		WHEN Rows.SetNewAmountMan
	|				AND Rows.CurrentAmountMan < Rows.NewAmountMan
	|			THEN Rows.NewAmountMan - Rows.CurrentAmountMan - ISNULL(Discounting.DiscountingAmountMan, 0)
	|		ELSE 0
	|	END AS SumMan,
	|	Rows.CurrentAmountLocal AS CurrentAmountLocal,
	|	Rows.CurrentAmountMan AS CurrentAmountMan,
	|	FALSE AS ThisChangeIsOnlyDiscountPercentage,
	|	Rows.RowID AS RowID
	|INTO TTAccruals
	|FROM
	|	Document.FutureExpenseCommitmentsAccrualWriteOff.Reserves AS Rows
	|		LEFT JOIN TTRegisteredRecordsOfDiscounting AS Discounting
	|		ON Rows.ProvisionObject = Discounting.ProvisionObject
	|			AND Rows.RowID = Discounting.RowID
	|WHERE
	|	Rows.Ref = &Ref
	|	AND (Rows.SetNewAmountLocal
	|				AND Rows.CurrentAmountLocal < Rows.NewAmountLocal
	|			OR Rows.SetNewAmountMan
	|				AND Rows.CurrentAmountMan < Rows.NewAmountMan
	|			OR Rows.SetNewTAAmount
	|				AND Rows.CurrentTAAmount < Rows.NewAmountTA)
	|
	|UNION ALL
	|
	|SELECT
	|	Rows.BusinessUnitAccruals,
	|	Rows.LineOfBusinessAccruals,
	|	Rows.LineOfBusiness,
	|	Rows.ProvisionObject,
	|	Rows.ExpenseItemAccruals,
	|	Rows.ExpensesDimensionAccruals,
	|	CASE
	|		WHEN Discounting.TypeOfRegisteredRecordedLocal = VALUE(AccumulationRecordType.Expense)
	|			THEN Discounting.DiscountingAmountCompl
	|		ELSE 0
	|	END,
	|	0,
	|	CASE
	|		WHEN NOT &CompanyManagementAccounting
	|			THEN 0
	|		WHEN Discounting.TypeOfManSRegisteredRecords = VALUE(AccumulationRecordType.Expense)
	|			THEN Discounting.DiscountingAmountMan
	|		ELSE 0
	|	END,
	|	Rows.CurrentAmountLocal,
	|	Rows.CurrentAmountMan,
	|	TRUE,
	|	Rows.RowID
	|FROM
	|	Document.FutureExpenseCommitmentsAccrualWriteOff.Reserves AS Rows
	|		INNER JOIN TTRegisteredRecordsOfDiscounting AS Discounting
	|		ON Rows.ProvisionObject = Discounting.ProvisionObject
	|			AND Rows.RowID = Discounting.RowID
	|WHERE
	|	Rows.Ref = &Ref
	|	AND (NOT Rows.SetNewAmountLocal OR Rows.CurrentAmountLocal = Rows.NewAmountLocal)
	|	AND (NOT Rows.SetNewAmountMan OR Rows.CurrentAmountMan = Rows.NewAmountMan)
	|	AND (NOT Rows.SetNewTAAmount OR Rows.CurrentTAAmount = Rows.NewAmountTA)
	|	AND (Discounting.TypeOfRegisteredRecordedLocal = VALUE(AccumulationRecordType.Expense)
	|			OR Discounting.TypeOfManSRegisteredRecords = VALUE(AccumulationRecordType.Expense))
	|
	|INDEX BY
	|	DimensionOfExpenses,
	|	RowID";
	
	QueryTexts.Add(QueryText, RegisterName);
	Return QueryText;
	
EndFunction

Function QueryTextTableTTWriteOff(Query, QueryTexts)
	
	RegisterName = "TTWriteOff";
	
	QueryTextTableTTRegisteredRecordsOfDiscounting(Query, QueryTexts);
	
	QueryText = 
	"SELECT
	|	Rows.BusinessUnitWriteOffs AS Department,
	|	Rows.LineOfBusinessExpenses AS LineOfBusinessExpenses,
	|	Rows.LineOfBusiness AS LineOfBusiness,
	|	Rows.ProvisionObject AS ProvisionObject,
	|	Rows.IncomeItemOfWriteOff AS IncomeItem,
	|	Rows.ExpenseItemAccruals AS ExpenseItem,
	|	Rows.IncomeDimensionOfWriteOff AS DimensionOfRevenue,
	|	Rows.ExpensesDimensionAccruals AS DimensionOfExpenses,
	|	Rows.ExpensesDimensionAccruals AS FixedAsset,
	|
	|	CASE
	|		WHEN Rows.SetNewAmountLocal
	|				AND Rows.CurrentAmountLocal > Rows.NewAmountLocal
	|			THEN Rows.CurrentAmountLocal - Rows.NewAmountLocal - ISNULL(Discounting.DiscountingAmountCompl, 0)
	|		ELSE 0
	|	END AS SumCompl,
	|
	|	CASE
	|		WHEN NOT Rows.ProvisionObject.YouCanGenerateAccountingAndTaxAccountingProvisionsSeparately
	|				AND Rows.SetNewAmountLocal
	|				AND Rows.CurrentAmountLocal > Rows.NewAmountLocal
	|			THEN Rows.CurrentAmountLocal - Rows.NewAmountLocal
	|		WHEN Rows.SetNewTAAmount
	|				AND Rows.CurrentTAAmount > Rows.NewAmountTA
	|			THEN Rows.CurrentTAAmount - Rows.NewAmountTA
	|		ELSE 0
	|	END AS AmountFA,
	|
	|	CASE
	|		WHEN NOT &CompanyManagementAccounting
	|			THEN 0
	|		WHEN Rows.SetNewAmountMan
	|				AND Rows.CurrentAmountMan > Rows.NewAmountMan
	|			THEN Rows.CurrentAmountMan - Rows.NewAmountMan - ISNULL(Discounting.DiscountingAmountMan, 0)
	|		ELSE 0
	|	END AS SumMan,
	|
	|	Rows.CurrentAmountLocal AS CurrentAmountLocal,
	|	Rows.CurrentAmountMan AS CurrentAmountMan,
	|	FALSE AS ThisChangeIsOnlyDiscountPercentage,
	|	Rows.RowID AS RowID
	|
	|INTO TTWriteOff
	|
	|FROM
	|	Document.FutureExpenseCommitmentsAccrualWriteOff.Reserves AS Rows
	|
	|		LEFT JOIN TTRegisteredRecordsOfDiscounting AS Discounting
	|		ON Rows.ProvisionObject = Discounting.ProvisionObject
	|			AND Rows.RowID = Discounting.RowID
	|WHERE
	|	Rows.Ref = &Ref
	|	AND (Rows.SetNewAmountLocal
	|				AND Rows.CurrentAmountLocal > Rows.NewAmountLocal
	|			OR Rows.SetNewAmountMan
	|				AND Rows.CurrentAmountMan > Rows.NewAmountMan
	|			OR Rows.SetNewTAAmount
	|				AND Rows.CurrentTAAmount > Rows.NewAmountTA)
	|
	|UNION ALL
	|
	|SELECT
	|	Rows.BusinessUnitWriteOffs,
	|	Rows.LineOfBusinessExpenses,
	|	Rows.LineOfBusiness,
	|	Rows.ProvisionObject,
	|	Rows.IncomeItemOfWriteOff,
	|	Rows.ExpenseItemAccruals,
	|	Rows.IncomeDimensionOfWriteOff,
	|	Rows.ExpensesDimensionAccruals,
	|	Rows.ExpensesDimensionAccruals,
	|
	|	CASE
	|		WHEN Discounting.TypeOfRegisteredRecordedLocal = VALUE(AccumulationRecordType.Receipt)
	|			THEN Discounting.DiscountingAmountCompl
	|		ELSE 0
	|	END,
	|
	|	0,
	|
	|	CASE
	|		WHEN NOT &CompanyManagementAccounting
	|			THEN 0
	|		WHEN Discounting.TypeOfManSRegisteredRecords = VALUE(AccumulationRecordType.Receipt)
	|			THEN Discounting.DiscountingAmountMan
	|		ELSE 0
	|	END,
	|
	|	Rows.CurrentAmountLocal,
	|	Rows.CurrentAmountMan,
	|	TRUE,
	|	Rows.RowID
	|
	|FROM
	|	Document.FutureExpenseCommitmentsAccrualWriteOff.Reserves AS Rows
	|
	|		INNER JOIN TTRegisteredRecordsOfDiscounting AS Discounting
	|		ON Rows.ProvisionObject = Discounting.ProvisionObject
	|			AND Rows.RowID = Discounting.RowID
	|
	|WHERE
	|	Rows.Ref = &Ref
	|	AND (NOT Rows.SetNewAmountLocal OR Rows.CurrentAmountLocal = Rows.NewAmountLocal)
	|	AND (NOT Rows.SetNewAmountMan OR Rows.CurrentAmountMan = Rows.NewAmountMan)
	|	AND (NOT Rows.SetNewTAAmount OR Rows.CurrentTAAmount = Rows.NewAmountTA)
	|	AND (Discounting.TypeOfRegisteredRecordedLocal = VALUE(AccumulationRecordType.Receipt)
	|			OR Discounting.TypeOfManSRegisteredRecords = VALUE(AccumulationRecordType.Receipt))
	|
	|INDEX BY
	|	DimensionOfExpenses,
	|	RowID";
	
	QueryTexts.Add(QueryText, RegisterName);
	Return QueryText;
	
EndFunction

Procedure QueryTextTableTTDiscounting(Query, QueryTexts)
	
	RegisterName = "TTDiscounting";
	
	If DocumentsPosting.ThereIsQueryTable(RegisterName, QueryTexts) Then
		Return;
	EndIf;
	
	// The discount amount is determined by the formula:
	// S% = Sn * (1 – 1/(1 + Rate) ^(tn/365)), where
	// sn is the nominal cost of the liquidation obligation,
	// tn is the time in days remaining until the date of fulfillment of the obligation.
	
	QueryText = 
	"SELECT
	|	DiscountTable.LineOfBusiness AS LineOfBusiness,
	|	DiscountTable.ProvisionObject AS ProvisionObject,
	|
	|	DiscountTable.SumCompl * (1 - 1 / POW(1 + &DiscountRate / 100, DATEDIFF(CASE
	|					WHEN BEGINOFPERIOD(&BeginOfPeriod, MONTH) > BEGINOFPERIOD(DiscountTable.CompletionDate, MONTH)
	|						THEN DiscountTable.CompletionDate
	|					ELSE &BeginOfPeriod
	|				END,
	|		DiscountTable.CompletionDate, DAY) / 365)) AS DiscountingAmountCompl,
	|
	|	DiscountTable.SumMan * (1 - 1 / POW(1 + &DiscountRate / 100, DATEDIFF(CASE
	|					WHEN BEGINOFPERIOD(&BeginOfPeriod, MONTH) > BEGINOFPERIOD(DiscountTable.CompletionDate, MONTH)
	|						THEN DiscountTable.CompletionDate
	|					ELSE &BeginOfPeriod
	|				END,
	|		DiscountTable.CompletionDate, DAY) / 365)) AS DiscountingAmountMan,
	|	DiscountTable.RowID AS RowID
	|
	|INTO TTDiscounting
	|
	|FROM
	|	(SELECT
	|		Rows.LineOfBusiness AS LineOfBusiness,
	|		Rows.ProvisionObject AS ProvisionObject,
	|
	|		CASE
	|			WHEN Rows.SetNewAmountLocal
	|				THEN Rows.NewAmountLocal
	|			ELSE Rows.CurrentAmountLocal
	|		END AS SumCompl,
	|
	|		CASE
	|			WHEN Rows.SetNewAmountMan
	|				THEN Rows.NewAmountMan
	|			ELSE Rows.CurrentAmountMan
	|		END AS SumMan,
	|
	|		CASE
	|			WHEN Rows.SetNewExecutionDate
	|				THEN Rows.NewExecutionDate
	|			ELSE Rows.CompletionDate
	|		END AS CompletionDate,
	|
	|		Rows.RowID AS RowID
	|	FROM
	|		Document.FutureExpenseCommitmentsAccrualWriteOff.Reserves AS Rows
	|
	|			LEFT JOIN InformationRegister.ProvisionDiscountingRates.SliceLast(
	|				&BeginOfPeriod,
	|				Organization = &Organization
	|					AND ReserveKind = &ReserveKind
	|					AND Recorder <> &Ref) AS ProvisionDiscountingRates
	|			ON TRUE
	|
	|	WHERE
	|		&DiscountingOfEstimatedObligation
	|		AND Rows.Ref = &Ref
	|		AND (Rows.NewAmountLocal <> 0 OR Rows.CurrentAmountLocal <> 0 OR Rows.NewAmountMan <> 0 OR Rows.CurrentAmountMan <> 0)
	|		AND (Rows.SetNewAmountLocal
	|					AND Rows.NewAmountLocal <> Rows.CurrentAmountLocal
	|				OR Rows.SetNewAmountMan
	|					AND Rows.NewAmountMan <> Rows.CurrentAmountMan
	|				OR Rows.SetNewExecutionDate
	|					AND Rows.NewExecutionDate <> Rows.CompletionDate
	|				OR ISNULL(ProvisionDiscountingRates.DiscountRate, 0) <> &DiscountRate)
	|	
	|	) DiscountTable
	|
	|INDEX BY
	|	LineOfBusiness,
	|	ProvisionObject";
	
	QueryTexts.Add(QueryText, RegisterName);
	
EndProcedure

Procedure QueryTextTableTueReserveBalances(Query, QueryTexts)
	
	RegisterName = "TueReserveBalances";
	
	If DocumentsPosting.ThereIsQueryTable(RegisterName, QueryTexts) Then
		Return;
	EndIf;
	
	QueryTextTableTTDiscounting(Query, QueryTexts);
	
	QueryText = 
	"SELECT
	|	ReserveBalances.LineOfBusiness AS LineOfBusiness,
	|	ReserveBalances.ProvisionObject AS ProvisionObject,
	|	ReserveBalances.DiscountingAmountManBalance AS DiscountingAmountMan,
	|	ReserveBalances.DiscountingAmountComplBalance AS DiscountingAmountCompl
	|INTO TueReserveBalances
	|FROM
	|	AccumulationRegister.FutureExpenseCommitments.Balance(
	|		&BeginOfPeriod, 
	|		&DiscountingOfEstimatedObligation
	|			AND (Organization, ReserveKind, LineOfBusiness, ProvisionObject) IN
	|				(SELECT
	|					&Organization,
	|					&ReserveKind,
	|					T.LineOfBusiness,
	|					T.ProvisionObject
	|				FROM
	|					TTDiscounting AS T)) AS ReserveBalances
	|
	|INDEX BY
	|	LineOfBusiness,
	|	ProvisionObject";
	
	QueryTexts.Add(QueryText, RegisterName);
	
EndProcedure

Procedure QueryTextTableTTRegisteredRecordsOfDiscounting(Query, QueryTexts)
	
	RegisterName = "TTRegisteredRecordsOfDiscounting";
	
	If DocumentsPosting.ThereIsQueryTable(RegisterName, QueryTexts) Then
		Return;
	EndIf;
	
	QueryTextTableTTDiscounting(Query, QueryTexts);
	QueryTextTableTueReserveBalances(Query, QueryTexts);
	
	QueryText = 
	"SELECT
	|	DiscountTable.LineOfBusiness AS LineOfBusiness,
	|	DiscountTable.ProvisionObject AS ProvisionObject,
	|	DiscountTable.TypeOfRegisteredRecordedLocal AS TypeOfRegisteredRecordedLocal,
	|	DiscountTable.TypeOfManSRegisteredRecords AS TypeOfManSRegisteredRecords,
	|	DiscountTable.DiscountingAmountCompl AS DiscountingAmountCompl,
	|	DiscountTable.DiscountingAmountMan AS DiscountingAmountMan,
	|	DiscountTable.RowID AS RowID
	|
	|INTO TTRegisteredRecordsOfDiscounting
	|
	|FROM
	|	(SELECT
	|		DiscountTable.LineOfBusiness AS LineOfBusiness,
	|		DiscountTable.ProvisionObject AS ProvisionObject,
	|
	|		CASE
	|			WHEN DiscountTable.DiscountingAmountCompl > ISNULL(TueReserveBalances.DiscountingAmountCompl, 0)
	|				THEN VALUE(AccumulationRecordType.Receipt)
	|			ELSE VALUE(AccumulationRecordType.Expense)
	|		END AS TypeOfRegisteredRecordedLocal,
	|
	|		CASE
	|			WHEN DiscountTable.DiscountingAmountMan > ISNULL(TueReserveBalances.DiscountingAmountMan, 0)
	|				THEN VALUE(AccumulationRecordType.Receipt)
	|			ELSE VALUE(AccumulationRecordType.Expense)
	|		END AS TypeOfManSRegisteredRecords,
	|
	|		CASE
	|			WHEN DiscountTable.DiscountingAmountCompl > ISNULL(TueReserveBalances.DiscountingAmountCompl, 0)
	|				THEN DiscountTable.DiscountingAmountCompl - ISNULL(TueReserveBalances.DiscountingAmountCompl, 0)
	|			ELSE ISNULL(TueReserveBalances.DiscountingAmountCompl, 0) - DiscountTable.DiscountingAmountCompl
	|		END AS DiscountingAmountCompl,
	|
	|		CASE
	|			WHEN DiscountTable.DiscountingAmountMan > ISNULL(TueReserveBalances.DiscountingAmountMan, 0)
	|				THEN DiscountTable.DiscountingAmountMan - ISNULL(TueReserveBalances.DiscountingAmountMan, 0)
	|			ELSE ISNULL(TueReserveBalances.DiscountingAmountMan, 0) - DiscountTable.DiscountingAmountMan
	|		END AS DiscountingAmountMan,
	|
	|		DiscountTable.RowID AS RowID
	|
	|	FROM
	|		TTDiscounting AS DiscountTable
	|
	|			LEFT JOIN TueReserveBalances AS TueReserveBalances
	|			ON DiscountTable.LineOfBusiness = TueReserveBalances.LineOfBusiness
	|				AND DiscountTable.ProvisionObject = TueReserveBalances.ProvisionObject
	|
	|	) AS DiscountTable
	|
	|WHERE
	|	(DiscountTable.DiscountingAmountCompl <> 0
	|			OR DiscountTable.DiscountingAmountMan <> 0)
	|
	|INDEX BY
	|	ProvisionObject,
	|	RowID";
	
	QueryTexts.Add(QueryText, RegisterName);
	
EndProcedure

Procedure QueryTextTableTTDataOfFixedAssets(Query, QueryTexts)
	
	RegisterName = "TTDataOfFixedAssets";
	
	If DocumentsPosting.ThereIsQueryTable(RegisterName, QueryTexts) Then
		Return;
	EndIf;
	
	QueryTextTableTTAccountingProcedureForOsuu(Query, QueryTexts);
	QueryTextTableTueAccountingProcedureForOSBU(Query, QueryTexts);
	QueryTextTableTTAccountingFA(Query, QueryTexts);
	QueryTextTableTTLocationOfFA(Query, QueryTexts);
	
	QueryText = 
	"SELECT
	|	Rows.ExpensesDimensionAccruals AS FixedAsset,
	|	Rows.RowID AS RowID,
	|	ISNULL(FixedAssetsAccountingProcedureManagementAccounting.State, UNDEFINED) = VALUE(Enum.FixedAssetsStates.Recognized_) AS TakenIntoAccountByMan,
	|	ISNULL(AccountingProcedureForOSBU.BUState, UNDEFINED) = VALUE(Enum.FixedAssetsStates.Recognized_) AS LocalRegistrationHasBeenAccepted,
	|	AccountingProcedureForOSBU.VATTaxation AS VATTaxation,
	|	FixedAssetsAccountingProcedure.FinancialAccountingGroup AS FinancialAccountingGroup,
	|	FixedAssetsAccountingProcedure.LineOfBusiness AS LineOfBusiness,
	|	FALocation.Department AS Department,
	|	FALocation.Leaseholder AS Leaseholder
	|
	|INTO TTDataOfFixedAssets
	|
	|FROM
	|	Document.FutureExpenseCommitmentsAccrualWriteOff.Reserves AS Rows
	|
	|		LEFT JOIN TTAccountingProcedureForOsuu AS FixedAssetsAccountingProcedureManagementAccounting
	|		ON Rows.ExpensesDimensionAccruals = FixedAssetsAccountingProcedureManagementAccounting.FixedAsset
	|
	|		LEFT JOIN TueAccountingProcedureForOSBU AS AccountingProcedureForOSBU
	|		ON Rows.ExpensesDimensionAccruals = AccountingProcedureForOSBU.FixedAsset
	|
	|		LEFT JOIN TTAccountingFA AS FixedAssetsAccountingProcedure
	|		ON Rows.ExpensesDimensionAccruals = FixedAssetsAccountingProcedure.FixedAsset
	|
	|		LEFT JOIN TTLocationOfFA AS FALocation
	|		ON Rows.ExpensesDimensionAccruals = FALocation.FixedAsset
	|
	|WHERE
	|	&TheseAreReservesOfLiquidationObligations
	|	AND Rows.Ref = &Ref
	|	AND VALUETYPE(Rows.ExpensesDimensionAccruals) = TYPE(Catalog.Assets)
	|
	|INDEX BY
	|	FixedAsset,
	|	RowID";
	
	QueryTexts.Add(QueryText, RegisterName);
	
EndProcedure

Procedure QueryTextTableTTAccountingProcedureForOsuu(Query, QueryTexts)
	
	RegisterName = "TTAccountingProcedureForOsuu";
	
	If DocumentsPosting.ThereIsQueryTable(RegisterName, QueryTexts) Then
		Return;
	EndIf;

	If Not DocumentsPosting.ThereIsQueryTable("TTAccruals", QueryTexts) Then
		QueryTextTableTTAccruals(Query, QueryTexts);
	EndIf;
	
	If Not DocumentsPosting.ThereIsQueryTable("TTWriteOff", QueryTexts) Then
		QueryTextTableTTWriteOff(Query, QueryTexts);
	EndIf;
	
	QueryText = 
	"SELECT
	|	FixedAssetsAccountingProcedureManagementAccounting.FixedAsset AS FixedAsset,
	|	FixedAssetsAccountingProcedureManagementAccounting.State AS State
	|INTO TTAccountingProcedureForOsuu
	|FROM
	|	InformationRegister.FixedAssetsAccountingProcedureManagementAccounting.SliceLast(
	|		&BeginOfPeriod, 
	|		&TheseAreReservesOfLiquidationObligations
	|			AND CorrectionDate = DATETIME(1,1,1)
	|			AND (FixedAsset, Organization) IN
	|				(SELECT
	|					T.DimensionOfExpenses,
	|					&Organization
	|				FROM
	|					TTAccruals AS T
	|
	|				UNION ALL
	|
	|				SELECT
	|					T.DimensionOfExpenses,
	|					&Organization
	|				FROM
	|					TTWriteOff AS T)) AS FixedAssetsAccountingProcedureManagementAccounting	
	|
	|INDEX BY
	|	FixedAsset";
	
	QueryTexts.Add(QueryText, RegisterName);
	
EndProcedure

Procedure QueryTextTableTueAccountingProcedureForOSBU(Query, QueryTexts)
	
	RegisterName = "TueAccountingProcedureForOSBU";
	
	If DocumentsPosting.ThereIsQueryTable(RegisterName, QueryTexts) Then
		Return;
	EndIf;

	If Not DocumentsPosting.ThereIsQueryTable("TTAccruals", QueryTexts) Then
		QueryTextTableTTAccruals(Query, QueryTexts);
	EndIf;
	
	If Not DocumentsPosting.ThereIsQueryTable("TTWriteOff", QueryTexts) Then
		QueryTextTableTTWriteOff(Query, QueryTexts);
	EndIf;
	
	QueryText = 
	"SELECT
	|	NULL AS FixedAsset,
	|	NULL AS BUState,
	|	NULL AS VATTaxation
	|INTO TueAccountingProcedureForOSBU";
	
	FutureExpenseCommitmentsAccrualWriteOffLocalization.QueryTextTableTTDataOfFixedAssets(QueryText);

	QueryTexts.Add(QueryText, RegisterName);
	
EndProcedure

Procedure QueryTextTableTTAccountingFA(Query, QueryTexts)
	
	RegisterName = "TTAccountingFA";
	
	If DocumentsPosting.ThereIsQueryTable(RegisterName, QueryTexts) Then
		Return;
	EndIf;
	
	If Not DocumentsPosting.ThereIsQueryTable("TTAccruals", QueryTexts) Then
		QueryTextTableTTAccruals(Query, QueryTexts);
	EndIf;
	
	If Not DocumentsPosting.ThereIsQueryTable("TTWriteOff", QueryTexts) Then
		QueryTextTableTTWriteOff(Query, QueryTexts);
	EndIf;
	
	QueryText = 
	"SELECT
	|	FixedAssetsAccountingProcedure.FixedAsset AS FixedAsset,
	|	FixedAssetsAccountingProcedure.FinancialAccountingGroup AS FinancialAccountingGroup,
	|	FixedAssetsAccountingProcedure.LineOfBusiness AS LineOfBusiness
	|INTO TTAccountingFA
	|FROM
	|	InformationRegister.FixedAssetsAccountingProcedure.SliceLast(
	|		&BeginOfPeriod, 
	|		&TheseAreReservesOfLiquidationObligations
	|			AND CorrectionDate = DATETIME(1,1,1)
	|			AND (FixedAsset, Organization) IN
	|				(SELECT
	|					T.DimensionOfExpenses,
	|					&Organization
	|				FROM
	|					TTAccruals AS T
	|
	|				UNION ALL
	|
	|				SELECT
	|					T.DimensionOfExpenses,
	|					&Organization
	|				FROM
	|					TTWriteOff AS T)) AS FixedAssetsAccountingProcedure	
	|
	|INDEX BY
	|	FixedAsset";
	
	QueryTexts.Add(QueryText, RegisterName);
	
EndProcedure

Procedure QueryTextTableTTLocationOfFA(Query, QueryTexts)
	
	RegisterName = "TTLocationOfFA";
	
	If DocumentsPosting.ThereIsQueryTable(RegisterName, QueryTexts) Then
		Return;
	EndIf;
	
	If Not DocumentsPosting.ThereIsQueryTable("TTAccruals", QueryTexts) Then
		QueryTextTableTTAccruals(Query, QueryTexts);
	EndIf;
	
	If Not DocumentsPosting.ThereIsQueryTable("TTWriteOff", QueryTexts) Then
		QueryTextTableTTWriteOff(Query, QueryTexts);
	EndIf;
	
	QueryText = 
	"SELECT
	|	FALocation.FixedAsset AS FixedAsset,
	|	FALocation.FixedAssetsLocation AS Department,
	|	FALocation.Leaseholder AS Leaseholder
	|INTO TTLocationOfFA
	|FROM
	|	InformationRegister.FALocation.SliceLast(
	|		&BeginOfPeriod, 
	|		&TheseAreReservesOfLiquidationObligations
	|			AND CorrectionDate = DATETIME(1,1,1)
	|			AND (FixedAsset) IN
	|				(SELECT
	|					T.DimensionOfExpenses
	|				FROM
	|					TTAccruals AS T
	|
	|				UNION ALL
	|
	|				SELECT
	|					T.DimensionOfExpenses
	|				FROM
	|					TTWriteOff AS T)) AS FALocation
	|
	|INDEX BY
	|	FixedAsset";
	
	QueryTexts.Add(QueryText, RegisterName);
	
EndProcedure

Procedure QueryTextTableTTCostOfFixedAssets(Query, QueryTexts)
	
	RegisterName = "TTCostOfFixedAssets";
	
	If DocumentsPosting.ThereIsQueryTable(RegisterName, QueryTexts) Then
		Return;
	EndIf;
	
	If Not Query.Parameters.TheseAreReservesOfLiquidationObligations Then
		QueryText = 
		"SELECT
		|	Rows.DimensionOfExpenses AS FixedAsset,
		|	Rows.RowID AS RowID,
		|	0 AS BalanceOfNetInitialCostCo,
		|	0 AS BalanceOfCostLocal
		|INTO TTCostOfFixedAssets
		|FROM
		|	TTWriteOff AS Rows
		|
		|INDEX BY
		|	FixedAsset,
		|	RowID
		|";
		
	ElsIf Not Query.Parameters.NegativeCostIsPossible Then
		
		If Not DocumentsPosting.ThereIsQueryTable("TTWriteOff", QueryTexts) Then
			QueryTextTableTTWriteOff(Query, QueryTexts);
		EndIf;
		
		QueryTextTableCostTTOfFA(Query, QueryTexts, "TTWriteOff");
		QueryTextTableTTDepreciationFA(Query, QueryTexts, "TTWriteOff");
		QueryTextTableTTImpairmentOfVna(Query, QueryTexts, "TTWriteOff");
		
		QueryText = 
		"SELECT
		|	Rows.DimensionOfExpenses AS FixedAsset,
		|	Rows.RowID AS RowID,
		|	ISNULL(FACost.BalanceOfNetInitialCostCo, 0) - ISNULL(FixedAssetsDepreciationCharge.DepreciationBalanceMan, 0) -
		|		ISNULL(ImpairmentFA.ImpairmentBalanceMan, 0) AS BalanceOfNetInitialCostCo,
		|	ISNULL(FACost.BalanceOfCostLocal, 0) - ISNULL(FixedAssetsDepreciationCharge.BalanceOfDepreciationIsLocal, 0) -
		|		ISNULL(ImpairmentFA.ImpairmentBalanceLocal, 0) AS BalanceOfCostLocal
		|INTO TTCostOfFixedAssets
		|FROM
		|	TTWriteOff AS Rows
		|		LEFT JOIN CostTTOfFA AS FACost
		|		ON Rows.DimensionOfExpenses = FACost.FixedAsset
		|		LEFT JOIN TTDepreciationFA AS FixedAssetsDepreciationCharge
		|		ON Rows.DimensionOfExpenses = FixedAssetsDepreciationCharge.FixedAsset
		|		LEFT JOIN TTImpairmentOfVna AS ImpairmentFA
		|		ON Rows.DimensionOfExpenses = ImpairmentFA.FixedAsset
		|WHERE
		|	&TheseAreReservesOfLiquidationObligations
		|
		|INDEX BY
		|	FixedAsset,
		|	RowID";
		
	Else
		
		If Not DocumentsPosting.ThereIsQueryTable("TTExtendedFATable", QueryTexts) Then
			QueryTextTableTTExtendedFATable(Query, QueryTexts);
		EndIf;
		
		QueryTextTableCostTTOfFA(Query, QueryTexts, "TTExtendedFATable");
		QueryTextTableTTDepreciationFA(Query, QueryTexts, "TTExtendedFATable");
		QueryTextTableTTImpairmentOfVna(Query, QueryTexts, "TTExtendedFATable");
		NonCurrentAssetsInternal.QueryTextTableWDepreciationParametersOfOSBU(QueryTexts, "TTExtendedFATable");
		NonCurrentAssetsInternal.QueryTextTableTTOsuuDepreciationParameters(QueryTexts, "TTExtendedFATable");
		
		QueryText = 
		"SELECT
		|	Rows.DimensionOfExpenses AS FixedAsset,
		|	Rows.RowID AS RowID,
		|	SUM(ISNULL(FACost.BalanceOfNetInitialCostCo, 0) - ISNULL(FixedAssetsDepreciationCharge.DepreciationBalanceMan, 0) -
		|		ISNULL(ImpairmentFA.ImpairmentBalanceMan, 0) -
		|		ISNULL(FixedAssetDepreciationParametersManagementAccounting.ResidualValueMan, 0)) AS BalanceOfNetInitialCostCo,
		|	SUM(ISNULL(FACost.BalanceOfCostLocal, 0) - ISNULL(FixedAssetsDepreciationCharge.BalanceOfDepreciationIsLocal, 0) -
		|		ISNULL(ImpairmentFA.ImpairmentBalanceLocal, 0) -
		|		ISNULL(OSBUDepreciationParameters.ResidualValueMan, 0)) AS BalanceOfCostLocal
		|INTO TTCostOfFixedAssets
		|FROM
		|	TTWriteOff AS Rows
		|		LEFT JOIN TTExtendedFATable AS FATable
		|		ON Rows.DimensionOfExpenses = FATable.LOComponent
		|		LEFT JOIN CostTTOfFA AS FACost
		|		ON FATable.FixedAsset = FACost.FixedAsset
		|		LEFT JOIN TTDepreciationFA AS FixedAssetsDepreciationCharge
		|		ON FATable.FixedAsset = FixedAssetsDepreciationCharge.FixedAsset
		|		LEFT JOIN TTImpairmentOfVna AS ImpairmentFA
		|		ON FATable.FixedAsset = ImpairmentFA.FixedAsset
		|		LEFT JOIN WDepreciationParametersOfOSBU AS OSBUDepreciationParameters
		|		ON FATable.FixedAsset = OSBUDepreciationParameters.FixedAsset
		|		LEFT JOIN TTOsuuDepreciationParameters AS FixedAssetDepreciationParametersManagementAccounting
		|		ON FATable.FixedAsset = FixedAssetDepreciationParametersManagementAccounting.FixedAsset
		|WHERE
		|	&TheseAreReservesOfLiquidationObligations
		|
		|GROUP BY
		|	Rows.DimensionOfExpenses,
		|	Rows.RowID
		|
		|INDEX BY
		|	FixedAsset,
		|	RowID
		|";
	EndIf;
	
	QueryTexts.Add(QueryText, RegisterName);
	
EndProcedure

Procedure QueryTextTableTTFAList(Query, QueryTexts)
	
	RegisterName = "TTFAList";
	
	If DocumentsPosting.ThereIsQueryTable(RegisterName, QueryTexts) Then
		Return;
	EndIf;
	
	If Not DocumentsPosting.ThereIsQueryTable("TTWriteOff", QueryTexts) Then
		QueryTextTableTTWriteOff(Query, QueryTexts);
	EndIf;
	
	QueryText = 
	"SELECT
	|	&Ref AS Ref,
	|	&Period AS Period,
	|	&Organization AS Organization,
	|	FATable.FixedAsset,
	|	FATable.LOComponent
	|INTO TTFAList
	|FROM
	|	(SELECT
	|		ISNULL(NodesComponents.FixedAsset, Rows.DimensionOfExpenses) AS FixedAsset,
	|		Rows.DimensionOfExpenses AS LOComponent
	|	FROM
	|		TTWriteOff AS Rows
	|			LEFT JOIN InformationRegister.SubAssetsComponentsOfDepreciation AS NodesComponents
	|			ON NodesComponents.SubAssetComponent = Rows.DimensionOfExpenses) AS FATable
	|
	|INDEX BY
	|	FixedAsset";
	
	QueryTexts.Add(QueryText, RegisterName);
	
EndProcedure

Procedure QueryTextTableTTExtendedFATable(Query, QueryTexts)
	
	RegisterName = "TTExtendedFATable";
	
	If Not DocumentsPosting.ThereIsQueryTable("TTFAList", QueryTexts) Then
		QueryTextTableTTFAList(Query, QueryTexts);
	EndIf;
	
	NonCurrentAssetsInternal.QueryTextTableTTUnitsDepreciationComponents(QueryTexts, "TTFAList");
	
	QueryText =
	"SELECT
	|	FATable.LOComponent      AS LOComponent,
	|	FATable.FixedAsset AS FixedAsset,
	|	VALUE(Catalog.Assets.EmptyRef) AS FAOwner
	|INTO TTExtendedFATable
	|FROM
	|	TTFAList AS FATable
	|WHERE
	|	FATable.Ref = &Ref
	|
	|UNION ALL
	|
	|SELECT
	|	FATable.LOComponent,
	|	NodesComponents.SubAssetComponent AS FixedAsset,
	|	FATable.FixedAsset   AS FAOwner
	|FROM
	|	TTFAList AS FATable
	|		INNER JOIN InformationRegister.SubAssetsComponentsOfDepreciation.SliceLast(&Period, SubAssetComponent IN
	|			(SELECT
	|				NodeTable_.SubAssetComponent AS SubAssetComponent
	|			FROM
	|				TTUnitsDepreciationComponents AS NodeTable_)) AS NodesComponents
	|		ON FATable.FixedAsset = NodesComponents.FixedAsset
	|WHERE
	|	FATable.Ref = &Ref
	|
	|INDEX BY
	|	FixedAsset";
	
	QueryTexts.Add(QueryText, RegisterName);
	
EndProcedure

Procedure QueryTextTableCostTTOfFA(Query, QueryTexts, FATable)
	
	RegisterName = "CostTTOfFA";
	
	If DocumentsPosting.ThereIsQueryTable(RegisterName, QueryTexts) Then
		Return;
	EndIf;
	
	QueryText = 
	"SELECT
	|	FACost.FixedAsset AS FixedAsset,
	|	FACost.CostBalance AS BalanceOfNetInitialCostCo,
	|	FACost.LocalCostBalance AS BalanceOfCostLocal
	|INTO CostTTOfFA
	|FROM
	|	AccumulationRegister.FACost.Balance(&PeriodOfCostBalances, &TheseAreReservesOfLiquidationObligations
	|	AND (Organization, FixedAsset) IN
	|		(SELECT
	|			&Organization,
	|			T.FixedAsset
	|		FROM
	|			TTExtendedFATable AS T)) AS FACost
	|
	|INDEX BY
	|	FixedAsset";
	
	QueryText = StrReplace(QueryText, "TTExtendedFATable", FATable);
	QueryTexts.Add(QueryText, RegisterName);
	
EndProcedure

Procedure QueryTextTableTTDepreciationFA(Query, QueryTexts, FATable)
	
	RegisterName = "TTDepreciationFA";
	
	If DocumentsPosting.ThereIsQueryTable(RegisterName, QueryTexts) Then
		Return;
	EndIf;

	QueryText = 
	"SELECT
	|	FixedAssetsDepreciationCharge.FixedAsset AS FixedAsset,
	|	-FixedAssetsDepreciationCharge.DepreciationBalance AS DepreciationBalanceMan,
	|	-FixedAssetsDepreciationCharge.DepreciationLocalBalance AS BalanceOfDepreciationIsLocal
	|INTO TTDepreciationFA
	|FROM
	|	AccumulationRegister.FixedAssetsDepreciationCharge.Balance(&PeriodOfCostBalances, &TheseAreReservesOfLiquidationObligations
	|	AND (Organization, FixedAsset) IN
	|		(SELECT
	|			&Organization,
	|			T.FixedAsset
	|		FROM
	|			TTExtendedFATable AS T)) AS FixedAssetsDepreciationCharge
	|
	|INDEX BY
	|	FixedAsset";
	
	QueryText = StrReplace(QueryText, "TTExtendedFATable", FATable);
	QueryTexts.Add(QueryText, RegisterName);
	
EndProcedure

Procedure QueryTextTableTTCompositionOfCGU(Query, QueryTexts, FATable)
	
	RegisterName = "TTCompositionOfCGU";
	
	If DocumentsPosting.ThereIsQueryTable(RegisterName, QueryTexts) Then
		Return;
	EndIf;
	
	QueryText = 
	"SELECT
	|	CGUComposition.NonCurrentAsset AS NonCurrentAsset,
	|	CGUComposition.Organization AS Organization,
	|	CGUComposition.CGU AS CGU
	|INTO TTCompositionOfCGU
	|FROM
	|	InformationRegister.CGUComposition.SliceLast(&PeriodOfCostBalances, &TheseAreReservesOfLiquidationObligations
	|	AND (NonCurrentAsset, Organization) IN
	|		(SELECT
	|			T.FixedAsset,
	|			&Organization
	|		FROM
	|			TTExtendedFATable AS T)) AS CGUComposition
	|
	|INDEX BY
	|	NonCurrentAsset,
	|	Organization,
	|	CGU";
	
	QueryText = StrReplace(QueryText, "TTExtendedFATable", FATable);
	QueryTexts.Add(QueryText, RegisterName);
	
EndProcedure

Procedure QueryTextTableTTImpairmentOfVna(Query, QueryTexts, FATable)
	
	RegisterName = "TTImpairmentOfVna";
	
	If DocumentsPosting.ThereIsQueryTable(RegisterName, QueryTexts) Then
		Return;
	EndIf;

	QueryTextTableTTCompositionOfCGU(Query, QueryTexts, FATable);
	
	QueryText = 
	"SELECT
	|	ImpairmentFA.NonCurrentAsset AS FixedAsset,
	|	-ImpairmentFA.ImpairmenManBalance AS ImpairmentBalanceMan,
	|	-ImpairmentFA.ImpairmentLocalAssetsBalance AS ImpairmentBalanceLocal
	|INTO TTImpairmentOfVna
	|FROM
	|	AccumulationRegister.ImpairmentFA.Balance(&PeriodOfCostBalances, &TheseAreReservesOfLiquidationObligations
	|	AND (NonCurrentAsset, CGU, Organization) IN
	|		(SELECT
	|			T.NonCurrentAsset,
	|			T.CGU,
	|			T.Organization
	|		FROM
	|			TTCompositionOfCGU AS T)) AS ImpairmentFA
	|
	|INDEX BY
	|	FixedAsset";
	
	QueryTexts.Add(QueryText, RegisterName);
	
EndProcedure

Function QueryTextTableTTInitialOtherExpenses(Query, QueryTexts)
	
	RegisterName = "TTInitialOtherExpenses";
	
	If Not DocumentsPosting.ThereIsQueryTable("TTAccruals", QueryTexts) Then
		QueryTextTableTTAccruals(Query, QueryTexts);
	EndIf;
	
	If Not DocumentsPosting.ThereIsQueryTable("TTWriteOff", QueryTexts) Then
		QueryTextTableTTWriteOff(Query, QueryTexts);
	EndIf;
	
	QueryTextTableTTDataOfFixedAssets(Query, QueryTexts);
	
	QueryText = "SELECT
	|	CASE
	|		WHEN &DiscountingOfEstimatedObligation
	|			THEN &BeginOfPeriod
	|		ELSE &Period
	|	END AS Period,
	|	VALUE(AccumulationRecordType.Receipt) AS RecordType,
	|	&Organization AS Organization,
	|	AccrualTable.Department AS Department,
	|	AccrualTable.LineOfBusinessAccruals AS LineOfBusiness,
	|	AccrualTable.ExpenseItem AS ExpenseItem,
	|	AccrualTable.DimensionOfExpenses AS DimensionOfExpenses,
	|	UNDEFINED AS VATActivityType,
	|	0 AS AmountIncludingVAT,
	|	0 AS AmountExcludingVAT,
	|	SUM(AccrualTable.SumMan) AS AmountExcludingVATMan,
	|	SUM(AccrualTable.SumCompl) AS AmountIncludingVATCompl,
	|	SUM(AccrualTable.SumCompl) AS AmountExcludingVATCompl,
	|	0 AS PermanentDifference,
	|	SUM(AccrualTable.SumCompl) - SUM(AccrualTable.AmountFA) AS CostTD,
	|	CASE
	|		WHEN AccrualTable.ThisChangeIsOnlyDiscountPercentage
	|			THEN VALUE(Enum.BusinessTransactions.DiscountingInterestWriteOff)
	|		ELSE VALUE(Enum.BusinessTransactions.FutureExpenseCommitmentsAccrual)
	|	END AS BusinessOperation,
	|	UNDEFINED AS ItemsLocationAttributes,
	|	AccrualTable.RowID AS FinRecordID,
	|	CASE
	|		WHEN AccrualTable.ThisChangeIsOnlyDiscountPercentage
	|			THEN VALUE(Catalog.BusinessTransactionsSettings.DiscountingInterestWriteOff)
	|		ELSE VALUE(Catalog.BusinessTransactionsSettings.FutureExpenseCommitmentsAccrual)
	|	END AS BusinessTransactionSetting
	|INTO TTInitialOtherExpenses
	|FROM
	|	TTAccruals AS AccrualTable
	|WHERE
	|	NOT &TheseAreReservesOfLiquidationObligations
	|GROUP BY
	|	AccrualTable.ExpenseItem,
	|	AccrualTable.DimensionOfExpenses,
	|	AccrualTable.Department,
	|	AccrualTable.LineOfBusinessAccruals,
	|	CASE
	|		WHEN AccrualTable.ThisChangeIsOnlyDiscountPercentage
	|			THEN VALUE(Enum.BusinessTransactions.DiscountingInterestWriteOff)
	|		ELSE VALUE(Enum.BusinessTransactions.FutureExpenseCommitmentsAccrual)
	|	END,
	|	CASE
	|		WHEN AccrualTable.ThisChangeIsOnlyDiscountPercentage
	|			THEN VALUE(Catalog.BusinessTransactionsSettings.DiscountingInterestWriteOff)
	|		ELSE VALUE(Catalog.BusinessTransactionsSettings.FutureExpenseCommitmentsAccrual)
	|	END,
	|	AccrualTable.RowID
	|
	|UNION ALL
	|
	|SELECT
	|	&BeginOfPeriod AS Period,
	|	VALUE(AccumulationRecordType.Receipt) AS RecordType,
	|	&Organization AS Organization,
	|	AccrualTable.Department AS Department,
	|	AccrualTable.LineOfBusinessAccruals AS LineOfBusiness,
	|	AccrualTable.ExpenseItem AS ExpenseItem,
	|	AccrualTable.DimensionOfExpenses AS DimensionOfExpenses,
	|	UNDEFINED AS VATActivityType,
	|	0 AS AmountIncludingVAT,
	|	0 AS AmountExcludingVAT,
	|	SUM(CASE
	|		WHEN NOT TTDataOfFixedAssets.TakenIntoAccountByMan
	|			THEN AccrualTable.SumMan
	|		ELSE 0
	|	END) AS AmountExcludingVATMan,
	|	SUM(CASE
	|		WHEN NOT TTDataOfFixedAssets.LocalRegistrationHasBeenAccepted
	|			THEN AccrualTable.SumCompl
	|		ELSE 0
	|	END) AS AmountIncludingVATCompl,
	|	SUM(CASE
	|		WHEN NOT TTDataOfFixedAssets.LocalRegistrationHasBeenAccepted
	|			THEN AccrualTable.SumCompl
	|		ELSE 0
	|	END) AS AmountExcludingVATCompl,
	|	0 AS PermanentDifference,
	|	SUM(CASE
	|		WHEN NOT TTDataOfFixedAssets.LocalRegistrationHasBeenAccepted
	|			THEN AccrualTable.SumCompl
	|		ELSE 0
	|	END) AS CostTD,
	|	CASE
	|		WHEN AccrualTable.ThisChangeIsOnlyDiscountPercentage
	|			THEN VALUE(Enum.BusinessTransactions.DiscountingInterestWriteOff)
	|		ELSE VALUE(Enum.BusinessTransactions.FutureExpenseCommitmentsAccrual)
	|	END AS BusinessOperation,
	|	UNDEFINED AS ItemsLocationAttributes,
	|	AccrualTable.RowID AS FinRecordID,
	|	CASE
	|		WHEN AccrualTable.ThisChangeIsOnlyDiscountPercentage
	|			THEN VALUE(Catalog.BusinessTransactionsSettings.DiscountingInterestWriteOff)
	|		ELSE VALUE(Catalog.BusinessTransactionsSettings.FutureExpenseCommitmentsAccrual)
	|	END AS BusinessTransactionSetting
	|FROM
	|	TTAccruals AS AccrualTable
	|		LEFT JOIN TTDataOfFixedAssets AS TTDataOfFixedAssets
	|		ON AccrualTable.DimensionOfExpenses = TTDataOfFixedAssets.FixedAsset
	|		AND AccrualTable.RowID = TTDataOfFixedAssets.RowID
	|WHERE
	|	&TheseAreReservesOfLiquidationObligations
	|	AND (NOT TTDataOfFixedAssets.TakenIntoAccountByMan
	|	OR NOT TTDataOfFixedAssets.LocalRegistrationHasBeenAccepted)
	|GROUP BY
	|	AccrualTable.ExpenseItem,
	|	AccrualTable.DimensionOfExpenses,
	|	AccrualTable.Department,
	|	AccrualTable.LineOfBusinessAccruals,
	|	CASE
	|		WHEN AccrualTable.ThisChangeIsOnlyDiscountPercentage
	|			THEN VALUE(Enum.BusinessTransactions.DiscountingInterestWriteOff)
	|		ELSE VALUE(Enum.BusinessTransactions.FutureExpenseCommitmentsAccrual)
	|	END,
	|	CASE
	|		WHEN AccrualTable.ThisChangeIsOnlyDiscountPercentage
	|			THEN VALUE(Catalog.BusinessTransactionsSettings.DiscountingInterestWriteOff)
	|		ELSE VALUE(Catalog.BusinessTransactionsSettings.FutureExpenseCommitmentsAccrual)
	|	END,
	|	AccrualTable.RowID
	|
	|UNION ALL
	|
	|SELECT
	|	&BeginOfPeriod AS Period,
	|	VALUE(AccumulationRecordType.Receipt) AS RecordType,
	|	&Organization AS Organization,
	|	AccrualTable.Department AS Department,
	|	AccrualTable.LineOfBusinessExpenses AS LineOfBusiness,
	|	AccrualTable.ExpenseItem AS ExpenseItem,
	|	AccrualTable.DimensionOfExpenses AS DimensionOfExpenses,
	|	UNDEFINED AS VATActivityType,
	|	0 AS AmountIncludingVAT,
	|	0 AS AmountExcludingVAT,
	|	SUM(CASE
	|		WHEN AccrualTable.ThisChangeIsOnlyDiscountPercentage
	|			THEN -AccrualTable.SumMan
	|		WHEN NOT TTDataOfFixedAssets.TakenIntoAccountByMan
	|			THEN -AccrualTable.SumMan
	|		ELSE 0
	|	END) AS AmountExcludingVATMan,
	|	SUM(CASE
	|		WHEN AccrualTable.ThisChangeIsOnlyDiscountPercentage
	|			THEN -AccrualTable.SumCompl
	|		WHEN NOT TTDataOfFixedAssets.LocalRegistrationHasBeenAccepted
	|			THEN -AccrualTable.SumCompl
	|		ELSE 0
	|	END) AS AmountIncludingVATCompl,
	|	SUM(CASE
	|		WHEN AccrualTable.ThisChangeIsOnlyDiscountPercentage
	|			THEN -AccrualTable.SumCompl
	|		WHEN NOT TTDataOfFixedAssets.LocalRegistrationHasBeenAccepted
	|			THEN -AccrualTable.SumCompl
	|		ELSE 0
	|	END) AS AmountExcludingVATCompl,
	|	0 AS PermanentDifference,
	|	SUM(CASE
	|		WHEN AccrualTable.ThisChangeIsOnlyDiscountPercentage
	|			THEN -AccrualTable.SumCompl
	|		WHEN NOT TTDataOfFixedAssets.LocalRegistrationHasBeenAccepted
	|			THEN -AccrualTable.SumCompl
	|		ELSE 0
	|	END) AS CostTD,
	|	CASE
	|		WHEN AccrualTable.ThisChangeIsOnlyDiscountPercentage
	|			THEN VALUE(Enum.BusinessTransactions.AccrualOfInterestOnDiscounting)
	|		ELSE VALUE(Enum.BusinessTransactions.FutureExpenseCommitmentsWriteOff)
	|	END AS BusinessOperation,
	|	UNDEFINED AS ItemsLocationAttributes,
	|	AccrualTable.RowID AS FinRecordID,
	|	CASE
	|		WHEN AccrualTable.ThisChangeIsOnlyDiscountPercentage
	|			THEN VALUE(Catalog.BusinessTransactionsSettings.AccrualOfInterestOnDiscounting)
	|		ELSE VALUE(Catalog.BusinessTransactionsSettings.FutureExpenseCommitmentsWriteOff)
	|	END AS BusinessTransactionSetting
	|FROM
	|	TTWriteOff AS AccrualTable
	|		LEFT JOIN TTDataOfFixedAssets AS TTDataOfFixedAssets
	|		ON AccrualTable.DimensionOfExpenses = TTDataOfFixedAssets.FixedAsset
	|		AND AccrualTable.RowID = TTDataOfFixedAssets.RowID
	|WHERE
	|	&TheseAreReservesOfLiquidationObligations
	|	AND (NOT TTDataOfFixedAssets.TakenIntoAccountByMan
	|	OR NOT TTDataOfFixedAssets.LocalRegistrationHasBeenAccepted)
	|GROUP BY
	|	AccrualTable.ExpenseItem,
	|	AccrualTable.DimensionOfExpenses,
	|	AccrualTable.Department,
	|	AccrualTable.LineOfBusinessExpenses,
	|	CASE
	|		WHEN AccrualTable.ThisChangeIsOnlyDiscountPercentage
	|			THEN VALUE(Enum.BusinessTransactions.AccrualOfInterestOnDiscounting)
	|		ELSE VALUE(Enum.BusinessTransactions.FutureExpenseCommitmentsWriteOff)
	|	END,
	|	CASE
	|		WHEN AccrualTable.ThisChangeIsOnlyDiscountPercentage
	|			THEN VALUE(Catalog.BusinessTransactionsSettings.AccrualOfInterestOnDiscounting)
	|		ELSE VALUE(Catalog.BusinessTransactionsSettings.FutureExpenseCommitmentsWriteOff)
	|	END,
	|	AccrualTable.RowID";
	
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

Function QueryTextOtherExpenses(Query, QueryTexts, Registers)
	
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

Procedure QueryTextOtherIncome(Query, QueryTexts, Registers)
	
	RegisterName = "OtherIncome";
	
	If Not DocumentsPosting.RequiresTableForRegisteredRecords(RegisterName, Registers) Then
		Return;
	EndIf;
	
	If Not DocumentsPosting.ThereIsQueryTable("TTWriteOff", QueryTexts) Then
		QueryTextTableTTWriteOff(Query, QueryTexts);
	EndIf;
	
	QueryTextTableTTDataOfFixedAssets(Query, QueryTexts);
	QueryTextTableTTCostOfFixedAssets(Query, QueryTexts);
	
	QueryText =
	"SELECT
	|	CASE
	|		WHEN &DiscountingOfEstimatedObligation
	|			THEN &BeginOfPeriod
	|		ELSE &Period
	|	END AS Period,
	|	&Organization AS Organization,
	|	TableOfDebits.Department AS Department,
	|	TableOfDebits.LineOfBusinessExpenses AS LineOfBusiness,
	|	TableOfDebits.IncomeItem AS IncomeItem,
	|	TableOfDebits.DimensionOfRevenue AS DimensionOfRevenue,
	|	SUM(0) AS Sum,
	|	SUM(TableOfDebits.SumCompl) AS SumCompl,
	|	SUM(TableOfDebits.SumMan) AS SumMan,
	|	CASE
	|		WHEN TableOfDebits.ThisChangeIsOnlyDiscountPercentage
	|			THEN VALUE(Enum.BusinessTransactions.AccrualOfInterestOnDiscounting)
	|		ELSE VALUE(Enum.BusinessTransactions.FutureExpenseCommitmentsWriteOff)
	|	END AS BusinessOperation,
	|	
	|	TableOfDebits.RowID AS FinRecordID,
	|	CASE
	|		WHEN TableOfDebits.ThisChangeIsOnlyDiscountPercentage
	|			THEN VALUE(Catalog.BusinessTransactionsSettings.AccrualOfInterestOnDiscounting)
	|		ELSE VALUE(Catalog.BusinessTransactionsSettings.FutureExpenseCommitmentsWriteOff)
	|	END AS BusinessTransactionSetting
	|	
	|FROM
	|	TTWriteOff AS TableOfDebits
	|WHERE
	|	NOT &TheseAreReservesOfLiquidationObligations
	|
	|GROUP BY
	|	TableOfDebits.IncomeItem,
	|	TableOfDebits.DimensionOfRevenue,
	|	TableOfDebits.Department,
	|	TableOfDebits.LineOfBusinessExpenses,
	|	CASE
	|		WHEN TableOfDebits.ThisChangeIsOnlyDiscountPercentage
	|			THEN VALUE(Enum.BusinessTransactions.AccrualOfInterestOnDiscounting)
	|		ELSE VALUE(Enum.BusinessTransactions.FutureExpenseCommitmentsWriteOff)
	|	END,
	|	CASE
	|		WHEN TableOfDebits.ThisChangeIsOnlyDiscountPercentage
	|			THEN VALUE(Catalog.BusinessTransactionsSettings.AccrualOfInterestOnDiscounting)
	|		ELSE VALUE(Catalog.BusinessTransactionsSettings.FutureExpenseCommitmentsWriteOff)
	|	END,
	|	TableOfDebits.RowID
	|
	|UNION ALL
	|
	|SELECT
	|	&BeginOfPeriod AS Period,
	|	&Organization AS Organization,
	|	TableOfDebits.Department AS Department,
	|	TableOfDebits.LineOfBusinessExpenses AS LineOfBusiness,
	|	TableOfDebits.IncomeItem AS IncomeItem,
	|	TableOfDebits.DimensionOfRevenue AS DimensionOfRevenue,
	|	SUM(0) AS Sum,
	|	SUM(CASE
	|		WHEN TTDataOfFixedAssets.LocalRegistrationHasBeenAccepted
	|				AND TTCostOfFixedAssets.BalanceOfCostLocal < 0
	|			THEN TableOfDebits.SumCompl
	|		WHEN TTDataOfFixedAssets.LocalRegistrationHasBeenAccepted
	|				AND TTCostOfFixedAssets.BalanceOfCostLocal < TableOfDebits.SumCompl
	|			THEN TableOfDebits.SumCompl - TTCostOfFixedAssets.BalanceOfCostLocal
	|		ELSE 0
	|	END) AS SumCompl,
	|	SUM(CASE
	|		WHEN TTDataOfFixedAssets.TakenIntoAccountByMan
	|				AND TTCostOfFixedAssets.BalanceOfNetInitialCostCo < 0
	|			THEN TableOfDebits.SumMan
	|		WHEN TTDataOfFixedAssets.TakenIntoAccountByMan
	|				AND TTCostOfFixedAssets.BalanceOfNetInitialCostCo < TableOfDebits.SumMan
	|			THEN TableOfDebits.SumMan - TTCostOfFixedAssets.BalanceOfNetInitialCostCo
	|		ELSE 0
	|	END) AS SumMan,
	|	CASE
	|		WHEN TableOfDebits.ThisChangeIsOnlyDiscountPercentage
	|			THEN VALUE(Enum.BusinessTransactions.AccrualOfInterestOnDiscounting)
	|		ELSE VALUE(Enum.BusinessTransactions.FutureExpenseCommitmentsWriteOff)
	|	END AS BusinessOperation,
	|	
	|	TableOfDebits.RowID AS FinRecordID,
	|	CASE
	|		WHEN TableOfDebits.ThisChangeIsOnlyDiscountPercentage
	|			THEN VALUE(Catalog.BusinessTransactionsSettings.AccrualOfInterestOnDiscounting)
	|		ELSE VALUE(Catalog.BusinessTransactionsSettings.FutureExpenseCommitmentsWriteOff)
	|	END AS BusinessTransactionSetting
	|	
	|FROM
	|	TTWriteOff AS TableOfDebits
	|		LEFT JOIN TTDataOfFixedAssets AS TTDataOfFixedAssets
	|		ON TableOfDebits.DimensionOfExpenses = TTDataOfFixedAssets.FixedAsset
	|		AND TableOfDebits.RowID = TTDataOfFixedAssets.RowID
	|		LEFT JOIN TTCostOfFixedAssets AS TTCostOfFixedAssets
	|		ON TableOfDebits.DimensionOfExpenses = TTCostOfFixedAssets.FixedAsset
	|		AND TableOfDebits.RowID = TTCostOfFixedAssets.RowID
	|WHERE
	|	&TheseAreReservesOfLiquidationObligations
	|	AND (TTDataOfFixedAssets.TakenIntoAccountByMan AND TableOfDebits.SumMan - TTCostOfFixedAssets.BalanceOfNetInitialCostCo >= 0.01 
	|	OR TTDataOfFixedAssets.LocalRegistrationHasBeenAccepted AND TableOfDebits.SumCompl - TTCostOfFixedAssets.BalanceOfCostLocal >= 0.01)
	|
	|GROUP BY
	|	TableOfDebits.IncomeItem,
	|	TableOfDebits.DimensionOfRevenue,
	|	TableOfDebits.Department,
	|	TableOfDebits.LineOfBusinessExpenses,
	|	CASE
	|		WHEN TableOfDebits.ThisChangeIsOnlyDiscountPercentage
	|			THEN VALUE(Enum.BusinessTransactions.AccrualOfInterestOnDiscounting)
	|		ELSE VALUE(Enum.BusinessTransactions.FutureExpenseCommitmentsWriteOff)
	|	END,
	|	CASE
	|		WHEN TableOfDebits.ThisChangeIsOnlyDiscountPercentage
	|			THEN VALUE(Catalog.BusinessTransactionsSettings.AccrualOfInterestOnDiscounting)
	|		ELSE VALUE(Catalog.BusinessTransactionsSettings.FutureExpenseCommitmentsWriteOff)
	|	END,
	|	TableOfDebits.RowID
	|";
	
	QueryTexts.Add(QueryText, RegisterName);
	
EndProcedure

Procedure QueryTextFACost(Query, QueryTexts, Registers)
	
	RegisterName = "FACost";
	
	If Not DocumentsPosting.RequiresTableForRegisteredRecords(RegisterName, Registers) Then
		Return;
	EndIf;
	
	If Not DocumentsPosting.ThereIsQueryTable("TTAccruals", QueryTexts) Then
		QueryTextTableTTAccruals(Query, QueryTexts);
	EndIf;
	
	If Not DocumentsPosting.ThereIsQueryTable("TTWriteOff", QueryTexts) Then
		QueryTextTableTTWriteOff(Query, QueryTexts);
	EndIf;
	
	QueryTextTableTTDataOfFixedAssets(Query, QueryTexts);
	QueryTextTableTTCostOfFixedAssets(Query, QueryTexts);
	
	QueryText =
	"SELECT
	|	VALUE(AccumulationRecordType.Receipt) AS RecordType,
	|	&BeginOfPeriod AS Period,
	|	&Organization AS Organization,
	|	AccrualTable.DimensionOfExpenses AS FixedAsset,
	|	TTDataOfFixedAssets.Department AS Department,
	|	TTDataOfFixedAssets.FinancialAccountingGroup AS FinancialAccountingGroup,
	|	TTDataOfFixedAssets.LineOfBusiness AS LineOfBusiness,
	|	TTDataOfFixedAssets.Leaseholder AS Leaseholder,
	|
	|	CASE
	|		WHEN AccrualTable.ThisChangeIsOnlyDiscountPercentage
	|			THEN VALUE(Enum.BusinessTransactions.DiscountingInterestWriteOff)
	|		ELSE VALUE(Enum.BusinessTransactions.FutureExpenseCommitmentsAccrual)
	|	END AS BusinessOperation,
	|
	|	TTDataOfFixedAssets.LocalRegistrationHasBeenAccepted AS RecordInLocalAccounting,
	|	TTDataOfFixedAssets.TakenIntoAccountByMan AS RecordInManAccounting,
	|	TTDataOfFixedAssets.VATTaxation AS VATTaxation,
	|	AccrualTable.Department AS DebitBusinessUnit,
	|	TTDataOfFixedAssets.LineOfBusiness AS CorLineOfBusiness,
	|	TTDataOfFixedAssets.FinancialAccountingGroup AS CorFinancialAccountingGroup,
	|
	|	CASE
	|		WHEN TTDataOfFixedAssets.TakenIntoAccountByMan
	|			THEN AccrualTable.SumMan
	|		ELSE 0
	|	END AS Cost,
	|
	|	CASE
	|		WHEN TTDataOfFixedAssets.LocalRegistrationHasBeenAccepted
	|			THEN AccrualTable.SumCompl
	|		ELSE 0
	|	END AS LocalCost,
	|
	|	CASE
	|		WHEN TTDataOfFixedAssets.LocalRegistrationHasBeenAccepted
	|			THEN AccrualTable.SumCompl
	|		ELSE 0
	|	END AS CostTemporaryDifference,
	|
	|	AccrualTable.RowID AS FinRecordID,
	|
	|	CASE
	|		WHEN AccrualTable.ThisChangeIsOnlyDiscountPercentage
	|			THEN VALUE(Catalog.BusinessTransactionsSettings.DiscountingInterestWriteOff)
	|		ELSE VALUE(Catalog.BusinessTransactionsSettings.FutureExpenseCommitmentsAccrual)
	|	END AS BusinessTransactionSetting
	|
	|FROM
	|	TTAccruals AS AccrualTable
	|
	|		INNER JOIN TTDataOfFixedAssets AS TTDataOfFixedAssets
	|		ON AccrualTable.DimensionOfExpenses = TTDataOfFixedAssets.FixedAsset
	|			AND AccrualTable.RowID = TTDataOfFixedAssets.RowID
	|
	|WHERE
	|	&TheseAreReservesOfLiquidationObligations
	|	AND (TTDataOfFixedAssets.TakenIntoAccountByMan
	|			AND AccrualTable.SumMan <> 0
	|		OR TTDataOfFixedAssets.LocalRegistrationHasBeenAccepted
	|			AND AccrualTable.SumCompl <> 0)
	|
	|UNION ALL
	|
	|SELECT
	|	VALUE(AccumulationRecordType.Receipt) AS RecordType,
	|	&BeginOfPeriod AS Period,
	|	&Organization AS Organization,
	|	TableOfDebits.DimensionOfExpenses AS FixedAsset,
	|	TTDataOfFixedAssets.Department AS Department,
	|	TTDataOfFixedAssets.FinancialAccountingGroup AS FinancialAccountingGroup,
	|	TTDataOfFixedAssets.LineOfBusiness AS LineOfBusiness,
	|	TTDataOfFixedAssets.Leaseholder AS Leaseholder,
	|
	|	CASE
	|		WHEN TableOfDebits.ThisChangeIsOnlyDiscountPercentage
	|			THEN VALUE(Enum.BusinessTransactions.AccrualOfInterestOnDiscounting)
	|		ELSE VALUE(Enum.BusinessTransactions.FutureExpenseCommitmentsWriteOff)
	|	END AS BusinessOperation,
	|
	|	TTDataOfFixedAssets.LocalRegistrationHasBeenAccepted AS RecordInLocalAccounting,
	|	TTDataOfFixedAssets.TakenIntoAccountByMan AS RecordInManAccounting,
	|	TTDataOfFixedAssets.VATTaxation AS VATTaxation,
	|	TableOfDebits.Department AS DebitBusinessUnit,
	|	TTDataOfFixedAssets.LineOfBusiness AS CorLineOfBusiness,
	|	TTDataOfFixedAssets.FinancialAccountingGroup AS CorFinancialAccountingGroup,
	|
	|	CASE
	|		WHEN TTDataOfFixedAssets.TakenIntoAccountByMan 
	|				AND TTCostOfFixedAssets.BalanceOfNetInitialCostCo < 0
	|			THEN 0
	|		WHEN TTDataOfFixedAssets.TakenIntoAccountByMan 
	|				AND TTCostOfFixedAssets.BalanceOfNetInitialCostCo >= TableOfDebits.SumMan
	|			THEN -TableOfDebits.SumMan
	|		WHEN TTDataOfFixedAssets.TakenIntoAccountByMan 
	|				AND TTCostOfFixedAssets.BalanceOfNetInitialCostCo < TableOfDebits.SumMan
	|			THEN -TTCostOfFixedAssets.BalanceOfNetInitialCostCo
	|		ELSE 0
	|	END AS Cost,
	|
	|	CASE
	|		WHEN TTDataOfFixedAssets.LocalRegistrationHasBeenAccepted
	|				AND TTCostOfFixedAssets.BalanceOfCostLocal < 0
	|			THEN 0
	|		WHEN TTDataOfFixedAssets.LocalRegistrationHasBeenAccepted
	|				AND TTCostOfFixedAssets.BalanceOfCostLocal >= TableOfDebits.SumCompl
	|			THEN -TableOfDebits.SumCompl
	|		WHEN TTDataOfFixedAssets.LocalRegistrationHasBeenAccepted
	|				AND TTCostOfFixedAssets.BalanceOfCostLocal < TableOfDebits.SumCompl
	|			THEN -TTCostOfFixedAssets.BalanceOfCostLocal
	|		ELSE 0
	|	END AS LocalCost,
	|
	|	CASE
	|		WHEN TTDataOfFixedAssets.LocalRegistrationHasBeenAccepted
	|				AND TTCostOfFixedAssets.BalanceOfCostLocal < 0
	|			THEN 0
	|		WHEN TTDataOfFixedAssets.LocalRegistrationHasBeenAccepted
	|				AND TTCostOfFixedAssets.BalanceOfCostLocal >= TableOfDebits.SumCompl
	|			THEN -TableOfDebits.SumCompl
	|		WHEN TTDataOfFixedAssets.LocalRegistrationHasBeenAccepted
	|				AND TTCostOfFixedAssets.BalanceOfCostLocal < TableOfDebits.SumCompl
	|			THEN -TTCostOfFixedAssets.BalanceOfCostLocal
	|		ELSE 0
	|	END AS CostTemporaryDifference,
	|
	|	TableOfDebits.RowID AS FinRecordID,
	|
	|	CASE
	|		WHEN TableOfDebits.ThisChangeIsOnlyDiscountPercentage
	|			THEN VALUE(Catalog.BusinessTransactionsSettings.AccrualOfInterestOnDiscounting)
	|		ELSE VALUE(Catalog.BusinessTransactionsSettings.FutureExpenseCommitmentsWriteOff)
	|	END AS BusinessTransactionSetting
	|
	|FROM
	|	TTWriteOff AS TableOfDebits
	|
	|		INNER JOIN TTDataOfFixedAssets AS TTDataOfFixedAssets
	|		ON TableOfDebits.DimensionOfExpenses = TTDataOfFixedAssets.FixedAsset
	|			AND TableOfDebits.RowID = TTDataOfFixedAssets.RowID
	|		
	|		LEFT JOIN TTCostOfFixedAssets AS TTCostOfFixedAssets
	|		ON TableOfDebits.DimensionOfExpenses = TTCostOfFixedAssets.FixedAsset
	|			AND TableOfDebits.RowID = TTCostOfFixedAssets.RowID
	|
	|WHERE
	|	&TheseAreReservesOfLiquidationObligations
	|	AND (TTDataOfFixedAssets.TakenIntoAccountByMan
	|		OR TTDataOfFixedAssets.LocalRegistrationHasBeenAccepted)
	|";
	
	QueryTexts.Add(QueryText, RegisterName);
	
EndProcedure

Procedure QueryTextFutureExpenseCommitments(Query, QueryTexts, Registers)
	
	RegisterName = "FutureExpenseCommitments";
	
	If Not DocumentsPosting.RequiresTableForRegisteredRecords(RegisterName, Registers) Then
		Return;
	EndIf;
	
	If Not DocumentsPosting.ThereIsQueryTable("TTAccruals", QueryTexts) Then
		QueryTextTableTTAccruals(Query, QueryTexts);
	EndIf;
	
	If Not DocumentsPosting.ThereIsQueryTable("TTWriteOff", QueryTexts) Then
		QueryTextTableTTWriteOff(Query, QueryTexts);
	EndIf;
	
	QueryTextTableTTRegisteredRecordsOfDiscounting(Query, QueryTexts);
	
	QueryText =
	"SELECT
	|	CASE
	|		WHEN &DiscountingOfEstimatedObligation OR &TheseAreReservesOfLiquidationObligations
	|			THEN &BeginOfPeriod
	|		ELSE &Period
	|	END AS Period,
	|	VALUE(AccumulationRecordType.Expense) AS RecordType,
	|	&Organization AS Organization,
	|	&ReserveKind AS ReserveKind,
	|	AccrualTable.LineOfBusiness AS LineOfBusiness,
	|	AccrualTable.ProvisionObject AS ProvisionObject,
	|	SUM(AccrualTable.SumCompl) AS SumCompl,
	|	SUM(AccrualTable.AmountFA) AS AmountFA,
	|	SUM(AccrualTable.SumMan) AS SumMan,
	|	0 AS DiscountingAmountCompl,
	|	0 AS DiscountingAmountMan,
	|	CASE
	|		WHEN AccrualTable.ThisChangeIsOnlyDiscountPercentage
	|			THEN VALUE(Enum.BusinessTransactions.DiscountingInterestWriteOff)
	|		ELSE VALUE(Enum.BusinessTransactions.FutureExpenseCommitmentsAccrual)
	|	END AS BusinessOperation,
	|	
	|	AccrualTable.RowID AS FinRecordID,
	|	CASE
	|		WHEN AccrualTable.ThisChangeIsOnlyDiscountPercentage
	|			THEN VALUE(Catalog.BusinessTransactionsSettings.DiscountingInterestWriteOff)
	|		ELSE VALUE(Catalog.BusinessTransactionsSettings.FutureExpenseCommitmentsAccrual)
	|	END AS BusinessTransactionSetting
	|	
	|FROM
	|	TTAccruals AS AccrualTable
	|
	|GROUP BY
	|	AccrualTable.ProvisionObject,
	|	AccrualTable.LineOfBusiness,
	|	CASE
	|		WHEN AccrualTable.ThisChangeIsOnlyDiscountPercentage
	|			THEN VALUE(Enum.BusinessTransactions.DiscountingInterestWriteOff)
	|		ELSE VALUE(Enum.BusinessTransactions.FutureExpenseCommitmentsAccrual)
	|	END,
	|	AccrualTable.RowID,
	|	CASE
	|		WHEN AccrualTable.ThisChangeIsOnlyDiscountPercentage
	|			THEN VALUE(Catalog.BusinessTransactionsSettings.DiscountingInterestWriteOff)
	|		ELSE VALUE(Catalog.BusinessTransactionsSettings.FutureExpenseCommitmentsAccrual)
	|	END
	|
	|UNION ALL
	|
	|SELECT
	|	CASE
	|		WHEN &DiscountingOfEstimatedObligation OR &TheseAreReservesOfLiquidationObligations
	|			THEN &BeginOfPeriod
	|		ELSE &Period
	|	END,
	|	VALUE(AccumulationRecordType.Receipt),
	|	&Organization,
	|	&ReserveKind,
	|	TableOfDebits.LineOfBusiness,
	|	TableOfDebits.ProvisionObject,
	|	SUM(TableOfDebits.SumCompl),
	|	SUM(TableOfDebits.AmountFA),
	|	SUM(TableOfDebits.SumMan),
	|	0 AS DiscountingAmountCompl,
	|	0 AS DiscountingAmountMan,
	|	CASE
	|		WHEN TableOfDebits.ThisChangeIsOnlyDiscountPercentage
	|			THEN VALUE(Enum.BusinessTransactions.AccrualOfInterestOnDiscounting)
	|		ELSE VALUE(Enum.BusinessTransactions.FutureExpenseCommitmentsWriteOff)
	|	END,
	|	
	|	TableOfDebits.RowID AS FinRecordID,
	|	CASE
	|		WHEN TableOfDebits.ThisChangeIsOnlyDiscountPercentage
	|			THEN VALUE(Catalog.BusinessTransactionsSettings.AccrualOfInterestOnDiscounting)
	|		ELSE VALUE(Catalog.BusinessTransactionsSettings.FutureExpenseCommitmentsWriteOff)
	|	END AS BusinessTransactionSetting
	|	
	|FROM
	|	TTWriteOff AS TableOfDebits
	|
	|GROUP BY
	|	TableOfDebits.ProvisionObject,
	|	TableOfDebits.LineOfBusiness,
	|	CASE
	|		WHEN TableOfDebits.ThisChangeIsOnlyDiscountPercentage
	|			THEN VALUE(Enum.BusinessTransactions.AccrualOfInterestOnDiscounting)
	|		ELSE VALUE(Enum.BusinessTransactions.FutureExpenseCommitmentsWriteOff)
	|	END,
	|	TableOfDebits.RowID,
	|	CASE
	|		WHEN TableOfDebits.ThisChangeIsOnlyDiscountPercentage
	|			THEN VALUE(Catalog.BusinessTransactionsSettings.AccrualOfInterestOnDiscounting)
	|		ELSE VALUE(Catalog.BusinessTransactionsSettings.FutureExpenseCommitmentsWriteOff)
	|	END
	|
	|UNION ALL
	|
	|SELECT
	|	CASE
	|		WHEN &DiscountingOfEstimatedObligation OR &TheseAreReservesOfLiquidationObligations
	|			THEN &BeginOfPeriod
	|		ELSE &Period
	|	END AS Period,
	|	VALUE(AccumulationRecordType.Receipt) AS RecordType,
	|	&Organization AS Organization,
	|	&ReserveKind AS ReserveKind,
	|	DataTable.LineOfBusiness AS LineOfBusiness,
	|	DataTable.ProvisionObject AS ProvisionObject,
	|	0 AS SumCompl,
	|	0 AS AmountFA,
	|	0 AS SumMan,
	|	CASE
	|		WHEN DataTable.TypeOfRegisteredRecordedLocal = VALUE(AccumulationRecordType.Receipt)
	|			THEN DataTable.DiscountingAmountCompl
	|		ELSE 0
	|	END AS DiscountingAmountCompl,
	|	CASE
	|		WHEN DataTable.TypeOfManSRegisteredRecords = VALUE(AccumulationRecordType.Receipt)
	|			THEN DataTable.DiscountingAmountMan
	|		ELSE 0
	|	END AS DiscountingAmountMan,
	|	VALUE(Enum.BusinessTransactions.AccrualOfInterestOnDiscounting) AS BusinessOperation,
	|	
	|	DataTable.RowID AS FinRecordID,
	|	VALUE(Catalog.BusinessTransactionsSettings.AccrualOfInterestOnDiscounting) AS BusinessTransactionSetting
	|	
	|FROM
	|	TTRegisteredRecordsOfDiscounting AS DataTable
	|WHERE
	|	&DiscountingOfEstimatedObligation
	|	AND (DataTable.TypeOfRegisteredRecordedLocal = VALUE(AccumulationRecordType.Receipt)
	|			OR DataTable.TypeOfManSRegisteredRecords = VALUE(AccumulationRecordType.Receipt))
	|
	|UNION ALL
	|
	|SELECT
	|	CASE
	|		WHEN &DiscountingOfEstimatedObligation OR &TheseAreReservesOfLiquidationObligations
	|			THEN &BeginOfPeriod
	|		ELSE &Period
	|	END AS Period,
	|	VALUE(AccumulationRecordType.Expense) AS RecordType,
	|	&Organization AS Organization,
	|	&ReserveKind AS ReserveKind,
	|	DataTable.LineOfBusiness AS LineOfBusiness,
	|	DataTable.ProvisionObject AS ProvisionObject,
	|	CASE
	|		WHEN DataTable.TypeOfRegisteredRecordedLocal = VALUE(AccumulationRecordType.Receipt)
	|			THEN DataTable.DiscountingAmountCompl
	|		ELSE 0
	|	END AS SumCompl,
	|	0 AS AmountFA,
	|	CASE
	|		WHEN DataTable.TypeOfManSRegisteredRecords = VALUE(AccumulationRecordType.Receipt)
	|			THEN DataTable.DiscountingAmountMan
	|		ELSE 0
	|	END AS SumMan,
	|	0 AS DiscountingAmountCompl,
	|	0 AS DiscountingAmountMan,
	|	VALUE(Enum.BusinessTransactions.AccrualOfInterestOnDiscounting) AS BusinessOperation,
	|	
	|	DataTable.RowID AS FinRecordID,
	|	VALUE(Catalog.BusinessTransactionsSettings.AccrualOfInterestOnDiscounting) AS BusinessTransactionSetting
	|	
	|FROM
	|	TTRegisteredRecordsOfDiscounting AS DataTable
	|WHERE
	|	&DiscountingOfEstimatedObligation
	|	AND (DataTable.TypeOfRegisteredRecordedLocal = VALUE(AccumulationRecordType.Receipt)
	|			OR DataTable.TypeOfManSRegisteredRecords = VALUE(AccumulationRecordType.Receipt))
	|
	|UNION ALL
	|
	|SELECT
	|	CASE
	|		WHEN &DiscountingOfEstimatedObligation OR &TheseAreReservesOfLiquidationObligations
	|			THEN &BeginOfPeriod
	|		ELSE &Period
	|	END AS Period,
	|	VALUE(AccumulationRecordType.Expense) AS RecordType,
	|	&Organization AS Organization,
	|	&ReserveKind AS ReserveKind,
	|	DataTable.LineOfBusiness AS LineOfBusiness,
	|	DataTable.ProvisionObject AS ProvisionObject,
	|	0 AS SumCompl,
	|	0 AS AmountFA,
	|	0 AS SumMan,
	|	CASE
	|		WHEN DataTable.TypeOfRegisteredRecordedLocal = VALUE(AccumulationRecordType.Expense)
	|			THEN DataTable.DiscountingAmountCompl
	|		ELSE 0
	|	END AS DiscountingAmountCompl,
	|	CASE
	|		WHEN DataTable.TypeOfManSRegisteredRecords = VALUE(AccumulationRecordType.Expense)
	|			THEN DataTable.DiscountingAmountMan
	|		ELSE 0
	|	END AS DiscountingAmountMan,
	|	VALUE(Enum.BusinessTransactions.DiscountingInterestWriteOff) AS BusinessOperation,
	|	
	|	DataTable.RowID AS FinRecordID,
	|	VALUE(Catalog.BusinessTransactionsSettings.DiscountingInterestWriteOff) AS BusinessTransactionSetting
	|	
	|FROM
	|	TTRegisteredRecordsOfDiscounting AS DataTable
	|WHERE
	|	&DiscountingOfEstimatedObligation
	|	AND (DataTable.TypeOfRegisteredRecordedLocal = VALUE(AccumulationRecordType.Expense)
	|			OR DataTable.TypeOfManSRegisteredRecords = VALUE(AccumulationRecordType.Expense))
	|
	|UNION ALL
	|
	|SELECT
	|	CASE
	|		WHEN &DiscountingOfEstimatedObligation OR &TheseAreReservesOfLiquidationObligations
	|			THEN &BeginOfPeriod
	|		ELSE &Period
	|	END AS Period,
	|	VALUE(AccumulationRecordType.Receipt) AS RecordType,
	|	&Organization AS Organization,
	|	&ReserveKind AS ReserveKind,
	|	DataTable.LineOfBusiness AS LineOfBusiness,
	|	DataTable.ProvisionObject AS ProvisionObject,
	|	CASE
	|		WHEN DataTable.TypeOfRegisteredRecordedLocal = VALUE(AccumulationRecordType.Expense)
	|			THEN DataTable.DiscountingAmountCompl
	|		ELSE 0
	|	END AS SumCompl,
	|	0 AS AmountFA,
	|	CASE
	|		WHEN DataTable.TypeOfManSRegisteredRecords = VALUE(AccumulationRecordType.Expense)
	|			THEN DataTable.DiscountingAmountMan
	|		ELSE 0
	|	END AS SumMan,
	|	0 AS DiscountingAmountCompl,
	|	0 AS DiscountingAmountMan,
	|	VALUE(Enum.BusinessTransactions.DiscountingInterestWriteOff) AS BusinessOperation,
	|	
	|	DataTable.RowID AS FinRecordID,
	|	VALUE(Catalog.BusinessTransactionsSettings.DiscountingInterestWriteOff) AS BusinessTransactionSetting
	|	
	|FROM
	|	TTRegisteredRecordsOfDiscounting AS DataTable
	|WHERE
	|	&DiscountingOfEstimatedObligation
	|	AND (DataTable.TypeOfRegisteredRecordedLocal = VALUE(AccumulationRecordType.Expense)
	|			OR DataTable.TypeOfManSRegisteredRecords = VALUE(AccumulationRecordType.Expense))
	|";
	
	QueryTexts.Add(QueryText, RegisterName);
	
EndProcedure

Procedure QueryTextProvisionDiscountingRates(Query, QueryTexts, Registers)
	
	RegisterName = "ProvisionDiscountingRates";
	
	If Not DocumentsPosting.RequiresTableForRegisteredRecords(RegisterName, Registers) Then
		Return;
	EndIf;
	
	QueryText =
	"SELECT
	|	DocumentData.Date AS Period,
	|	DocumentData.Organization AS Organization,
	|	DocumentData.ReserveKind AS ReserveKind,
	|	DocumentData.DiscountRate AS DiscountRate
	|FROM
	|	Document.FutureExpenseCommitmentsAccrualWriteOff AS DocumentData
	|		LEFT JOIN InformationRegister.ProvisionDiscountingRates.SliceLast(&BeginOfPeriod,
	|			Organization = &Organization
	|		AND ReserveKind = &ReserveKind
	|		AND Recorder <> &Ref) AS ProvisionDiscountingRates
	|		ON DocumentData.Organization = ProvisionDiscountingRates.Organization
	|		AND DocumentData.ReserveKind = ProvisionDiscountingRates.ReserveKind
	|WHERE
	|	&DiscountingOfEstimatedObligation
	|	AND DocumentData.Ref = &Ref
	|	AND &DiscountRate <> 0
	|	AND ISNULL(ProvisionDiscountingRates.DiscountRate, 0) <> &DiscountRate";
	
	QueryTexts.Add(QueryText, RegisterName);
	
EndProcedure

Procedure QueryTextPeriodOfDiscountingOfProvisionsAndContingentLiabilities(Query, QueryTexts, Registers)
	
	RegisterName = "PeriodOfDiscountingOfProvisionsAndContingentLiabilities";
	
	If Not DocumentsPosting.RequiresTableForRegisteredRecords(RegisterName, Registers) Then
		Return;
	EndIf;
	
	QueryText =
	"SELECT
	|	&Period AS Period,
	|	Rows.ProvisionObject AS ProvisionObject,
	|	CASE
	|		WHEN Rows.SetNewExecutionDate
	|			THEN Rows.NewExecutionDate
	|		ELSE Rows.CompletionDate
	|	END AS CompletionDate
	|FROM
	|	Document.FutureExpenseCommitmentsAccrualWriteOff.Reserves AS Rows
	|		LEFT JOIN InformationRegister.PeriodOfDiscountingOfProvisionsAndContingentLiabilities.SliceLast(&Period,
	|			Recorder <> &Ref) AS TermsOfDiscounting
	|		ON Rows.ProvisionObject = TermsOfDiscounting.ProvisionObject
	|WHERE
	|	&DiscountingOfEstimatedObligation
	|	AND Rows.Ref = &Ref
	|	AND (TermsOfDiscounting.CompletionDate IS NULL
	|	OR Rows.SetNewExecutionDate)";
	
	QueryTexts.Add(QueryText, RegisterName);
	
EndProcedure

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

Function QueryTextTableFixedAssetsDocuments(Query, QueryTexts, Registers)
	
	RegisterName = "FixedAssetsDocuments";
	
	If Not DocumentsPosting.RequiresTableForRegisteredRecords(RegisterName, Registers) Then
		Return "";
	EndIf;
	
	QueryText = 
	"SELECT
	|	ISNULL(FATable.LineNumber-1, 0) AS RecNo,
	|	&Ref                   AS Ref,
	|	&Period                   AS Date,
	|	&Organization              AS Organization,
	|	&MetadataIdentifier  AS RefType,
	|	&HouseholdOperationForRegistry    AS BusinessOperation,
	|	&Posted                 AS Posted,
	|	TRUE                    AS RecordInLocalAccounting,
	|	TRUE                    AS RecordInManAccounting,
	|	FATable.ExpensesDimensionAccruals AS FixedAsset
	|
	|FROM
	|	Document.FutureExpenseCommitmentsAccrualWriteOff.Reserves AS FATable
	|
	|		LEFT JOIN Document.FutureExpenseCommitmentsAccrualWriteOff.Reserves AS DoublesTable
	|		ON DoublesTable.Ref = FATable.Ref
	|			AND DoublesTable.ExpensesDimensionAccruals = FATable.ExpensesDimensionAccruals
	|			AND DoublesTable.LineNumber < FATable.LineNumber
	|
	|WHERE
	|	FATable.Ref = &Ref
	|	AND &TheseAreReservesOfLiquidationObligations
	|	AND DoublesTable.Ref IS NULL
	|	AND FATable.ExpensesDimensionAccruals <> UNDEFINED
	|	AND (FATable.ExpensesDimensionAccruals REFS Catalog.Assets
	|			AND FATable.ExpensesDimensionAccruals <> VALUE(Catalog.Assets.EmptyRef))
	|";
	QueryTexts.Add(QueryText, RegisterName);
	
	Return QueryText;
	
EndFunction

// Result of adapting the request for the update informationbase function.Registratorsreferences.
// 
// Parameters:
//  RegisterName - String - Register name
// 
// Returns:
//  Structure - Fields:
//	 * QueryText - String - must be declared necessarily, adapted from the text of the query
//	 * ParameterValues - Structure - values of query parameters that are calculated from constants
//										(do not depend on a specific document).
//
Function AdaptedCaseSensitiveQueryText(RegisterName) Export
	
	Query = New Query;
	QueryTexts = New ValueList;
	
	FullDocumentName = "Document.FutureExpenseCommitmentsAccrualWriteOff";
	ParameterValues = New Structure;
	ParameterValues.Insert("MetadataIdentifier", Common.MetadataObjectID("Document.FutureExpenseCommitmentsAccrualWriteOff"));
	ParameterValues.Insert("HouseholdOperationForRegistry", Enums.BusinessTransactions.FutureExpenseCommitmentsAccrualWriteOff);
	
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

Function QueryTextTableDocumentPostingInFinancialAccounting(QueryTexts, Registers = Undefined)
	
	RegisterName = "DocumentPostingInFinancialAccounting";
	
	If Not DocumentsPosting.RequiresTableForRegisteredRecords(RegisterName, Registers) Then
		Return "";
	EndIf;
	
	QueryText =
	"SELECT
	|	&Period AS Period,
	|	&Ref AS Document,
	|	FinancialAccountingChartsOfAccountsForCompanies.Organization AS Organization,
	|	CASE
	|		WHEN &DiscountingOfEstimatedObligation
	|				OR &TheseAreReservesOfLiquidationObligations
	|			THEN BEGINOFPERIOD(&BeginOfPeriod, DAY)
	|		ELSE BEGINOFPERIOD(&Period, DAY)
	|	END AS DateRecord,
	|	VALUE(Enum.StatusesOfPostingsInFinancialAccounting.ForPostingInAccounting) AS Status,
	|	FinancialAccountingChartsOfAccountsForCompanies.ChartOfAccounts AS ChartOfAccounts,
	|	FinancialAccountingChartsOfAccountsForCompanies.PostingGenerationSetting AS PostingGenerationSetting
	|FROM
	|	InformationRegister.FinancialAccountingChartsOfAccountsForCompanies.SliceLast(&Period, Organization = &Organization) AS FinancialAccountingChartsOfAccountsForCompanies";
	
	QueryTexts.Add(QueryText, RegisterName);
	Return QueryText;
	
EndFunction

#EndRegion

#Region PostingsOfReglAccounting

// The function returns the request text to reflect the document in regulated accounting.
//
// Returns:
//	String - Query text
//
Function TextOfReflectionInLocalAccounting() Export

	Return FutureExpenseCommitmentsAccrualWriteOffLocalization.TextOfReflectionInLocalAccounting();

EndFunction

// The function returns the request text for additional temporary tables
// that are required for reflection in regulated accounting.
//
// Returns:
//   String - the generated request text.
//
Function RequestTextTTReflectedInLocalAccounting() Export

	Return FutureExpenseCommitmentsAccrualWriteOffLocalization.RequestTextTTReflectedInLocalAccounting();

EndFunction

#EndRegion

#Region Other

#Region LoadingFromFile

////////////////////////////////////////////////////////////////////////////////
// Interface for working with the File Upload subsystem.

// Sets the download parameters.
//
Procedure SetDownloadParametersFromVHFFile(Parameters) Export
	Return;
EndProcedure

// Compares the data loaded in the table part of the full table part
// With the data in the IB, and fills in the parameters of the addressable Comparison and the list of one-Values.
// 
// Parameters:
// 	AddressOfUploadedData    - String - the address of the temporary storage with the table of values in which
//                                        the downloaded data from the file is located. Composition of columns:
//     ID - Number - the sequence number of the line.
//     The remaining columns correspond to the columns of the File Upload Template.
// 	AddressOfMappingTable - String - the address of the temporary storage with an empty table of values,
//                                        which is a copy of the table part of the document
//                                        that needs to be filled in from the addressable Data table.
// 	ConflictsList    - ValueTable - a list of ambiguous values for which there are several in the information security:
// 		* Id - Number - the ordinal number of the line.
// 		The rest of the column.
// 	FullTabularSectionName   - String -
// 	AdditionalParameters   - Structure - 
Procedure MapDataToImport(AddressOfUploadedData, AddressOfMappingTable, ConflictsList, FullTabularSectionName, AdditionalParameters) Export
	
	Reserves =  ReadTableForDownload(AddressOfMappingTable);
	DataToImport = ReadTableForDownload(AddressOfUploadedData);
	
	Query = New Query;
	Query.Text = 
	"SELECT
	|	CAST(DataForComparison.ProvisionObject AS STRING(&NameLength_)) AS Description,
	|	DataForComparison.Id AS Id
	|INTO DataForComparison
	|FROM
	|	&DataForComparison AS DataForComparison
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	MAX(MappingCatalog_.Ref) AS ProvisionObject,
	|	DataForMatchingByName.Id,
	|	COUNT(DataForMatchingByName.Id) AS Count
	|FROM
	|	DataForComparison AS DataForMatchingByName
	|		LEFT JOIN Catalog.AccountingObjectsOfFutureExpenseCommitments AS MappingCatalog_
	|		ON (MappingCatalog_.Description = DataForMatchingByName.Description)
	|			AND NOT MappingCatalog_.IsFolder
	|WHERE
	|	NOT MappingCatalog_.Ref IS NULL
	|
	|GROUP BY
	|	DataForMatchingByName.Id";
	
	NameLength_ = Metadata.Catalogs.AccountingObjectsOfFutureExpenseCommitments.DescriptionLength;
	
	Query.Text = StrReplace(Query.Text, "&NameLength_", NameLength_); 
	
	Query.SetParameter("DataForComparison", DataToImport);
	
	QueryResult = Query.Execute();
	
	ResultTable2 = QueryResult.Unload();
	
	For Each TableRow In DataToImport Do 
		
		NewRow = Reserves.Add();
		NewRow.Id = TableRow.Id;
		
		ResultString1 = ResultTable2.Find(TableRow.Id, "Id");
		If ResultString1 <> Undefined Then 
			If ResultString1.Count = 1 Then 
				NewRow.ProvisionObject  = ResultString1.ProvisionObject;
				FillPropertyValues(NewRow, TableRow,, "Id,ProvisionObject");
			ElsIf ResultString1.Count > 1 Then 
				WritingAboutAmbiguity = ConflictsList.Add();
				WritingAboutAmbiguity.Id = TableRow.Id; 
				WritingAboutAmbiguity.Column = "ProvisionObject";
			EndIf;
		EndIf;
		
	EndDo;
	
	PutToTempStorage(Reserves, AddressOfMappingTable);
	
EndProcedure

// LongDesc
// 
// Parameters:
// 	FullTabularSectionName - String - full name of the table part where data is loaded.
// 	ConflictsList - Array, ValueTable - A list to fill in with ambiguous data. Columns:
//     * Id        - Number  - Unique ID of the string.
//     * Column              - String -  Name of the column with the resulting ambiguity.
// 	ColumnName - String - Name of the column where the ambiguity occurred.
// 	LoadedValuesString - String - Loaded data based on which the ambiguity occurred.
// 	AdditionalParameters - Structure -
Procedure FillInListOfAmbiguities(FullTabularSectionName, ConflictsList, ColumnName, LoadedValuesString, AdditionalParameters) Export
	
	If ColumnName = "ProvisionObject" Then

		Query = New Query;
		Query.Text = 
		"SELECT
		|	ProvisionObjects.Ref
		|FROM
		|	Catalog.AccountingObjectsOfFutureExpenseCommitments AS ProvisionObjects
		|WHERE
		|	ProvisionObjects.Description = &Description";
		Query.SetParameter("Description", LoadedValuesString.ProvisionObject);
		QueryResult = Query.Execute();
		SelectionDetailRecords = QueryResult.Select();
		While SelectionDetailRecords.Next() Do
			ConflictsList.Add(SelectionDetailRecords.Ref);
		EndDo;
	EndIf;
	
EndProcedure

// Returns a table passed through temporary storage
// 
// Parameters:
// 	TempStorageAddress - String - address of the storage where the table is located
// Returns:
// 	ValueTable - table with columns:
// 		* Id - Number - serial number.
// 		The rest of the column.
Function ReadTableForDownload(TempStorageAddress)
	Return GetFromTempStorage(TempStorageAddress); // ValueTable
EndFunction

#EndRegion

#EndRegion

#EndRegion

#EndIf
