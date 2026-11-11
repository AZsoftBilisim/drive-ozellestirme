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
	DocumentMechanisms.Add("CostAndBatchAccounting");
	DocumentMechanisms.Add("AccountingOfIncomeExpenses");
	DocumentMechanisms.Add("AccountingForOtherAssetsLiabilities");
	DocumentMechanisms.Add("DocumentsRegistry");
	
	DeferredExpensesAllocationLocalization.RegisterAccountingMechanisms(DocumentMechanisms);
	
EndProcedure

// Returns tables for movements that are necessary for conducting a document through registers of accounting mechanisms.
//
// Parameters:
//  Document - DocumentRef, DocumentObject - link to the document or object for which you want to get data
//  Registers - Structure - a list of register names for which you want to table
//  AddlParameters - Structure - additional parameters for getting data that define the context of the event.
//
// Returns:
//  Structure - collection of elements:
//     * RegisterNameTable - ValueTable - table of data to be reflected in the register.
//
Function DocumentDataForPosting(Document, Registers, AddlParameters = Undefined) Export
	
	If AddlParameters = Undefined Then
		AddlParameters = DocumentsPosting.AdditionalParametersDocumentDataForPosting();
	EndIf;
	
	If TypeOf(Document) = Type("DocumentObject.DeferredExpensesAllocation") Then
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
		
		QueryTextTableOtherExpenses(Query, QueryTexts, Registers);
		QueryTextTableItemisedExpensesLots(Query, QueryTexts, Registers);
		QueryTextTableOtherAssetsLiabilities(Query, QueryTexts, Registers);
		QueryTextRecordsIncomeExpensesOtherAssetsLiabilities(Query, QueryTexts, Registers);
		QueryTextTableDocumentsRegistry(Query, QueryTexts, Registers);
		
		DeferredExpensesAllocationLocalization.AddRequestTexts(Query, QueryTexts, Registers);
	EndIf;
	
	////////////////////////////////////////////////////////////////////////////
	// We will get tables for movements
	
	Return DocumentsPosting.InitializeDocumentDataForPosting(Query, QueryTexts, AddlParameters);
	
EndFunction

#EndRegion

// StandardSubsystems.ObjectsVersioning

// Defines object settings for the object Versioning subsystem.
//
// Parameters:
//  Settings - Structure - subsystem settings.
Procedure OnDefineObjectVersioningSettings(Settings) Export

EndProcedure

// End StandardSubsystems.ObjectsVersioning

// Defines a list of creation commands based on.
//
// Parameters:
//  GenerationCommands - See GenerateFromOverridable.BeforeAddGenerationCommands.GenerationCommands
//  Parameters - See GenerateFromOverridable.BeforeAddGenerationCommands.Parameters
//
Procedure AddGenerationCommands(GenerationCommands, Parameters) Export
	
	BusinessProcesses.Job.AddGenerateCommand(GenerationCommands);
	
	DeferredExpensesAllocationLocalization.AddGenerationCommands(GenerationCommands, Parameters);

EndProcedure

// Adds the command to create the "RBP Distribution" document.
//
// Parameters:
//  GenerationCommands - See GenerateFromOverridable.BeforeAddGenerationCommands.GenerationCommands
//
// Returns:
//	ValueTableRow - added command
//
Function AddGenerateCommand(GenerationCommands) Export
	If AccessRight("Insert", Metadata.Documents.DeferredExpensesAllocation) Then
		CreateBasedOnCommand = GenerationCommands.Add();
		CreateBasedOnCommand.Manager = Metadata.Documents.DeferredExpensesAllocation.FullName();
		CreateBasedOnCommand.Presentation = TMCommonUse.ObjectPresentation(Metadata.Documents.DeferredExpensesAllocation);
		CreateBasedOnCommand.WriteMode = "Post";
		CreateBasedOnCommand.FunctionalOptions = "UseAccountingOfOtherIncomeExpenses";
		Return CreateBasedOnCommand;
	EndIf;
	Return Undefined;
EndFunction

// Defines a list of report commands.
//
// Parameters:
//   ReportsCommands - See ReportsOptionsOverridable.BeforeAddReportCommands.ReportsCommands
//   Parameters - See ReportsOptionsOverridable.BeforeAddReportCommands.Parameters
//
Procedure AddReportCommands(ReportsCommands, Parameters) Export
	
	
	
	DeferredExpensesAllocationLocalization.AddReportCommands(ReportsCommands, Parameters);

EndProcedure

// Returns the request text to reflect the document in regulated accounting.
//
// Returns:
//	String - Query text
//
Function TextOfReflectionInLocalAccounting() Export

	Return DeferredExpensesAllocationLocalization.TextOfReflectionInLocalAccounting();

EndFunction

// The function returns the request text for additional temporary tables
// that are required for reflection in regulated accounting.
//
// Returns:
//	String - The text of the request to create temporary tables.
//
Function RequestTextTTReflectedInLocalAccounting() Export

	Return DeferredExpensesAllocationLocalization.RequestTextTTReflectedInLocalAccounting();

EndFunction

// Returns parameters for selecting articles in the document.
// 
// Returns:
// 	Array - Array of accounting account settings (See IncomeAndExpensesServer.ArticleSelectionAndAnalyticsOptions)
//
Function ItemsAndDimensionsSelectionParameters() Export
	
	ArrayOfSelectionParameters = New Array;
	
	#Region ExpenseItem
	ChoiceParameters = IncomeAndExpensesServer.ArticleSelectionAndAnalyticsOptions();
	ChoiceParameters.DataPath = "Object";
	ChoiceParameters.AssetRef = "ExpenseItem";
	
	ChoiceParameters.ChoosingExpenseItem = True;
	ChoiceParameters.DimensionOfExpenses = "DimensionOfExpenses";
	ChoiceParameters.FormItems.AssetRef.Add("ExpenseItem");
	ChoiceParameters.FormItems.DimensionOfExpenses.Add("DimensionOfExpenses");
	
	ArrayOfSelectionParameters.Add(ChoiceParameters);
	#EndRegion
	
	#Region CostAllocationExpenseItem
	ChoiceParameters = IncomeAndExpensesServer.ArticleSelectionAndAnalyticsOptions();
	ChoiceParameters.DataPath = "Object.CostAllocation";
	ChoiceParameters.AssetRef = "ExpenseItem";
	
	ChoiceParameters.ChoosingExpenseItem = True;
	ChoiceParameters.DimensionOfExpenses = "DimensionOfExpenses";
	ChoiceParameters.FormItems.AssetRef.Add("CostAllocationExpenseItem");
	ChoiceParameters.FormItems.DimensionOfExpenses.Add("CostAllocationDimensionOfExpenses");
	
	ArrayOfSelectionParameters.Add(ChoiceParameters);
	#EndRegion
	
	Return ArrayOfSelectionParameters;
	
EndFunction

// Returns the last date when the expense occurred in the month when the RBP distribution document was issued
//
// Parameters:
//  FillingData - Structure - parameters for getting data.
//
// Returns:
//   Date   - last date when the expense occurred
//
Function GetDateOfOccurrenceOfRBP(FillingData) Export 

	QueryText = "
	|SELECT
	|	MAX(DatesOfExpenses.Period) AS Period
	|FROM
	|	(SELECT
	|		OtherExpenses.Period AS Period
	|	FROM
	|		AccumulationRegister.OtherExpenses AS OtherExpenses
	|	WHERE
	|		OtherExpenses.Organization = &Organization
	|		AND OtherExpenses.Department = &Department
	|		AND OtherExpenses.LineOfBusiness = &LineOfBusiness
	|		AND OtherExpenses.ExpenseItem = &ExpenseItem
	|		AND OtherExpenses.DimensionOfExpenses = &DimensionOfExpenses
	|		AND OtherExpenses.RecordType = VALUE(AccumulationRecordType.Receipt)
	|		AND OtherExpenses.Active
	|		AND OtherExpenses.Period BETWEEN BEGINOFPERIOD(&Period, MONTH) AND ENDOFPERIOD(&Period, MONTH)
	|	
	|	UNION ALL
	|	
	|	SELECT
	|		InventoryCost.Period
	|	FROM
	|		AccumulationRegister.InventoryCost AS InventoryCost
	|	WHERE
	|		InventoryCost.Organization = &Organization
	|		AND InventoryCost.Department = &Department
	|		AND InventoryCost.CorLineOfBusiness = &LineOfBusiness
	|		AND InventoryCost.ExpenseItemOfWriteOff = &ExpenseItem
	|		AND InventoryCost.DimensionOfExpenses = &DimensionOfExpenses
	|		AND InventoryCost.RecordType = VALUE(AccumulationRecordType.Expense)
	|		AND InventoryCost.Active
	|		AND InventoryCost.Period BETWEEN BEGINOFPERIOD(&Period, MONTH) AND ENDOFPERIOD(&Period, MONTH)
	|		AND InventoryCost.BusinessOperation = VALUE(Enum.BusinessTransactions.GoodsConsumptionOnDemand)
	|	
	|	UNION ALL
	|	
	|	SELECT
	|		BEGINOFPERIOD(&Period, MONTH)
	|) AS DatesOfExpenses";
	If Not ValueIsFilled(FillingData.ExpenseItem) 
		And TypeOf(FillingData.DimensionOfExpenses) = Type("CatalogRef.CostCenters") Then
		
		QueryText = "
		|SELECT
		|	MAX(DatesOfExpenses.Period) AS Period
		|FROM
		|	(SELECT
		|		OtherExpenses.Period AS Period
		|	FROM
		|		AccumulationRegister.OtherExpenses AS OtherExpenses
		|	WHERE
		|		OtherExpenses.Organization = &Organization
		|		AND OtherExpenses.Department = &Department
		|		AND OtherExpenses.DimensionOfExpenses = &DimensionOfExpenses
		|		AND OtherExpenses.RecordType = VALUE(AccumulationRecordType.Receipt)
		|		AND OtherExpenses.Active
		|		AND OtherExpenses.Period BETWEEN BEGINOFPERIOD(&Period, MONTH) AND ENDOFPERIOD(&Period, MONTH)
		|	
		|	UNION ALL
		|	
		|	SELECT
		|		InventoryCost.Period
		|	FROM
		|		AccumulationRegister.InventoryCost AS InventoryCost
		|	WHERE
		|		InventoryCost.Organization = &Organization
		|		AND InventoryCost.Department = &Department
		|		AND InventoryCost.DimensionOfExpenses = &DimensionOfExpenses
		|		AND InventoryCost.RecordType = VALUE(AccumulationRecordType.Expense)
		|		AND InventoryCost.Active
		|		AND InventoryCost.Period BETWEEN BEGINOFPERIOD(&Period, MONTH) AND ENDOFPERIOD(&Period, MONTH)
		|		AND InventoryCost.BusinessOperation = VALUE(Enum.BusinessTransactions.GoodsConsumptionOnDemand)
		|	
		|	UNION ALL
		|	
		|	SELECT
		|		BEGINOFPERIOD(&Period, MONTH)
		|) AS DatesOfExpenses";
		
	EndIf;
	Query = New Query;
	Query.Text = QueryText;
	TMCommonUse.SetRequestParameters(Query, FillingData);
	
	Result = Query.Execute();
	Selection = Result.Select();
	
	Selection.Next();
	Return BegOfDay(Selection.Period);
	
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

// StandardSubsystems.Print

// Overrides the printing settings for the object.
//
// Parameters:
//  Settings - See PrintManagement.ObjectPrintingSettings.
//
Procedure OnDefinePrintSettings(Settings) Export
	
	Settings.OnAddPrintCommands = True;
	
EndProcedure

// End StandardSubsystems.Print

#EndRegion

// The text of the RBP request for distribution (sources).
// 
// Returns:
//  String - Query text
Function RequestTextCostsForDistributionSources(SourceDebuggingMode = False) Export

// Request texts of RBP sources for distribution.
// Divided into areas:
// 1. TextuAlreferenCES
// 2. Textshodyrbp
// 3. The text of the description of the materials of the WORKNARBP
// 4. The text of the description of the expenditure of the NBP
// 5. The text is transientostatocrbp
// 6. textostatocnotesdistributed RBPs
// 7. TextpRikhodyRBPOVZ
// 8. The text of the description of the materials of the Worknarbpovz
// 9. The textpiztransitnyhzpermanentreferences
// 10. textrbpiztransitnyhsperforming indicators
// Each of the areas, in turn, is divided into 3 query texts (by UU, RU and TA).
// 
// Items 1, 2, 5 and 6 are the basic indicators (initial Balance (5), income (1), expenditure (2) and final Balance (6)). Collected according to the PH "Other expenses". The amounts are filled in.
// 
// For the remaining items, rows with zero sums are selected. The signs of "Sumless..." are set to TRUE. For requests for HIA, the ETO field is TRUE.
// - The text of the description of the materials of the work of the NBP - the expenditure RegisteredRecords are selected according to the PH "Cost of goods", 
//    which have items of expenditure with a variant of the distribution of expenses - the expenditure of the coming periods.
// - The text of the description of the expenses of the NBP - the lines are selected according to the documents of the distribution of other costs by items of expenditure with the option of allocating expenses - the overspending of future periods.
// - The text of the arrival of the HIA - incoming Registered Records are selected for the "Other expenses" PH with the analysis of expenses of the HIA type, which have a variant of the distribution of expenses - the overspending of the upcoming periods.
// - The text of the description of the materials of the WORKNARBPOVZ - the expenditure Registered Records are selected according to the PH "Cost of goods" with the analysis of expenses of the HIA type, 
//    which have a variant of the distribution of expenses - the overspending of future periods.
// - textrbpiztransitnyhspermanent indicators - lines are selected according to the documents of the distribution of other expenses, 
//    where the indicator coincides with the indicator from the cut of the latter at the end of the period according to the RS "Values of indicators for the distribution of expenses for the HIA, 
//    with the option of allocating expenses - for the coming periods.
// - The text shows the transitory and variable indicators - it looks like the last item, but the connection according to the PC "Values of indicators for the distribution of expenses" is not based on the cut of the latter, 
//    but on the Registered Records table. In addition to the indicator, the base of the indicator distribution is involved in the connection (it must be "entered monthly") and the period.
// For all these options, in the selected period, the availability of completed documents for the distribution of expenses of future periods is checked, as well as the availability of tasks for calculating the cost.
// 
// AD totals are selected in the query texts by TA.
// The request texts for TA are used only when the "Use Remote Control" feature is enabled.
// 
// The texts of HIA requests are used only when the "Use accountingobjects to collect new costs" feature is enabled

	#Region TextDescriptionOfFields
	TextDescriptionOfFields = "
	|SELECT TOP 0
	|	//Settings """" AS REQUESTED Source,
	|	DD.Organization AS Organization,
	|	DD.Department AS Department,
	|	DD.ExpenseItem AS ExpenseItem,
	|	DD.DimensionOfExpenses AS DimensionOfExpenses,
	|	DD.LineOfBusiness AS LineOfBusiness,
	// Receipt
	|	DD.Sum AS SumReceipt,
	|	DD.Sum AS AmountExcludingVATReceipt,
	|	DD.Sum AS SumManReceipt,
	|	DD.Sum AS SumComplReceipt,
	|	DD.Sum AS PermanentDifferenceReceipt,
	|	DD.Sum AS CostTDReceipt,
	|	DD.Sum AS AITAmountReceipt,
	// Expense
	|	DD.Sum AS SumExpense,
	|	DD.Sum AS AmountExcludingVATExpense,
	|	DD.Sum AS SumManExpense,
	|	DD.Sum AS SumComplExpense,
	|	DD.Sum AS PermanentDifferenceExpense,
	|	DD.Sum AS CostTDExpense,
	|	DD.Sum AS AITAmountExpense,
	// Balance
	|	DD.Sum AS SumBalance,
	|	DD.Sum AS AmountExcludingVATBalance,
	|	DD.Sum AS SumManBalance,
	|	DD.Sum AS SumComplBalance,
	|	DD.Sum AS PermanentDifferenceBalance,
	|	DD.Sum AS CostTDBalance,
	|	DD.Sum AS AITAmountBalance,
	// Balance total
	|	DD.Sum AS AmountBalanceTotal,
	|	DD.Sum AS VATExclusiveAmountBalanceTotal,
	|	DD.Sum AS UprAmountBalanceTotal,
	|	DD.Sum AS AmountReglBalanceTotal,
	|	DD.Sum AS ConstantDifferenceRemainderTotal,
	|	DD.Sum AS TimeDifferenceRemainderTotal,
	|	DD.Sum AS PersonalIncomeTaxAmountBalanceTotal,
	// without amounts
	|	FALSE AS WithoutManAmounts,
	|	FALSE AS NoLocalAmounts,
	|	FALSE AS WithoutSumsTa,
	|	FALSE AS WithoutNDDAmounts,
	|	FALSE AS ThisIsOVZ
	|FROM
	|	AccumulationRegister.OtherExpenses AS DD";
	
	#EndRegion

	#Region TextOfChangeDeferredExpensed
	TextOfChangeDeferredExpensed = "
	|SELECT
	|			//Settings of the ""Textismeniyarbp"" tab,
	|			DD.Organization,
	|			DD.Department,
	|			DD.ExpenseItem,
	|			DD.DimensionOfExpenses,
	|			DD.LineOfBusiness,
	// Receipt
	|			CASE WHEN ArticleMan.Ref IS NULL THEN 0 ELSE 1 END *
	|			CASE WHEN DD.RecordType = VALUE(AccumulationRecordType.Receipt) THEN 1 ELSE -1 END *
	|			DD.Sum,
	|			CASE WHEN ArticleMan.Ref IS NULL THEN 0 ELSE 1 END *
	|			CASE WHEN DD.RecordType = VALUE(AccumulationRecordType.Receipt) THEN 1 ELSE -1 END *
	|			DD.AmountExcludingVAT,
	|			CASE WHEN ArticleMan.Ref IS NULL THEN 0 ELSE 1 END *
	|			CASE WHEN DD.RecordType = VALUE(AccumulationRecordType.Receipt) THEN 1 ELSE -1 END *
	|			DD.SumMan,
	|			CASE WHEN ArticleLocal.Ref IS NULL THEN 0 ELSE 1 END *
	|			CASE WHEN DD.RecordType = VALUE(AccumulationRecordType.Receipt) THEN 1 ELSE -1 END *
	|			DD.SumCompl,
	|			0,
	|			0,
	|			0,
	// Expense
	|			0,
	|			0,
	|			0,
	|			0,
	|			0,
	|			0,
	|			0,
	// Balance
	|			0,
	|			0,
	|			0,
	|			0,
	|			0,
	|			0,
	|			0,
	// Balance total
	|			0,
	|			0,
	|			0,
	|			0,
	|			0,
	|			0,
	|			0,
	// without amounts
	|			FALSE AS WithoutManAmounts,
	|			FALSE AS NoLocalAmounts,
	|			FALSE AS WithoutSumsTa,
	|			FALSE AS WithoutNDDAmounts,
	|			FALSE AS ThisIsOVZ
	|		FROM
	|			AccumulationRegister.OtherExpenses AS DD
	|				LEFT JOIN ChartOfCharacteristicTypes.ExpenseItems AS ArticleMan
	|				ON ArticleMan.Ref = DD.ExpenseItem
	|					AND ArticleMan.CostAllocationOptionManag = VALUE(Enum.CostAllocationOptions.ToDeferredExpenses)
	|				LEFT JOIN ChartOfCharacteristicTypes.ExpenseItems AS ArticleLocal
	|				ON ArticleLocal.Ref = DD.ExpenseItem
	|					AND ArticleLocal.CostAllocationOptionLocal = VALUE(Enum.CostAllocationOptions.ToDeferredExpenses)
	
	|		WHERE
	|			DD.Period BETWEEN &BeginOfPeriod AND &EndOfPeriod
	|			AND NOT (DD.CalculationOfCost OR DD.LotCalculation)
	|			AND DD.Active
	|			AND (&ByAllCompanies OR DD.Organization = &Organization)
	|			AND (&ByAllBusinessUnits OR DD.Department = &Department)
	|			AND NOT DD.Recorder REFS Document.DeferredExpensesAllocation
	|			AND (
	|				ArticleMan.Ref IS NOT NULL
	|				OR ArticleLocal.Ref IS NOT NULL
	|			) 
	|";
	
	#EndRegion

	#Region TextRBPExpenses
	TextRBPExpenses = "
	|		SELECT
	|			//TEXTSHODYRBP settings,
	|			Expenses.Organization,
	|			Expenses.Department,
	|			Expenses.ExpenseItem,
	|			Expenses.DimensionOfExpenses,
	|			Expenses.LineOfBusiness,
	// Receipt
	|			0,
	|			0,
	|			0,
	|			0,
	|			0,
	|			0,
	|			0,
	// Expense
	|			CASE WHEN ArticleMan.Ref IS NULL THEN 0 ELSE 1 END *
	|			Expenses.Sum,
	|			CASE WHEN ArticleMan.Ref IS NULL THEN 0 ELSE 1 END *
	|			Expenses.AmountExcludingVAT,
	|			CASE WHEN ArticleMan.Ref IS NULL THEN 0 ELSE 1 END *
	|			Expenses.SumMan,
	|			Expenses.SumCompl,
	|			0,
	|			0,
	|			0,
	// Balance
	|			0,
	|			0,
	|			0,
	|			0,
	|			0,
	|			0,
	|			0,
	// Balance total
	|			0,
	|			0,
	|			0,
	|			0,
	|			0,
	|			0,
	|			0,
	// without amounts
	|			FALSE AS WithoutManAmounts,
	|			FALSE AS NoLocalAmounts,
	|			FALSE AS WithoutSumsTa,
	|			FALSE AS WithoutNDDAmounts,
	|			FALSE
	|		FROM
	|			AccumulationRegister.OtherExpenses AS Expenses
	|				INNER JOIN Document.DeferredExpensesAllocation AS Allocation
	|				ON Expenses.Recorder = Allocation.Ref
	|				LEFT JOIN ChartOfCharacteristicTypes.ExpenseItems AS ArticleMan
	|				ON ArticleMan.Ref = Expenses.ExpenseItem
	|					AND ArticleMan.CostAllocationOptionManag = VALUE(Enum.CostAllocationOptions.ToDeferredExpenses)
	|					AND Allocation.ManagementAccounting
	|					AND (Allocation.Date <= &EndOfPeriod
	|						AND NOT Expenses.CalculationOfCost
	|						AND NOT Allocation.AmountEntryOptionMan = VALUE(Enum.OptionsOfDEAmountSpecification.DeterminedAutomatically)
	|						OR Allocation.Date < &BeginOfPeriod)
	|				LEFT JOIN ChartOfCharacteristicTypes.ExpenseItems AS ArticleLocal
	|				ON ArticleLocal.Ref = Expenses.ExpenseItem
	|					AND ArticleLocal.CostAllocationOptionLocal = VALUE(Enum.CostAllocationOptions.ToDeferredExpenses)
	|					AND Allocation.LocalAccounting
	|					AND (Allocation.Date <= &EndOfPeriod
	|						AND NOT Expenses.CalculationOfCost
	|						AND NOT Allocation.AmountEntryOptionLocal = VALUE(Enum.OptionsOfDEAmountSpecification.DeterminedAutomatically)
	|						OR Allocation.Date < &BeginOfPeriod)
	
	|		WHERE
	|			Expenses.RecordType = VALUE(AccumulationRecordType.Expense)
	|			AND Expenses.Period >= &BeginOfPeriod
	|			AND Expenses.Active
	|			AND (&ByAllCompanies OR Expenses.Organization = &Organization)
	|			AND (&ByAllBusinessUnits OR Expenses.Department = &Department)
	|			AND (
	|				ArticleMan.Ref IS NOT NULL
	|				OR ArticleLocal.Ref IS NOT NULL
	|			) 
	|";
	
	
	#EndRegion
	
	#Region TextWriteOffOfMaterialsOfWorksOnRBP
	TextWriteOffOfMaterialsOfWorksOnRBP = "
	|		SELECT
	|			//Settings ""TextsPissionmAterialswoRkingNaRBP"",
	|			ISNULL(CompanyRecipient.Ref, Cost_.Organization),
	|			Cost_.Department,
	|			Cost_.ExpenseItemOfWriteOff,
	|			Cost_.DimensionOfExpenses,
	|			ISNULL(Assignments.LineOfBusiness, VALUE(Catalog.LinesOfBusiness.EmptyRef)),
	// Receipt
	|			0,
	|			0,
	|			0,
	|			0,
	|			0,
	|			0,
	|			0,
	// Expense
	|			0,
	|			0,
	|			0,
	|			0,
	|			0,
	|			0,
	|			0,
	// Balance
	|			0,
	|			0,
	|			0,
	|			0,
	|			0,
	|			0,
	|			0,
	// Balance total
	|			0,
	|			0,
	|			0,
	|			0,
	|			0,
	|			0,
	|			0,
	// without amounts
	|			ArticleMan.Ref IS NOT NULL AND DistributionOfMan.Ref IS NULL AS WithoutManAmounts,
	|			ArticleLocal.Ref IS NOT NULL AND DistributionOfLocal.Ref IS NULL AS NoLocalAmounts,
	|			FALSE AS WithoutSumsTa,
	|			FALSE AS WithoutDDAmounts,
	|			FALSE
	|		FROM
	|			AccumulationRegister.InventoryCost AS Cost_
	|				LEFT JOIN Catalog.Assignments AS Assignments
	|				ON Assignments.Ref = Cost_.ItemsLocationAttributes.Purpose
	|				LEFT JOIN Catalog.Companies AS CompanyRecipient
	|				ON CompanyRecipient.Ref = Cost_.CorCompany
	|				LEFT JOIN ChartOfCharacteristicTypes.ExpenseItems AS ArticleMan
	|				ON ArticleMan.Ref = Cost_.ExpenseItemOfWriteOff
	|					AND ArticleMan.CostAllocationOptionManag = VALUE(Enum.CostAllocationOptions.ToDeferredExpenses)
	|				LEFT JOIN ChartOfCharacteristicTypes.ExpenseItems AS ArticleLocal
	|				ON ArticleLocal.Ref = Cost_.ExpenseItemOfWriteOff
	|					AND ArticleLocal.CostAllocationOptionLocal = VALUE(Enum.CostAllocationOptions.ToDeferredExpenses)
	
	|				LEFT JOIN Document.DeferredExpensesAllocation AS DistributionOfMan
	|				ON
	|					DistributionOfMan.Organization = ISNULL(CompanyRecipient.Ref, Cost_.Organization)
	|					AND DistributionOfMan.Department = Cost_.Department
	|					AND DistributionOfMan.ExpenseItem = ArticleMan.Ref
	|					AND DistributionOfMan.DimensionOfExpenses = Cost_.DimensionOfExpenses
	|					AND DistributionOfMan.LineOfBusiness = ISNULL(Assignments.LineOfBusiness, VALUE(Catalog.LinesOfBusiness.EmptyRef))
	|					AND DistributionOfMan.ManagementAccounting
	|					AND DistributionOfMan.Posted
	|					AND DistributionOfMan.Date BETWEEN &BeginOfPeriod AND &EndOfPeriod
	|				LEFT JOIN Document.DeferredExpensesAllocation AS DistributionOfLocal
	|				ON
	|					DistributionOfLocal.Organization = ISNULL(CompanyRecipient.Ref, Cost_.Organization)
	|					AND DistributionOfLocal.Department = Cost_.Department
	|					AND DistributionOfLocal.ExpenseItem = ArticleLocal.Ref
	|					AND DistributionOfLocal.DimensionOfExpenses = Cost_.DimensionOfExpenses
	|					AND DistributionOfLocal.LineOfBusiness = ISNULL(Assignments.LineOfBusiness, VALUE(Catalog.LinesOfBusiness.EmptyRef))
	|					AND DistributionOfLocal.LocalAccounting
	|					AND DistributionOfLocal.Posted
	|					AND DistributionOfLocal.Date BETWEEN &BeginOfPeriod AND &EndOfPeriod
	
	|		WHERE
	|			Cost_.Period BETWEEN &BeginOfPeriod AND &EndOfPeriod
	|			AND Cost_.RecordType = VALUE(AccumulationRecordType.Expense)
	|			AND (&ByAllCompanies OR Cost_.Organization = &Organization)
	|			AND (&ByAllBusinessUnits OR Cost_.Department = &Department)
	|			AND TRUE IN (SELECT TOP 1 TRUE
	|				FROM InformationRegister.JobsForCalculatingCost AS Jobs
	|				WHERE
	|					Jobs.Month <= &BeginOfPeriod
	|					AND Jobs.Organization = Cost_.Organization
	|				)
	|			AND (
	|				ArticleMan.Ref IS NOT NULL AND DistributionOfMan.Ref IS NULL
	|				OR ArticleLocal.Ref IS NOT NULL AND DistributionOfLocal.Ref IS NULL
	|			) 
	|";
	
	#EndRegion
	#Region TextWriteOffOfExpensesForRBP
	TextWriteOffOfExpensesForRBP = "
	|		SELECT
	|			//Settings for ""textspissionreferences"",
	|			DD.Organization,
	|			WriteOffOfExpenses.Department,
	|			WriteOffOfExpenses.ExpenseItem,
	|			WriteOffOfExpenses.DimensionOfExpenses,
	|			WriteOffOfExpenses.LineOfBusiness,
	// Receipt
	|			0,
	|			0,
	|			0,
	|			0,
	|			0,
	|			0,
	|			0,
	// Expense
	|			0,
	|			0,
	|			0,
	|			0,
	|			0,
	|			0,
	|			0,
	// Balance
	|			0,
	|			0,
	|			0,
	|			0,
	|			0,
	|			0,
	|			0,
	// Balance total
	|			0,
	|			0,
	|			0,
	|			0,
	|			0,
	|			0,
	|			0,
	// without amounts
	|			ArticleMan.Ref IS NOT NULL AND DistributionOfMan.Ref IS NULL AS WithoutManAmounts,
	|			ArticleLocal.Ref IS NOT NULL AND DistributionOfLocal.Ref IS NULL AS NoLocalAmounts,
	
	
	|			FALSE AS WithoutSumsTa,
	|			FALSE AS WithoutDDAmounts,
	|			FALSE
	|		FROM
	|			Document.AllocationOfOtherCosts.WriteOff AS WriteOffOfExpenses
	|				INNER JOIN Document.AllocationOfOtherCosts AS DD
	|				ON WriteOffOfExpenses.Ref = DD.Ref
	|				LEFT JOIN ChartOfCharacteristicTypes.ExpenseItems AS ArticleMan
	|				ON ArticleMan.Ref = WriteOffOfExpenses.ExpenseItem
	|					AND ArticleMan.CostAllocationOptionManag = VALUE(Enum.CostAllocationOptions.ToDeferredExpenses)
	|				LEFT JOIN ChartOfCharacteristicTypes.ExpenseItems AS ArticleLocal
	|				ON ArticleLocal.Ref = WriteOffOfExpenses.ExpenseItem
	|					AND ArticleLocal.CostAllocationOptionLocal = VALUE(Enum.CostAllocationOptions.ToDeferredExpenses)
	
	
	|				LEFT JOIN Document.DeferredExpensesAllocation AS DistributionOfMan
	|				ON
	|					DistributionOfMan.Organization = DD.Organization
	|					AND DistributionOfMan.Department = WriteOffOfExpenses.Department
	|					AND DistributionOfMan.ExpenseItem = ArticleMan.Ref
	|					AND DistributionOfMan.DimensionOfExpenses = WriteOffOfExpenses.DimensionOfExpenses
	|					AND DistributionOfMan.LineOfBusiness = WriteOffOfExpenses.LineOfBusiness
	|					AND DistributionOfMan.ManagementAccounting
	|					AND DistributionOfMan.Posted
	|					AND DistributionOfMan.Date BETWEEN &BeginOfPeriod AND &EndOfPeriod
	|				LEFT JOIN Document.DeferredExpensesAllocation AS DistributionOfLocal
	|				ON
	|					DistributionOfLocal.Organization = DD.Organization
	|					AND DistributionOfLocal.Department = WriteOffOfExpenses.Department
	|					AND DistributionOfLocal.ExpenseItem = ArticleLocal.Ref
	|					AND DistributionOfLocal.DimensionOfExpenses = WriteOffOfExpenses.DimensionOfExpenses
	|					AND DistributionOfLocal.LineOfBusiness = WriteOffOfExpenses.LineOfBusiness
	|					AND DistributionOfLocal.LocalAccounting
	|					AND DistributionOfLocal.Posted
	|					AND DistributionOfLocal.Date BETWEEN &BeginOfPeriod AND &EndOfPeriod
	|		WHERE
	|			DD.Date BETWEEN &BeginOfPeriod AND &EndOfPeriod
	|			AND DD.ManagementAccounting
	|			AND DD.Posted
	|			AND (&ByAllCompanies OR DD.Organization = &Organization)
	|			AND (&ByAllBusinessUnits OR WriteOffOfExpenses.Department = &Department)
	|			AND TRUE IN (SELECT TOP 1 TRUE
	|				FROM InformationRegister.JobsForCalculatingCost AS Jobs
	|				WHERE
	|					Jobs.Month <= DD.Date
	|					AND Jobs.Organization = DD.Organization
	|				)
	|			AND (
	|				ArticleMan.Ref IS NOT NULL AND DistributionOfMan.Ref IS NULL
	|				OR ArticleLocal.Ref IS NOT NULL AND DistributionOfLocal.Ref IS NULL
				
				
	|			) 
	|";
	
	#EndRegion
	#Region TextIsRollingRemainderOfRBP
	TextIsRollingRemainderOfRBP = "
	|		SELECT
	|			//Settings for ""Text-TRANSIENTOSTATOCRBP"",
	|			Balance.Organization,
	|			Balance.Department,
	|			Balance.ExpenseItem,
	|			Balance.DimensionOfExpenses,
	|			Balance.LineOfBusiness,
	// Receipt
	|			0,
	|			0,
	|			0,
	|			0,
	|			0,
	|			0,
	|			0,
	// Expense
	|			0,
	|			0,
	|			0,
	|			0,
	|			0,
	|			0,
	|			0,
	// Balance
	|			CASE WHEN 
	|				ExpenseItem.CostAllocationOptionManag = 
	|					VALUE(Enum.CostAllocationOptions.ToDeferredExpenses)
	|				THEN 1 ELSE 0
	|			END *
	|			Balance.SumBalance,
	|			CASE WHEN 
	|				ExpenseItem.CostAllocationOptionManag = 
	|					VALUE(Enum.CostAllocationOptions.ToDeferredExpenses)
	|				THEN 1 ELSE 0
	|			END *
	|			Balance.AmountExcludingVATBalance,
	|			CASE WHEN 
	|				ExpenseItem.CostAllocationOptionManag = 
	|					VALUE(Enum.CostAllocationOptions.ToDeferredExpenses)
	|				THEN 1 ELSE 0
	|			END *
	|			Balance.SumManBalance,
	|			CASE WHEN 
	|				ExpenseItem.CostAllocationOptionLocal = 
	|					VALUE(Enum.CostAllocationOptions.ToDeferredExpenses)
	|				THEN 1 ELSE 0
	|			END *
	|			Balance.SumComplBalance,
	|			0,
	|			0,
	|			CASE WHEN 
	|				ExpenseItem.CostAllocationOptionTax = 
	|					VALUE(Enum.CostAllocationOptions.ToDeferredExpenses)
	|				THEN 1 ELSE 0
	|			END *
	|			Balance.AITAmountBalance,
	// Balance total
	|			0,
	|			0,
	|			0,
	|			0,
	|			0,
	|			0,
	|			0,
	// without amounts
	|			FALSE AS WithoutManAmounts,
	|			FALSE AS NoLocalAmounts,
	|			FALSE AS WithoutSumsTa,
	|			FALSE AS WithoutDDAmounts,
	|			FALSE
	|		FROM
	|			AccumulationRegister.OtherExpenses.Balance(
	|				&BeginOfPeriod, 
	|				(&ByAllCompanies OR Organization = &Organization)
	|					AND (&ByAllBusinessUnits OR Department = &Department)
	|					AND (
	|						ExpenseItem.CostAllocationOptionManag = VALUE(Enum.CostAllocationOptions.ToDeferredExpenses)
	|						OR ExpenseItem.CostAllocationOptionLocal = VALUE(Enum.CostAllocationOptions.ToDeferredExpenses)
	
	|					)
	|			) AS Balance
	|";
	
	#EndRegion
	
	#Region TextBalanceOfUnallocatedRBP
	TextBalanceOfUnallocatedRBP = "
	|		SELECT
	|			//Settings for ""textostatocnotdistributed RBPs"",
	|			Balance.Organization,
	|			Balance.Department,
	|			Balance.ExpenseItem,
	|			Balance.DimensionOfExpenses,
	|			Balance.LineOfBusiness,
	// Receipt
	|			0,
	|			0,
	|			0,
	|			0,
	|			0,
	|			0,
	|			0,
	// Expense
	|			0,
	|			0,
	|			0,
	|			0,
	|			0,
	|			0,
	|			0,
	// Balance
	|			0,
	|			0,
	|			0,
	|			0,
	|			0,
	|			0,
	|			0,
	// Balance total
	|			CASE WHEN 
	|				ExpenseItem.CostAllocationOptionManag = 
	|					VALUE(Enum.CostAllocationOptions.ToDeferredExpenses)
	|				THEN 1 ELSE 0
	|			END *
	|			Balance.SumBalance,
	|			CASE WHEN 
	|				ExpenseItem.CostAllocationOptionManag = 
	|					VALUE(Enum.CostAllocationOptions.ToDeferredExpenses)
	|				THEN 1 ELSE 0
	|			END *
	|			Balance.AmountExcludingVATBalance,
	|			CASE WHEN 
	|				ExpenseItem.CostAllocationOptionManag = 
	|					VALUE(Enum.CostAllocationOptions.ToDeferredExpenses)
	|				THEN 1 ELSE 0
	|			END *
	|			Balance.SumManBalance,
	|			CASE WHEN 
	|				ExpenseItem.CostAllocationOptionLocal = 
	|					VALUE(Enum.CostAllocationOptions.ToDeferredExpenses)
	|				THEN 1 ELSE 0
	|			END *
	|			Balance.SumComplBalance,
	|			0,
	|			0,
	|			CASE WHEN 
	|				ExpenseItem.CostAllocationOptionTax = 
	|					VALUE(Enum.CostAllocationOptions.ToDeferredExpenses)
	|				THEN 1 ELSE 0
	|			END *
	|			Balance.AITAmountBalance,
	// without amounts
	|			FALSE AS WithoutManAmounts,
	|			FALSE AS NoLocalAmounts,
	|			FALSE AS WithoutSumsTa,
	|			FALSE AS WithoutDDAmounts,
	|			FALSE
	|		FROM
	|			AccumulationRegister.OtherExpenses.Balance(
	|				DATETIME(3999, 1, 1), 
	|				(&ByAllCompanies OR Organization = &Organization)
	|					AND (&ByAllBusinessUnits OR Department = &Department)
	|					AND (
	|						ExpenseItem.CostAllocationOptionManag = VALUE(Enum.CostAllocationOptions.ToDeferredExpenses)
	|						OR ExpenseItem.CostAllocationOptionLocal = VALUE(Enum.CostAllocationOptions.ToDeferredExpenses)
	
	|					)
	|			) AS Balance
	|";
	
	#EndRegion
	
	#Region TextRbpovzParishes
	TextRbpovzParishes = "
	|SELECT
	|			//TextpRikhodyRBPOVZ settings,
	|			Parishes.Organization AS Organization,
	|			Parishes.Department AS Department,
	|			VALUE(ChartOfCharacteristicTypes.ExpenseItems.EmptyRef) AS ExpenseItem,
	|			Parishes.DimensionOfExpenses AS DimensionOfExpenses,
	|			VALUE(Catalog.LinesOfBusiness.EmptyRef),
	// Receipt
	|			0,
	|			0,
	|			0,
	|			0,
	|			0,
	|			0,
	|			0,
	// Expense
	|			0,
	|			0,
	|			0,
	|			0,
	|			0,
	|			0,
	|			0,
	// Balance
	|			0,
	|			0,
	|			0,
	|			0,
	|			0,
	|			0,
	|			0,
	// Balance total
	|			0,
	|			0,
	|			0,
	|			0,
	|			0,
	|			0,
	|			0,
	// without amounts
	|			COInChargeMan.Ref IS NOT NULL AND DistributionOfMan.Ref IS NULL AS WithoutManAmounts,
	|			COLocal.Ref IS NOT NULL AND DistributionOfLocal.Ref IS NULL AS NoLocalAmounts,
	
	
	|			FALSE AS WithoutSumsTa,
	|			FALSE AS WithoutDDAmounts,
	|			TRUE
	|		FROM
	|			AccumulationRegister.OtherExpenses AS Parishes
	|				LEFT JOIN Catalog.CostCenters AS COInChargeMan
	|				ON	(COInChargeMan.Ref = Parishes.DimensionOfExpenses)
	|					AND COInChargeMan.CostAllocationOptionManag = VALUE(Enum.CostAllocationOptions.ToDeferredExpenses)
	|				LEFT JOIN Document.DeferredExpensesAllocation AS DistributionOfMan
	|				ON BEGINOFPERIOD(DistributionOfMan.Date, MONTH) = BEGINOFPERIOD(Parishes.Period, MONTH)
	|					AND DistributionOfMan.Posted
	|					AND DistributionOfMan.ManagementAccounting
	|					AND DistributionOfMan.AmountEntryOptionMan = VALUE(Enum.OptionsOfDEAmountSpecification.DeterminedAutomatically)
	|					AND DistributionOfMan.Organization = Parishes.Organization
	|					AND DistributionOfMan.Department = Parishes.Department
	|					AND DistributionOfMan.DimensionOfExpenses = COInChargeMan.Ref
	|				LEFT JOIN Catalog.CostCenters AS COLocal
	|				ON	(COLocal.Ref = Parishes.DimensionOfExpenses)
	|					AND COLocal.CostAllocationOptionLocal = VALUE(Enum.CostAllocationOptions.ToDeferredExpenses)
	|				LEFT JOIN Document.DeferredExpensesAllocation AS DistributionOfLocal
	|				ON BEGINOFPERIOD(DistributionOfLocal.Date, MONTH) = BEGINOFPERIOD(Parishes.Period, MONTH)
	|					AND DistributionOfLocal.Posted
	|					AND DistributionOfLocal.LocalAccounting
	|					AND DistributionOfLocal.AmountEntryOptionLocal = VALUE(Enum.OptionsOfDEAmountSpecification.DeterminedAutomatically)
	|					AND DistributionOfLocal.Organization = Parishes.Organization
	|					AND DistributionOfLocal.Department = Parishes.Department
	|					AND DistributionOfLocal.DimensionOfExpenses = COLocal.Ref
	|		WHERE
	|			Parishes.Period BETWEEN &BeginOfPeriod AND &EndOfPeriod
	|			AND Parishes.RecordType = VALUE(AccumulationRecordType.Receipt)
	|			AND (&ByAllCompanies OR Parishes.Organization = &Organization)
	|			AND (&ByAllBusinessUnits OR Parishes.Department = &Department)
	|			AND (
	|				COInChargeMan.Ref IS NOT NULL AND DistributionOfMan.Ref IS NULL
	|				OR COLocal.Ref IS NOT NULL AND DistributionOfLocal.Ref IS NULL
	
	|			)
	
	|";
	
	#EndRegion
	
	#Region TextWriteOffOfMaterialsOfWorksOnRBPOVZ
	TextWriteOffOfMaterialsOfWorksOnRBPOVZ = "
	|		SELECT
	|			//Settings ""TextsPissionmAterialswoRkingNaRBPOVZ"",
	|			Cost_.Organization,
	|			Cost_.Department,
	|			VALUE(ChartOfCharacteristicTypes.ExpenseItems.EmptyRef),
	|			Cost_.DimensionOfExpenses,
	|			VALUE(Catalog.LinesOfBusiness.EmptyRef),
	// Receipt
	|			0,
	|			0,
	|			0,
	|			0,
	|			0,
	|			0,
	|			0,
	// Expense
	|			0,
	|			0,
	|			0,
	|			0,
	|			0,
	|			0,
	|			0,
	// Balance
	|			0,
	|			0,
	|			0,
	|			0,
	|			0,
	|			0,
	|			0,
	// Balance total
	|			0,
	|			0,
	|			0,
	|			0,
	|			0,
	|			0,
	|			0,
	// without amounts
	|			COInChargeMan.Ref IS NOT NULL AND DistributionOfMan.Ref IS NULL AS WithoutManAmounts,
	|			COLocal.Ref IS NOT NULL AND DistributionOfLocal.Ref IS NULL AS NoLocalAmounts,
	
	
	|			FALSE AS WithoutSumsTa,
	|			FALSE AS WithoutDDAmounts,
	|			TRUE
	|		FROM
	|			AccumulationRegister.InventoryCost AS Cost_
	|				LEFT JOIN Catalog.Assignments AS Assignments
	|				ON (Assignments.Ref = Cost_.ItemsLocationAttributes.Purpose)

	|				LEFT JOIN Catalog.CostCenters AS COInChargeMan
	|				ON	(COInChargeMan.Ref = Cost_.DimensionOfExpenses)
	|					AND COInChargeMan.CostAllocationOptionManag = VALUE(Enum.CostAllocationOptions.ToDeferredExpenses)
	|				LEFT JOIN Document.DeferredExpensesAllocation AS DistributionOfMan
	|				ON BEGINOFPERIOD(DistributionOfMan.Date, MONTH) = BEGINOFPERIOD(Cost_.Period, MONTH)
	|					AND DistributionOfMan.Posted
	|					AND DistributionOfMan.ManagementAccounting
	|					AND DistributionOfMan.AmountEntryOptionMan = VALUE(Enum.OptionsOfDEAmountSpecification.DeterminedAutomatically)
	|					AND DistributionOfMan.Organization = Cost_.Organization
	|					AND DistributionOfMan.Department = Cost_.Department
	|					AND DistributionOfMan.DimensionOfExpenses = COInChargeMan.Ref
	|				LEFT JOIN Catalog.CostCenters AS COLocal
	|				ON	(COLocal.Ref = Cost_.DimensionOfExpenses)
	|					AND COLocal.CostAllocationOptionLocal = VALUE(Enum.CostAllocationOptions.ToDeferredExpenses)
	|				LEFT JOIN Document.DeferredExpensesAllocation AS DistributionOfLocal
	|				ON BEGINOFPERIOD(DistributionOfLocal.Date, MONTH) = BEGINOFPERIOD(Cost_.Period, MONTH)
	|					AND DistributionOfLocal.Posted
	|					AND DistributionOfLocal.LocalAccounting
	|					AND DistributionOfLocal.AmountEntryOptionLocal = VALUE(Enum.OptionsOfDEAmountSpecification.DeterminedAutomatically)
	|					AND DistributionOfLocal.Organization = Cost_.Organization
	|					AND DistributionOfLocal.Department = Cost_.Department
	|					AND DistributionOfLocal.DimensionOfExpenses = COLocal.Ref

	|		WHERE
	|			Cost_.Period BETWEEN &BeginOfPeriod AND &EndOfPeriod
	|			AND Cost_.RecordType = VALUE(AccumulationRecordType.Expense)
	|			AND (&ByAllCompanies OR Cost_.Organization = &Organization)
	|			AND (&ByAllBusinessUnits OR Cost_.Department = &Department)
	|			AND (
	|				COInChargeMan.Ref IS NOT NULL AND DistributionOfMan.Ref IS NULL
	|				OR COLocal.Ref IS NOT NULL AND DistributionOfLocal.Ref IS NULL
	
	|			)
	|";
	
	#EndRegion
	
	#Region TextRBInTransitHIAConstantIndicators
	TextRBForTransitHIAConstantManIndicators = "
	|		SELECT DISTINCT
	|			//Settings ""textrbpiztransitnyhzpermanentreferences"",
	|			CostCenters.Organization,
	|			CostCenters.Department,
	|			VALUE(ChartOfCharacteristicTypes.ExpenseItems.EmptyRef),
	|			CostCenters.Ref,
	|			VALUE(Catalog.LinesOfBusiness.EmptyRef),
	// Receipt
	|			0,
	|			0,
	|			0,
	|			0,
	|			0,
	|			0,
	|			0,
	// Expense
	|			0,
	|			0,
	|			0,
	|			0,
	|			0,
	|			0,
	|			0,
	// Balance
	|			0,
	|			0,
	|			0,
	|			0,
	|			0,
	|			0,
	|			0,
	// Balance total
	|			0,
	|			0,
	|			0,
	|			0,
	|			0,
	|			0,
	|			0,
	// without amounts
	|			TRUE AS WithoutManAmounts,
	|			FALSE AS NoLocalAmounts,
	|			FALSE AS WithoutSumsTa,
	|			FALSE AS WithoutDDAmounts,
	|			TRUE
	|		FROM
	|			Document.AllocationOfOtherCosts AS DistributionOfChildrenFromHIA
	|			INNER JOIN InformationRegister.IndicatorValuesForAllocatingExpensesBetweenExpenseObjects.SliceLast(&EndOfPeriod) AS CrossSectionOfValues
	|				ON CrossSectionOfValues.Factor = DistributionOfChildrenFromHIA.Factor
	|			INNER JOIN Catalog.CostCenters AS CostCenters
	|				ON	CostCenters.Ref = CrossSectionOfValues.ConstCenter
	|					AND CostCenters.Organization = DistributionOfChildrenFromHIA.Organization
	|					AND CostCenters.CostAllocationOptionManag = VALUE(Enum.CostAllocationOptions.ToDeferredExpenses)
	|			LEFT JOIN Document.DeferredExpensesAllocation AS DeferredExpenseAllocation
	|				ON DeferredExpenseAllocation.Organization = CostCenters.Organization
	|					AND DeferredExpenseAllocation.Department = CostCenters.Department
	|					AND DeferredExpenseAllocation.DimensionOfExpenses = CostCenters.Ref
	|					AND DeferredExpenseAllocation.ManagementAccounting
	|					AND DeferredExpenseAllocation.Posted
	|					AND BEGINOFPERIOD(DeferredExpenseAllocation.Date, MONTH) = BEGINOFPERIOD(DistributionOfChildrenFromHIA.Date, MONTH)
	|		WHERE
	|			DistributionOfChildrenFromHIA.Posted
	|			AND DistributionOfChildrenFromHIA.Date BETWEEN &BeginOfPeriod AND &EndOfPeriod
	|			AND DistributionOfChildrenFromHIA.ManagementAccounting 
	|			AND NOT CrossSectionOfValues.IndicatorValue = 0
	|			AND (&ByAllCompanies OR DistributionOfChildrenFromHIA.Organization = &Organization)
	|			AND (&ByAllCompanies OR CostCenters.Organization = &Organization)
	|			AND (&ByAllBusinessUnits OR CostCenters.Department = &Department)
	|			AND DeferredExpenseAllocation.Ref IS NULL
	|			AND TRUE IN (SELECT TOP 1 TRUE
	|				FROM InformationRegister.JobsForCalculatingCost AS Jobs
	|				WHERE
	|					Jobs.Month <= DistributionOfChildrenFromHIA.Date
	|					AND Jobs.Organization = DistributionOfChildrenFromHIA.Organization
	|				)
	|";
	TextRBForTransitHIAConstantLocalHealthIndicators = "
	|		SELECT DISTINCT
	|			//Settings ""textrbpiztransitnyhzpermanentreferencesregl"",
	|			CostCenters.Organization,
	|			CostCenters.Department,
	|			VALUE(ChartOfCharacteristicTypes.ExpenseItems.EmptyRef),
	|			CostCenters.Ref,
	|			VALUE(Catalog.LinesOfBusiness.EmptyRef),
	// Receipt
	|			0,
	|			0,
	|			0,
	|			0,
	|			0,
	|			0,
	|			0,
	// Expense
	|			0,
	|			0,
	|			0,
	|			0,
	|			0,
	|			0,
	|			0,
	// Balance
	|			0,
	|			0,
	|			0,
	|			0,
	|			0,
	|			0,
	|			0,
	// Balance total
	|			0,
	|			0,
	|			0,
	|			0,
	|			0,
	|			0,
	|			0,
	// without amounts
	|			FALSE AS WithoutManAmounts,
	|			TRUE AS NoLocalAmounts,
	|			FALSE AS WithoutSumsTa,
	|			FALSE AS WithoutDDAmounts,
	|			TRUE
	|		FROM
	|			Document.AllocationOfOtherCosts AS DistributionOfChildrenFromHIA
	|			INNER JOIN InformationRegister.IndicatorValuesForAllocatingExpensesBetweenExpenseObjects.SliceLast(&EndOfPeriod) AS CrossSectionOfValues
	|				ON CrossSectionOfValues.Factor = DistributionOfChildrenFromHIA.Factor
	|			INNER JOIN Catalog.CostCenters AS CostCenters
	|				ON	CostCenters.Ref = CrossSectionOfValues.ConstCenter
	|					AND CostCenters.Organization = DistributionOfChildrenFromHIA.Organization
	|					AND CostCenters.CostAllocationOptionLocal = VALUE(Enum.CostAllocationOptions.ToDeferredExpenses)
	|			LEFT JOIN Document.DeferredExpensesAllocation AS DeferredExpenseAllocation
	|				ON DeferredExpenseAllocation.Organization = CostCenters.Organization
	|					AND DeferredExpenseAllocation.Department = CostCenters.Department
	|					AND DeferredExpenseAllocation.DimensionOfExpenses = CostCenters.Ref
	|					AND DeferredExpenseAllocation.LocalAccounting
	|					AND DeferredExpenseAllocation.Posted
	|					AND BEGINOFPERIOD(DeferredExpenseAllocation.Date, MONTH) = BEGINOFPERIOD(DistributionOfChildrenFromHIA.Date, MONTH)
	|		WHERE
	|			DistributionOfChildrenFromHIA.Posted
	|			AND DistributionOfChildrenFromHIA.Date BETWEEN &BeginOfPeriod AND &EndOfPeriod
	|			AND DistributionOfChildrenFromHIA.LocalAccounting 
	|			AND NOT CrossSectionOfValues.IndicatorValue = 0
	|			AND (&ByAllCompanies OR DistributionOfChildrenFromHIA.Organization = &Organization)
	|			AND (&ByAllCompanies OR CostCenters.Organization = &Organization)
	|			AND (&ByAllBusinessUnits OR CostCenters.Department = &Department)
	|			AND DeferredExpenseAllocation.Ref IS NULL
	|			AND TRUE IN (SELECT TOP 1 TRUE
	|				FROM InformationRegister.JobsForCalculatingCost AS Jobs
	|				WHERE
	|					Jobs.Month <= DistributionOfChildrenFromHIA.Date
	|					AND Jobs.Organization = DistributionOfChildrenFromHIA.Organization
	|				)
	|";
	
	
	
	#EndRegion
	
	#Region TextRBForTransitHIAVariableIndicators
	TextRBForTransitHIAVariableManIndicators = "		
	|		SELECT DISTINCT
	|			//Settings ""textrbpiztransitnyhovzpereferencesupr"",
	|			CostCenters.Organization,
	|			CostCenters.Department,
	|			VALUE(ChartOfCharacteristicTypes.ExpenseItems.EmptyRef),
	|			CostCenters.Ref,
	|			VALUE(Catalog.LinesOfBusiness.EmptyRef),
	// Receipt
	|			0,
	|			0,
	|			0,
	|			0,
	|			0,
	|			0,
	|			0,
	// Expense
	|			0,
	|			0,
	|			0,
	|			0,
	|			0,
	|			0,
	|			0,
	// Balance
	|			0,
	|			0,
	|			0,
	|			0,
	|			0,
	|			0,
	|			0,
	// Balance total
	|			0,
	|			0,
	|			0,
	|			0,
	|			0,
	|			0,
	|			0,
	// without amounts
	|			TRUE AS WithoutManAmounts,
	|			FALSE AS NoLocalAmounts,
	|			FALSE AS WithoutSumsTa,
	|			FALSE AS WithoutDDAmounts,
	|			TRUE
	|		FROM
	|			Document.AllocationOfOtherCosts AS DistributionOfChildrenFromHIA
	|			INNER JOIN InformationRegister.IndicatorValuesForAllocatingExpensesBetweenExpenseObjects AS ValuesForHIA
	|				ON	DistributionOfChildrenFromHIA.Factor = ValuesForHIA.Factor
	|					AND ValuesForHIA.Factor.AllocationBase = VALUE(Enum.TypesOfCostAllocatingBase.VariableEnteredManuallyOnMonthlyBasis)
	|					AND BEGINOFPERIOD(DistributionOfChildrenFromHIA.Date, MONTH) = ValuesForHIA.Period
	|			INNER JOIN Catalog.CostCenters AS CostCenters
	|				ON	CostCenters.Ref = ValuesForHIA.ConstCenter
	|					AND CostCenters.Organization = DistributionOfChildrenFromHIA.Organization
	|					AND CostCenters.CostAllocationOptionManag = VALUE(Enum.CostAllocationOptions.ToDeferredExpenses)
	|			LEFT JOIN Document.DeferredExpensesAllocation AS DeferredExpenseAllocation
	|				ON DeferredExpenseAllocation.Organization = CostCenters.Organization
	|					AND DeferredExpenseAllocation.Department = CostCenters.Department
	|					AND DeferredExpenseAllocation.DimensionOfExpenses = CostCenters.Ref
	|					AND DeferredExpenseAllocation.Posted
	|					AND DeferredExpenseAllocation.ManagementAccounting 
	|					AND CostCenters.CostAllocationOptionManag = VALUE(Enum.CostAllocationOptions.ToDeferredExpenses)
	|					AND BEGINOFPERIOD(DeferredExpenseAllocation.Date, MONTH) = BEGINOFPERIOD(DistributionOfChildrenFromHIA.Date, MONTH)
	|		WHERE
	|			NOT ValuesForHIA.IndicatorValue = 0
	|			AND DistributionOfChildrenFromHIA.Date BETWEEN &BeginOfPeriod AND &EndOfPeriod
	|			AND DistributionOfChildrenFromHIA.ManagementAccounting
	|			AND (&ByAllCompanies OR DistributionOfChildrenFromHIA.Organization = &Organization)
	|			AND (&ByAllCompanies OR CostCenters.Organization = &Organization)
	|			AND (&ByAllBusinessUnits OR CostCenters.Department = &Department)
	|			AND DeferredExpenseAllocation.Ref IS NULL
	|			AND TRUE IN (SELECT TOP 1 TRUE
	|				FROM InformationRegister.JobsForCalculatingCost AS Jobs
	|				WHERE
	|					Jobs.Month <= DistributionOfChildrenFromHIA.Date
	|					AND Jobs.Organization = DistributionOfChildrenFromHIA.Organization
	|				)
	|";
	TextRBForTransitHIAVariableLocalHealthIndicators = "		
	|		SELECT DISTINCT
	|			//Settings of the ""textrbpiztransitnyhovzpereferencesregl"",
	|			CostCenters.Organization,
	|			CostCenters.Department,
	|			VALUE(ChartOfCharacteristicTypes.ExpenseItems.EmptyRef),
	|			CostCenters.Ref,
	|			VALUE(Catalog.LinesOfBusiness.EmptyRef),
	// Receipt
	|			0,
	|			0,
	|			0,
	|			0,
	|			0,
	|			0,
	|			0,
	// Expense
	|			0,
	|			0,
	|			0,
	|			0,
	|			0,
	|			0,
	|			0,
	// Balance
	|			0,
	|			0,
	|			0,
	|			0,
	|			0,
	|			0,
	|			0,
	// Balance total
	|			0,
	|			0,
	|			0,
	|			0,
	|			0,
	|			0,
	|			0,
	// without amounts
	|			FALSE AS WithoutManAmounts,
	|			TRUE AS NoLocalAmounts,
	|			FALSE AS WithoutSumsTa,
	|			FALSE AS WithoutDDAmounts,
	|			TRUE
	|		FROM
	|			Document.AllocationOfOtherCosts AS DistributionOfChildrenFromHIA
	|			INNER JOIN InformationRegister.IndicatorValuesForAllocatingExpensesBetweenExpenseObjects AS ValuesForHIA
	|				ON	DistributionOfChildrenFromHIA.Factor = ValuesForHIA.Factor
	|					AND ValuesForHIA.Factor.AllocationBase = VALUE(Enum.TypesOfCostAllocatingBase.VariableEnteredManuallyOnMonthlyBasis)
	|					AND BEGINOFPERIOD(DistributionOfChildrenFromHIA.Date, MONTH) = ValuesForHIA.Period
	|			INNER JOIN Catalog.CostCenters AS CostCenters
	|				ON	CostCenters.Ref = ValuesForHIA.ConstCenter
	|					AND CostCenters.Organization = DistributionOfChildrenFromHIA.Organization
	|					AND CostCenters.CostAllocationOptionLocal = VALUE(Enum.CostAllocationOptions.ToDeferredExpenses)
	|			LEFT JOIN Document.DeferredExpensesAllocation AS DeferredExpenseAllocation
	|				ON DeferredExpenseAllocation.Organization = CostCenters.Organization
	|					AND DeferredExpenseAllocation.Department = CostCenters.Department
	|					AND DeferredExpenseAllocation.DimensionOfExpenses = CostCenters.Ref
	|					AND DeferredExpenseAllocation.Posted
	|					AND DeferredExpenseAllocation.LocalAccounting 
	|					AND CostCenters.CostAllocationOptionLocal = VALUE(Enum.CostAllocationOptions.ToDeferredExpenses)
	|					AND BEGINOFPERIOD(DeferredExpenseAllocation.Date, MONTH) = BEGINOFPERIOD(DistributionOfChildrenFromHIA.Date, MONTH)
	|		WHERE
	|			NOT ValuesForHIA.IndicatorValue = 0
	|			AND DistributionOfChildrenFromHIA.Date BETWEEN &BeginOfPeriod AND &EndOfPeriod
	|			AND DistributionOfChildrenFromHIA.LocalAccounting
	|			AND (&ByAllCompanies OR DistributionOfChildrenFromHIA.Organization = &Organization) 
	|			AND (&ByAllCompanies OR CostCenters.Organization = &Organization)
	|			AND (&ByAllBusinessUnits OR CostCenters.Department = &Department)
	|			AND DeferredExpenseAllocation.Ref IS NULL
	|			AND TRUE IN (SELECT TOP 1 TRUE
	|				FROM InformationRegister.JobsForCalculatingCost AS Jobs
	|				WHERE
	|					Jobs.Month <= DistributionOfChildrenFromHIA.Date
	|					AND Jobs.Organization = DistributionOfChildrenFromHIA.Organization
	|				)
	|";
	
	
	#EndRegion
	
	QueryTexts = New Array;
	QueryTexts.Add(TextDescriptionOfFields);
	
	QueryTexts.Add(TextOfChangeDeferredExpensed);
	QueryTexts.Add(TextRBPExpenses);
	QueryTexts.Add(TextWriteOffOfMaterialsOfWorksOnRBP);
	QueryTexts.Add(TextIsRollingRemainderOfRBP);
	QueryTexts.Add(TextBalanceOfUnallocatedRBP);
	QueryTexts.Add(TextWriteOffOfExpensesForRBP);
	
	If GetFunctionalOption("UseAccountingByExpenseObjects") Then
		QueryTexts.Add(TextRbpovzParishes);
		QueryTexts.Add(TextWriteOffOfMaterialsOfWorksOnRBPOVZ);
		
		QueryTexts.Add(TextRBForTransitHIAConstantManIndicators);
		QueryTexts.Add(TextRBForTransitHIAVariableManIndicators);

		QueryTexts.Add(TextRBForTransitHIAConstantLocalHealthIndicators);
		QueryTexts.Add(TextRBForTransitHIAVariableLocalHealthIndicators);

	EndIf;
	Return StrConcat(QueryTexts, TMCommonUse.QuerySeparatorInJoin());

EndFunction

// The text of the request for expenses to be allocated.
// 
// Parameters:
//  Top - Boolean - when True, only the first entries are selected
// 
// Returns:
//  String - Text of the request expenses for distribution
Function QueryTextExpenseForAllocation(Top = False) Export
	
	QueryText = 
		"SELECT //**01
		|	Data.Organization AS Organization,
		|	Data.Department AS Department,
		|	Data.LineOfBusiness AS LineOfBusiness,
		|	Data.ExpenseItem AS ExpenseItem,
		|	DataArticle.CostAllocationOptionManag AS CostAllocationOptionManag,
		|	DataArticle.CostAllocationOptionLocal AS CostAllocationOptionLocal,
		|	DataArticle.CostAllocationOptionTax AS CostAllocationOptionTax,
		|	Data.DimensionOfExpenses AS DimensionOfExpenses,
		|	Data.SumBalance + Data.SumReceipt - Data.SumExpense AS Sum,
		|	Data.SumManBalance + Data.SumManReceipt - Data.SumManExpense AS SumMan,
		|	Data.SumComplBalance + Data.SumComplReceipt - Data.SumComplExpense AS SumCompl,
		|	Data.SumComplBalance + Data.SumComplReceipt - Data.SumComplExpense 
		|		- (Data.PermanentDifferenceBalance + Data.PermanentDifferenceReceipt - Data.PermanentDifferenceExpense) 
		|		- (Data.CostTDBalance + Data.CostTDReceipt - Data.CostTDExpense) AS AmountFA,
		|	Data.PermanentDifferenceBalance + Data.PermanentDifferenceReceipt - Data.PermanentDifferenceExpense AS PermanentDifference,
		|	Data.CostTDBalance + Data.CostTDReceipt - Data.CostTDExpense AS CostTD,
		|	Data.AITAmountBalance + Data.AITAmountReceipt - Data.AITAmountExpense AS AITAmount,
		|	CASE 
		|		WHEN DataArticle.CostAllocationOptionManag 
		|			<> VALUE(Enum.CostAllocationOptions.ToDeferredExpenses) THEN 1
		|		WHEN Data.WithoutManAmounts THEN 2
		|		WHEN Data.SumBalance + Data.SumReceipt - Data.SumExpense = 0 THEN 1
		|		ELSE 0
		|	END AS AmountStatus,
		|	CASE 
		|		WHEN DataArticle.CostAllocationOptionManag 
		|			<> VALUE(Enum.CostAllocationOptions.ToDeferredExpenses) THEN 1
		|		WHEN Data.WithoutManAmounts THEN 2
		|		WHEN Data.SumManBalance + Data.SumManReceipt - Data.SumManExpense = 0 THEN 1
		|		ELSE 0
		|	END AS AmountOfUprStatus,
		|	CASE 
		|		WHEN DataArticle.CostAllocationOptionLocal 
		|			<> VALUE(Enum.CostAllocationOptions.ToDeferredExpenses) THEN 1
		|		WHEN Data.NoLocalAmounts THEN 2
		|		WHEN Data.SumComplBalance + Data.SumComplReceipt - Data.SumComplExpense = 0 THEN 1
		|		ELSE 0
		|	END AS AmountReglStatus,
		|	CASE 
		|		WHEN DataArticle.CostAllocationOptionTax 
		|			<> VALUE(Enum.CostAllocationOptions.ToDeferredExpenses) THEN 1
		|		WHEN Data.WithoutSumsTa THEN 2
		|		WHEN Data.SumComplBalance + Data.SumComplReceipt - Data.SumComplExpense 
		|			- (Data.PermanentDifferenceBalance + Data.PermanentDifferenceReceipt - Data.PermanentDifferenceExpense) 
		|			- (Data.CostTDBalance + Data.CostTDReceipt - Data.CostTDExpense) = 0 THEN 1
		|		ELSE 0
		|	END AS AmountAndStatus,
		|
		// For the DeferredExpensing of AIT, the TA distribution option is used.
		|	CASE
		|		WHEN DataArticle.CostAllocationOptionTax 
		|			<> VALUE(Enum.CostAllocationOptions.ToDeferredExpenses) THEN 1
		|		WHEN Data.WithoutNDDAmounts THEN 2
		|		WHEN Data.AITAmountBalance + Data.AITAmountReceipt - Data.AITAmountExpense = 0 THEN 1
		|		ELSE 0
		|	END AS NDDAmountStatus,
		|	Data.WithoutManAmounts AS CalculationOfAutoManAmounts,
		|	Data.NoLocalAmounts AS CalculationOfAutoLocalAmounts,
		|	Data.WithoutSumsTa AS CalculationOfAutoAmountsTa,
		|	Data.WithoutNDDAmounts AS CalculationOfAutoAmountsNDD,
		|	(Data.SumBalance + Data.SumReceipt - Data.SumExpense) <> 0
		|		AND ISNULL(Data.SumBalance, 0) <> 0 AS ThereAreBalancesAmount,
		|	(Data.SumManBalance + Data.SumManReceipt - Data.SumManExpense) <> 0
		|		AND ISNULL(Data.SumManBalance, 0) <> 0 AS ThereAreBalancesAmountMA,
		|	(Data.SumComplBalance + Data.SumComplReceipt - Data.SumComplExpense) <> 0
		|		AND ISNULL(Data.SumComplBalance, 0) <> 0 AS ThereAreBalancesAmountLocal,
		|	(Data.SumComplBalance + Data.SumComplReceipt - Data.SumComplExpense - (Data.PermanentDifferenceBalance + Data.PermanentDifferenceReceipt 
		|		- Data.PermanentDifferenceExpense) - (Data.CostTDBalance + Data.CostTDReceipt - Data.CostTDExpense)) <> 0
		|		AND (ISNULL(Data.SumComplBalance, 0) 
		|			- ISNULL(Data.PermanentDifferenceBalance, 0) 
		|			- ISNULL(Data.CostTDBalance, 0)) <> 0 AS ThereAreBalancesAmountTA,
		|	(Data.AITAmountBalance + Data.AITAmountReceipt - Data.AITAmountExpense) <> 0
		|		AND ISNULL(Data.AITAmountBalance, 0) <> 0 AS ThereAreBalancesAmountNDD,
		|	ISNULL(Data.AmountBalanceTotal, 0) = 0 AS EverythingIsDistributedAmount,
		|	ISNULL(Data.UprAmountBalanceTotal, 0) = 0 AS EverythingIsDistributedAmountMA,
		|	ISNULL(Data.AmountReglBalanceTotal, 0) = 0 AS EverythingIsDistributedAmountLocal,
		|	(ISNULL(Data.AmountReglBalanceTotal, 0) 
		|		- ISNULL(Data.ConstantDifferenceRemainderTotal, 0) 
		|		- ISNULL(Data.TimeDifferenceRemainderTotal, 0)) = 0 AS EverythingIsDistributedSumIsTA,
		|	ISNULL(Data.PersonalIncomeTaxAmountBalanceTotal, 0) = 0 AS EverythingIsDistributedAmountNDD
		|FROM
		|	(SELECT
		|		Data.Organization AS Organization,
		|		Data.Department AS Department,
		|		Data.ExpenseItem AS ExpenseItem,
		|		Data.DimensionOfExpenses AS DimensionOfExpenses,
		|		Data.LineOfBusiness AS LineOfBusiness,
		|		SUM(Data.SumReceipt) AS SumReceipt,
		|		SUM(Data.SumManReceipt) AS SumManReceipt,
		|		SUM(Data.SumComplReceipt) AS SumComplReceipt,
		|		SUM(Data.PermanentDifferenceReceipt) AS PermanentDifferenceReceipt,
		|		SUM(Data.CostTDReceipt) AS CostTDReceipt,
		|		SUM(CASE
		|				WHEN ISNULL(ArticleDetails_1.RecognizedInAITExpenses, TRUE)
		|					THEN Data.AITAmountReceipt
		|				ELSE 0
		|		END) AS AITAmountReceipt,
		|		SUM(Data.SumExpense) AS SumExpense,
		|		SUM(Data.SumManExpense) AS SumManExpense,
		|		SUM(Data.SumComplExpense) AS SumComplExpense,
		|		SUM(Data.PermanentDifferenceExpense) AS PermanentDifferenceExpense,
		|		SUM(Data.CostTDExpense) AS CostTDExpense,
		|		SUM(CASE
		|				WHEN ISNULL(ArticleDetails_1.RecognizedInAITExpenses, TRUE)
		|					THEN Data.AITAmountExpense
		|				ELSE 0
		|		END) AS AITAmountExpense,
		|		SUM(Data.SumBalance) AS SumBalance,
		|		SUM(Data.SumManBalance) AS SumManBalance,
		|		SUM(Data.SumComplBalance) AS SumComplBalance,
		|		SUM(Data.PermanentDifferenceBalance) AS PermanentDifferenceBalance,
		|		SUM(Data.CostTDBalance) AS CostTDBalance,
		|		SUM(CASE
		|				WHEN ISNULL(ArticleDetails_1.RecognizedInAITExpenses, TRUE)
		|					THEN Data.AITAmountBalance
		|				ELSE 0
		|		END) AS AITAmountBalance,
		|		SUM(Data.AmountBalanceTotal) AS AmountBalanceTotal,
		|		SUM(Data.UprAmountBalanceTotal) AS UprAmountBalanceTotal,
		|		SUM(Data.AmountReglBalanceTotal) AS AmountReglBalanceTotal,
		|		SUM(Data.ConstantDifferenceRemainderTotal) AS ConstantDifferenceRemainderTotal,
		|		SUM(Data.TimeDifferenceRemainderTotal) AS TimeDifferenceRemainderTotal,
		|		SUM(CASE
		|				WHEN ISNULL(ArticleDetails_1.RecognizedInAITExpenses, TRUE)
		|					THEN Data.PersonalIncomeTaxAmountBalanceTotal
		|				WHEN TRUE THEN 0
		|				ELSE 0
		|		END) AS PersonalIncomeTaxAmountBalanceTotal,
		|		MAX(Data.WithoutManAmounts) AS WithoutManAmounts,
		|		MAX(Data.NoLocalAmounts) AS NoLocalAmounts,
		|		MAX(Data.WithoutSumsTa) AS WithoutSumsTa,
		|		MAX(Data.WithoutNDDAmounts) AS WithoutNDDAmounts
		|	FROM
		|		&RBPSources AS Data
		|	LEFT JOIN
		|		ChartOfCharacteristicTypes.ExpenseItems AS ArticleDetails_1
		|		ON Data.ExpenseItem = ArticleDetails_1.Ref
		|	
		|	GROUP BY
		|		Data.Organization,
		|		Data.Department,
		|		Data.ExpenseItem,
		|		Data.DimensionOfExpenses,
		|		Data.LineOfBusiness) AS Data
		|LEFT JOIN
		|	ChartOfCharacteristicTypes.ExpenseItems AS DataArticle
		|	ON Data.ExpenseItem = DataArticle.Ref
		|LEFT JOIN Document.DeferredExpensesAllocation AS DistributionOfMan
		|	ON DistributionOfMan.Date BETWEEN &BeginOfPeriod AND &EndOfPeriod
		|	AND DistributionOfMan.ExpenseItem = Data.ExpenseItem
		|	AND DistributionOfMan.Posted
		|	AND DistributionOfMan.ManagementAccounting
		|	AND DistributionOfMan.AmountEntryOptionMan = VALUE(Enum.OptionsOfDEAmountSpecification.DeterminedAutomatically)
		|	AND DistributionOfMan.Organization = Data.Organization
		|	AND DistributionOfMan.Department = Data.Department
		|	AND DistributionOfMan.DimensionOfExpenses = Data.DimensionOfExpenses
		|	AND DistributionOfMan.LineOfBusiness = Data.LineOfBusiness
		|LEFT JOIN Document.DeferredExpensesAllocation AS DistributionOfLocal
		|	ON DistributionOfLocal.Date BETWEEN &BeginOfPeriod AND &EndOfPeriod
		|	AND DistributionOfLocal.ExpenseItem = Data.ExpenseItem
		|	AND DistributionOfLocal.Posted
		|	AND DistributionOfLocal.LocalAccounting
		|	AND DistributionOfLocal.AmountEntryOptionLocal = VALUE(Enum.OptionsOfDEAmountSpecification.DeterminedAutomatically)
		|	AND DistributionOfLocal.Organization = Data.Organization
		|	AND DistributionOfLocal.Department = Data.Department
		|	AND DistributionOfLocal.DimensionOfExpenses = Data.DimensionOfExpenses
		|	AND DistributionOfLocal.LineOfBusiness = Data.LineOfBusiness
		|LEFT JOIN Document.DeferredExpensesAllocation AS TADistribution
		|	ON TADistribution.Date BETWEEN &BeginOfPeriod AND &EndOfPeriod
		|	AND TADistribution.ExpenseItem = Data.ExpenseItem
		|	AND TADistribution.Posted
		|	AND TADistribution.TaxAccounting
		|	AND TADistribution.AmountEntryOptionLocal = VALUE(Enum.OptionsOfDEAmountSpecification.DeterminedAutomatically)
		|	AND TADistribution.Organization = Data.Organization
		|	AND TADistribution.Department = Data.Department
		|	AND TADistribution.DimensionOfExpenses = Data.DimensionOfExpenses
		|	AND TADistribution.LineOfBusiness = Data.LineOfBusiness
		|LEFT JOIN Document.DeferredExpensesAllocation AS DistributionOfPersonalIncomeTax
		|	ON TADistribution.Date BETWEEN &BeginOfPeriod AND &EndOfPeriod
		|	AND TADistribution.ExpenseItem = Data.ExpenseItem
		|	AND TADistribution.Posted
		|	AND TADistribution.AIT
		|	AND TADistribution.AmountEntryOptionLocal = VALUE(Enum.OptionsOfDEAmountSpecification.DeterminedAutomatically)
		|	AND TADistribution.Organization = Data.Organization
		|	AND TADistribution.Department = Data.Department
		|	AND TADistribution.DimensionOfExpenses = Data.DimensionOfExpenses
		|	AND TADistribution.LineOfBusiness = Data.LineOfBusiness
		|LEFT JOIN
		|	Catalog.CostCenters AS HIAData
		|	ON Data.DimensionOfExpenses = HIAData.Ref
		|		AND Data.ExpenseItem = VALUE(ChartOfCharacteristicTypes.ExpenseItems.EmptyRef)
		|WHERE
		|	(Data.SumBalance + Data.SumReceipt - Data.SumExpense <> 0
		|		OR Data.SumManBalance + Data.SumManReceipt - Data.SumManExpense <> 0 
		|		OR Data.WithoutManAmounts) AND DistributionOfMan.Ref IS NULL
		|	OR (Data.SumComplBalance + Data.SumComplReceipt - Data.SumComplExpense <> 0 
		|		OR Data.NoLocalAmounts) AND DistributionOfLocal.Ref IS NULL
		|	OR (Data.SumComplBalance + Data.SumComplReceipt - Data.SumComplExpense 
		|			- (Data.PermanentDifferenceBalance + Data.PermanentDifferenceReceipt - Data.PermanentDifferenceExpense) 
		|			- (Data.CostTDBalance + Data.CostTDReceipt - Data.CostTDExpense) <> 0
		|		OR Data.WithoutSumsTa) AND TADistribution.Ref IS NULL
		|	OR (Data.AITAmountBalance + Data.AITAmountReceipt - Data.AITAmountExpense <> 0 
		|		OR Data.WithoutNDDAmounts) AND DistributionOfPersonalIncomeTax.Ref IS NULL
		|";
	
	QueryText = StrReplace(QueryText, "&RBPSources", "("+RequestTextCostsForDistributionSources()+")");
	QueryText = StrReplace(QueryText, "DataArticle.CostAllocationOptionManag", 
		"ISNULL(DataArticle.CostAllocationOptionManag, HIAData.CostAllocationOptionManag)");
	QueryText = StrReplace(QueryText, "DataArticle.CostAllocationOptionLocal", 
		"ISNULL(DataArticle.CostAllocationOptionLocal, HIAData.CostAllocationOptionLocal)");
	QueryText = StrReplace(QueryText, "DataArticle.CostAllocationOptionTax", 
		"ISNULL(DataArticle.CostAllocationOptionTax, HIAData.CostAllocationOptionTax)");
	If Top Then
		QueryText = StrReplace(QueryText, "//**01", "TOP 1"); //@Query-part
	EndIf;
	
	Return QueryText;
	
EndFunction

#EndRegion

#Region Private

#Region Print

// Fills in the list of print commands.
//
// Parameters:
//   PrintCommands - See PrintManagement.CreatePrintCommandsCollection
//
Procedure AddPrintCommands(PrintCommands) Export
	
	DeferredExpensesAllocationLocalization.AddPrintCommands(PrintCommands);

EndProcedure

#EndRegion

#Region Posting

Function AdditionalDataSourcesForRegisteredRecords(RegisterName) Export

	DataSources = New Map;

	Return DataSources; 

EndFunction

Procedure FillInInitializationParameters(Query, DocumentRef)
	
	Query.TempTablesManager = New TempTablesManager;
	Query.SetParameter("Ref", DocumentRef);
	Query.Text =
	"SELECT
	|	DocumentData.Date AS Period,
	|	DocumentData.Ref AS Ref,
	|	DocumentData.Organization AS Organization,
	|	DocumentData.Number AS Number,
	|	DocumentData.Comment AS Comment,
	|	DocumentData.Posted AS Posted,
	|	DocumentData.DeletionMark AS DeletionMark,
	|	DocumentData.EmployeeResponsible AS EmployeeResponsible,
	|	DocumentData.Department AS Department
	|FROM
	|	Document.DeferredExpensesAllocation AS DocumentData
	|WHERE
	|	DocumentData.Ref = &Ref
	|";
	Result = Query.Execute();
	Attributes = Result.Select();
	Attributes.Next();
	
	For Each Column In Result.Columns Do
		Query.SetParameter(Column.Name, Attributes[Column.Name]);
	EndDo;
	
	Query.SetParameter("MetadataIdentifier", Common.MetadataObjectID("Document.DeferredExpensesAllocation"));
	Query.SetParameter("NumberForPrinting", ObjectsPrefixesClientServer.NumberForPrinting(Attributes.Number));
	Query.SetParameter("HouseholdOperationForRegistry", Enums.BusinessTransactions.DeferredExpenseAllocation);
	Query.SetParameter("Currency", Constants.ManagementAccountingCurrency.Get());

	CostCalculationAppliedAlgorithms.FillInInitializationParameters(Query, Attributes);
	
	// Let's check if there is a date for prohibiting changes by dates in the document lines.
	Query.Text =
	"SELECT DISTINCT
	|	Rows.Date AS Date
	|FROM
	|	Document.DeferredExpensesAllocation.CostAllocation AS Rows
	|WHERE
	|	Rows.Ref = &Ref
	|";
	QueryResult = Query.Execute().Select();
	
	DataBanTemplate = PeriodClosingDates.DataToCheckTemplate();
	TemplateRow = DataBanTemplate.Add();
	TemplateRow.Section = "RoutineOperations";
	DataModificationBanPeriod = Date(1,1,1);
	
	While QueryResult.Next() Do
		TemplateRow.Date = BegOfDay(QueryResult.Date);
		If PeriodClosingDates.PeriodEndClosingFound(DataBanTemplate)
		 And DataModificationBanPeriod < QueryResult.Date Then
			DataModificationBanPeriod = QueryResult.Date;
		EndIf;
	EndDo;
	Query.SetParameter("DataModificationBanPeriod", DataModificationBanPeriod);

EndProcedure

Function QueryTextTableTTInitialOtherExpenses(Query, QueryTexts) Export
	
	RegisterName = "TTInitialOtherExpenses";
	
	QueryTextOfAccountingPolicyForAIT = CalculationOfCostLocalization.AITSettingsQueryText("", "DeferredExpensesAllocation_QueryTextTableTTInitialOtherExpenses");
	QueryTexts.Add(QueryTextOfAccountingPolicyForAIT, RegisterName);
	
	QueryText = "
	|SELECT
	|	Rows.Date                             AS Period,
	|	VALUE(AccumulationRecordType.Expense)  AS RecordType,
	|	DocumentData.Organization             AS Organization,
	|	DocumentData.Department           AS Department,
	|	DocumentData.ExpenseItem          AS ExpenseItem,
	|	DocumentData.DimensionOfExpenses       AS DimensionOfExpenses,
	|	DocumentData.LineOfBusiness AS LineOfBusiness,
	|	UNDEFINED                            AS VATActivityType,
	|	DocumentData.LineOfBusiness AS CorLineOfBusiness,
	|	Rows.Department                    AS DebitBusinessUnit,
	|	Rows.ExpenseItem					AS CorExpenseItem,
	|	Rows.DimensionOfExpenses				AS CorExpenditureDimension,
	|	CASE 
	|		WHEN DocumentData.ManagementAccounting 
	|		THEN SUM(Rows.Sum) ELSE 0
	|	END									AS AmountIncludingVAT,
	|	CASE 
	|		WHEN DocumentData.ManagementAccounting 
	|		THEN SUM(Rows.SumMan) ELSE 0
	|	END									AS AmountExcludingVAT,
	|	CASE 
	|		WHEN DocumentData.ManagementAccounting 
	|		THEN SUM(Rows.SumMan) ELSE 0
	|	END									AS AmountExcludingVATMan,
	|	CASE 
	|		WHEN DocumentData.LocalAccounting 
	|		THEN SUM(Rows.SumCompl) ELSE 0
	|	END									AS AmountIncludingVATCompl,
	|	CASE 
	|		WHEN DocumentData.LocalAccounting 
	|		THEN SUM(Rows.SumCompl) ELSE 0
	|	END									AS AmountExcludingVATCompl,
	|	CASE 
	|		WHEN DocumentData.LocalAccounting AND DocumentData.TaxAccounting OR DocumentData.TaxAccounting
	|		THEN SUM(Rows.PermanentDifference)
	|		WHEN DocumentData.LocalAccounting AND NOT DocumentData.TaxAccounting AND NOT DocumentData.ExpenseItem.EnteredInTaxAccounting
	|		THEN SUM(Rows.SumCompl)
	|		ELSE 0
	|	END									AS PermanentDifference,
	|	CASE 
	|		WHEN DocumentData.LocalAccounting AND DocumentData.TaxAccounting OR DocumentData.TaxAccounting
	|		THEN SUM(Rows.CostTD)
	|		WHEN DocumentData.LocalAccounting AND NOT DocumentData.TaxAccounting AND DocumentData.ExpenseItem.EnteredInTaxAccounting
	|		THEN SUM(Rows.SumCompl)
	|		ELSE 0
	|	END									AS CostTD,
	|	CASE
	|		WHEN DocumentData.AIT AND ISNULL(AITAccountingPolicy.PayerOfAdditionalIncomeTaxFromHydrocarbonProductionAIT, FALSE)
	|			THEN CASE
	|					WHEN DocumentData.ExpenseItem.RecognizedInAITExpenses
	|						THEN SUM(Rows.AITAmount)
	|					ELSE 0
	|				END
	|		ELSE 0
	|	END									AS AITAmount,
	|	VALUE(Enum.BusinessTransactions.DeferredExpenseAllocation) AS BusinessOperation,
	|	UNDEFINED AS ItemsLocationAttributes,
	|	
	|	Rows.RowID                     AS FinRecordID,
	|	VALUE(Catalog.BusinessTransactionsSettings.DeferredExpenseAllocation)  AS BusinessTransactionSetting
	|
	|INTO TTInitialOtherExpenses
	|FROM
	|	Document.DeferredExpensesAllocation AS DocumentData
	|	INNER JOIN Document.DeferredExpensesAllocation.CostAllocation AS Rows
	|		ON DocumentData.Ref = Rows.Ref
	|
	|	LEFT JOIN AITAccountingPolicy AS AITAccountingPolicy
	|	ON DocumentData.Organization = AITAccountingPolicy.Organization
	|
	|WHERE
	|	DocumentData.Ref = &Ref
	|	AND (Rows.Sum <> 0 OR Rows.SumMan <> 0
	|		OR Rows.SumCompl <> 0
	|		OR Rows.PermanentDifference <> 0
	|		OR Rows.CostTD <> 0
	|		OR Rows.AITAmount <> 0
	|		)
	// We form the data on the lines for which there is no prohibition to change the data.
	|	AND Rows.Date > &DataModificationBanPeriod
	|
	|GROUP BY
	|	Rows.Date,
	|	DocumentData.Organization,
	|	DocumentData.Department,
	|	DocumentData.ExpenseItem,
	|	DocumentData.DimensionOfExpenses,
	|	DocumentData.LineOfBusiness,
	|	DocumentData.ManagementAccounting,
	|	DocumentData.LocalAccounting,
	|	DocumentData.TaxAccounting,
	|	DocumentData.AIT,
	|	AITAccountingPolicy.PayerOfAdditionalIncomeTaxFromHydrocarbonProductionAIT,
	|	Rows.RowID, 
	|	Rows.Department,
	|	Rows.ExpenseItem,
	|	Rows.DimensionOfExpenses
	|
	|UNION ALL
	|
	|SELECT
	|	Rows.Date								AS Period,
	|	VALUE(AccumulationRecordType.Receipt)	AS RecordType,
	|	DocumentData.Organization				AS Organization,
	|	Rows.Department                    AS Department,
	|	Rows.ExpenseItem					AS ExpenseItem,
	|	Rows.DimensionOfExpenses				AS DimensionOfExpenses,
	|	DocumentData.LineOfBusiness AS LineOfBusiness,
	|	UNDEFINED                            AS VATActivityType,
	|	DocumentData.LineOfBusiness AS CorLineOfBusiness,
	|	DocumentData.Department           AS DebitBusinessUnit,
	|	DocumentData.ExpenseItem          AS CorExpenseItem,
	|	DocumentData.DimensionOfExpenses       AS CorExpenditureDimension,
	|	CASE 
	|		WHEN DocumentData.ManagementAccounting 
	|		THEN SUM(Rows.Sum) ELSE 0
	|	END									AS AmountIncludingVAT,
	|	CASE 
	|		WHEN DocumentData.ManagementAccounting 
	|		THEN SUM(Rows.SumMan) ELSE 0
	|	END									AS AmountExcludingVAT,
	|	CASE 
	|		WHEN DocumentData.ManagementAccounting 
	|		THEN SUM(Rows.SumMan) ELSE 0
	|	END									AS AmountExcludingVATMan,
	|	CASE 
	|		WHEN DocumentData.LocalAccounting 
	|		THEN SUM(Rows.SumCompl) ELSE 0
	|	END									AS AmountIncludingVATCompl,
	|	CASE 
	|		WHEN DocumentData.LocalAccounting 
	|		THEN SUM(Rows.SumCompl) ELSE 0
	|	END									AS AmountExcludingVATCompl,
	|	CASE 
	|		WHEN DocumentData.LocalAccounting AND DocumentData.TaxAccounting OR DocumentData.TaxAccounting
	|		THEN SUM(Rows.PermanentDifference)
	|		WHEN DocumentData.LocalAccounting AND NOT DocumentData.TaxAccounting 
	|				AND (NOT Rows.ExpenseItem.EnteredInTaxAccounting OR NOT DocumentData.ExpenseItem.EnteredInTaxAccounting)
	|		THEN SUM(Rows.SumCompl)
	|		ELSE 0
	|	END									AS PermanentDifference,
	|	CASE 
	|		WHEN DocumentData.LocalAccounting AND DocumentData.TaxAccounting OR DocumentData.TaxAccounting
	|		THEN SUM(Rows.CostTD)
	|		WHEN DocumentData.LocalAccounting AND NOT DocumentData.TaxAccounting AND Rows.ExpenseItem.EnteredInTaxAccounting
	|				AND Rows.ExpenseItem.EnteredInTaxAccounting AND DocumentData.ExpenseItem.EnteredInTaxAccounting
	|		THEN SUM(Rows.SumCompl)
	|		ELSE 0
	|	END									AS CostTD,
	|	CASE 
	|		WHEN DocumentData.AIT AND ISNULL(AITAccountingPolicy.PayerOfAdditionalIncomeTaxFromHydrocarbonProductionAIT, FALSE)
	|			THEN CASE
	|					WHEN DocumentData.ExpenseItem.RecognizedInAITExpenses
	|						THEN SUM(Rows.AITAmount)
	|					ELSE 0
	|				END
	|		ELSE 0
	|	END									AS AITAmount,
	|	VALUE(Enum.BusinessTransactions.DeferredExpenseAllocation) AS BusinessOperation,
	|	UNDEFINED AS ItemsLocationAttributes,
	|	
	|	Rows.RowID              AS FinRecordID,
	|	VALUE(Catalog.BusinessTransactionsSettings.DeferredExpenseAllocation)  AS BusinessTransactionSetting
	|
	|FROM
	|	Document.DeferredExpensesAllocation.CostAllocation AS Rows
	|	INNER JOIN Document.DeferredExpensesAllocation AS DocumentData
	|		ON DocumentData.Ref = Rows.Ref
	|
	|	LEFT JOIN AITAccountingPolicy AS AITAccountingPolicy
	|	ON DocumentData.Organization = AITAccountingPolicy.Organization
	|
	|WHERE
	|	Rows.Ref = &Ref
	|	AND (Rows.Sum <> 0 OR Rows.SumMan <> 0
	|		OR Rows.SumCompl <> 0
	|		OR Rows.PermanentDifference <> 0
	|		OR Rows.CostTD <> 0
	|		OR Rows.AITAmount <> 0
	|		)
	// We form the data on the lines for which there is no prohibition to change the data.
	|	AND Rows.Date > &DataModificationBanPeriod
	|
	|GROUP BY
	|	Rows.Date,
	|	DocumentData.Organization,
	|	Rows.Department,
	|	Rows.ExpenseItem,
	|	Rows.DimensionOfExpenses,
	|	DocumentData.LineOfBusiness,
	|	DocumentData.ManagementAccounting,
	|	DocumentData.LocalAccounting,
	|	DocumentData.TaxAccounting,
	|	DocumentData.AIT,
	|	AITAccountingPolicy.PayerOfAdditionalIncomeTaxFromHydrocarbonProductionAIT,
	|	Rows.RowID, 
	|	DocumentData.Department,
	|	DocumentData.ExpenseItem,
	|	DocumentData.DimensionOfExpenses
	|
	// For periods with a set date of prohibition of changing traffic data, we take it from the register.
	|UNION ALL
	|SELECT
	|	RegisterRecords.Period,
	|	RegisterRecords.RecordType,
	|	RegisterRecords.Organization,
	|	RegisterRecords.Department,
	|	RegisterRecords.ExpenseItem,
	|	RegisterRecords.DimensionOfExpenses,
	|	RegisterRecords.LineOfBusiness,
	|	UNDEFINED AS VATActivityType,
	|	RegisterRecords.CorLineOfBusiness,
	|	RegisterRecords.DebitBusinessUnit,
	|	RegisterRecords.CorExpenseItem,
	|	RegisterRecords.CorExpenditureDimension,
	|	RegisterRecords.Sum       AS AmountIncludingVAT,
	|	RegisterRecords.AmountExcludingVAT AS AmountExcludingVAT,
	|	RegisterRecords.SumMan    AS AmountExcludingVATMan,
	|	RegisterRecords.SumCompl   AS AmountIncludingVATCompl,
	|	RegisterRecords.SumCompl   AS AmountExcludingVATCompl,
	|	RegisterRecords.PermanentDifference,
	|	RegisterRecords.CostTD,
	|	CASE
	|		WHEN RegisterRecords.ExpenseItem.RecognizedInAITExpenses AND ISNULL(AITAccountingPolicy.PayerOfAdditionalIncomeTaxFromHydrocarbonProductionAIT, FALSE)
	|			THEN RegisterRecords.AITAmount
	|		ELSE 0
	|	END,
	|	RegisterRecords.BusinessOperation,
	|	UNDEFINED AS ItemsLocationAttributes,
	|	
	|	RegisterRecords.FinRecordID,
	|	RegisterRecords.BusinessTransactionSetting
	|FROM
	|	AccumulationRegister.OtherExpenses AS RegisterRecords
	|
	|	LEFT JOIN AITAccountingPolicy AS AITAccountingPolicy
	|	ON RegisterRecords.Organization = AITAccountingPolicy.Organization
	|WHERE
	|	RegisterRecords.Recorder = &Ref
	|	AND RegisterRecords.Period <= &DataModificationBanPeriod
	|	AND NOT RegisterRecords.LotCalculation
	|	AND NOT RegisterRecords.CalculationOfCost
	|";
	
	QueryTexts.Add(QueryText, RegisterName);
	Return QueryText;
EndFunction

Function QueryTextTableTTOtherExpenses_(Query, QueryTexts) Export
	
	RegisterName = "TTOtherExpenses_";
	
	If Not DocumentsPosting.ThereIsQueryTable("TTInitialOtherExpenses", QueryTexts) Then
		QueryTextTableTTInitialOtherExpenses(Query, QueryTexts);
	EndIf;
	
	AdditionalFields = "CorLineOfBusiness,DebitBusinessUnit,CorExpenseItem,CorExpenditureDimension";
	CalculationOfCostLocalization.AddAdditionalFieldsByAIT(AdditionalFields);
	
	QueryText = AccumulationRegisters.OtherExpenses.QueryTextTableTTOtherExpenses_(AdditionalFields);
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
	
	AdditionalFields = "CorLineOfBusiness,DebitBusinessUnit,CorExpenseItem,CorExpenditureDimension";
	CalculationOfCostLocalization.AddAdditionalFieldsByAIT(AdditionalFields);
	
	QueryText = AccumulationRegisters.OtherExpenses.QueryTextTableOtherExpenses(AdditionalFields);
	QueryTexts.Add(QueryText, RegisterName);
	Return QueryText;
	
EndFunction

Function QueryTextTableTTInitialBatchesOfOtherExpenses(Query, QueryTexts)
	
	RegisterName = "TTInitialBatchesOfOtherExpenses";
	
	QueryText = "
	|SELECT
	|	Rows.Date                             AS Period,
	|	VALUE(AccumulationRecordType.Receipt)  AS RecordType,
	|	Rows.Ref.Organization               AS Organization,
	|	CASE
	|		WHEN Rows.Department <> VALUE(Catalog.BusinessStructure.EmptyRef)
	|			THEN Rows.Department
	|		ELSE Rows.Ref.Department
	|	END                                   AS Department,
	|	&Ref                                 AS ExpenseReceiptDocument,
	|	Rows.ExpenseItem                   AS ExpenseItem,
	|	Rows.DimensionOfExpenses                AS DimensionOfExpenses,
	|	UNDEFINED                            AS AssetsLiabilitiesDimension,
	|	UNDEFINED                            AS LotVendorAttributes,
	|	DocumentData.LineOfBusiness AS LineOfBusiness,
	|	UNDEFINED                            AS ItemsLocationAttributes,
	|	UNDEFINED                            AS VATActivityType,
	|	
	|	Rows.Sum                            AS Cost,
	|	Rows.SumMan                         AS CostExcludingVAT,
	|	0                                       AS VATManag,
	|	Rows.SumCompl                        AS LocalCost,
	|	Rows.PermanentDifference                AS PermanentDifference,
	|	Rows.CostTD                 AS CostTD,
	|	0                                       AS VATLocal,
	|	VALUE(Enum.BusinessTransactions.DeferredExpenseAllocation) AS BusinessOperation,
	|	
	|	Rows.RowID              AS FinRecordID,
	|	VALUE(Catalog.BusinessTransactionsSettings.DeferredExpenseAllocation)  AS BusinessTransactionSetting
	|
	|INTO TTInitialBatchesOfOtherExpenses
	|FROM
	|	Document.DeferredExpensesAllocation.CostAllocation AS Rows
	|	INNER JOIN Document.DeferredExpensesAllocation AS DocumentData
	|		ON DocumentData.Ref = Rows.Ref
	|WHERE
	|	Rows.Ref = &Ref
	|	AND (Rows.Sum <> 0 OR Rows.SumMan <> 0
	|		OR Rows.SumCompl <> 0
	|		OR Rows.PermanentDifference <> 0
	|		OR Rows.CostTD <> 0)
	|";
	
	QueryTexts.Add(QueryText, RegisterName);
	Return QueryText;
EndFunction

Function QueryTextTableTTLotsOfOtherExpenses(Query, QueryTexts) Export
	
	RegisterName = "TTLotsOfOtherExpenses";
	
	If Not DocumentsPosting.ThereIsQueryTable("TTInitialBatchesOfOtherExpenses", QueryTexts) Then
		QueryTextTableTTInitialBatchesOfOtherExpenses(Query, QueryTexts);
	EndIf;
	
	QueryText = AccumulationRegisters.ItemisedExpensesLots.QueryTextTableTTLotsOfOtherExpenses();
	QueryTexts.Add(QueryText, RegisterName);
	Return QueryText;
	
EndFunction

Function QueryTextTableItemisedExpensesLots(Query, QueryTexts, Registers)
	
	RegisterName = "ItemisedExpensesLots";
	
	If Not DocumentsPosting.RequiresTableForRegisteredRecords(RegisterName, Registers) Then
		Return "";
	EndIf;
	
	If Not DocumentsPosting.ThereIsQueryTable("TTLotsOfOtherExpenses", QueryTexts) Then
		QueryTextTableTTLotsOfOtherExpenses(Query, QueryTexts);
	EndIf;
	
	QueryText = AccumulationRegisters.ItemisedExpensesLots.QueryTextTableItemisedExpensesLots();
	QueryTexts.Add(QueryText, RegisterName);
	Return QueryText;
	
EndFunction

Function QueryTextRecordsIncomeExpensesOtherAssetsLiabilities(Query, QueryTexts, Registers)

	RegisterName = "RecordsIncomeExpensesOtherAssetsLiabilities";
	
	If Not DocumentsPosting.RequiresTableForRegisteredRecords(RegisterName, Registers) Then
		Return "";
	EndIf; 
	
	QueryText = "
	|SELECT
	|	Rows.LineNumber,
	|	Rows.Date AS Period,
	|	VALUE(Enum.BusinessTransactions.DeferredExpenseAllocation) AS BusinessOperation,
	|	DocumentData.Organization AS Organization,
	|	DocumentData.Department AS Department,
	|	DocumentData.ExpenseItem AS AssetRef,
	|	DocumentData.DimensionOfExpenses AS DimensionOfExpenses,
	|
	|	Rows.Department AS DebitBusinessUnit,
	|	Rows.ExpenseItem AS CorItem,
	|	Rows.DimensionOfExpenses AS CorExpenditureDimension,
	|
	|	DocumentData.LineOfBusiness AS LineOfBusiness,
	|	DocumentData.LineOfBusiness AS CorLineOfBusiness,
	|
	|	Rows.Sum AS Sum,
	|	CASE
	|		WHEN DocumentData.ExpenseItem.CostAllocationOptionManag = VALUE(Enum.CostAllocationOptions.ToInventoryCost)
	|		 OR NOT &CompanyManagementAccounting
	|			THEN 0
	|		ELSE
	|			Rows.SumMan
	|	END AS SumMan,
	|	Rows.SumCompl AS SumCompl,
	|
	|	&Currency AS Currency,
	|	Rows.Sum AS AmountInCurrency
	|
	|FROM
	|	Document.DeferredExpensesAllocation AS DocumentData
	|	INNER JOIN Document.DeferredExpensesAllocation.CostAllocation AS Rows
	|		ON Rows.Ref = DocumentData.Ref
	|WHERE
	|	DocumentData.Ref = &Ref
	|	AND (Rows.Sum <> 0 OR Rows.SumMan <> 0 OR Rows.SumCompl <> 0)
	|
	|ORDER BY
	|	LineNumber
	|";
	
	QueryTexts.Add(QueryText, RegisterName);
	
	Return QueryText;
	
EndFunction

Function QueryTextTableOtherAssetsLiabilities(Query, QueryTexts, Registers)
	
	RegisterName = "OtherAssetsLiabilities";
	
	If Not DocumentsPosting.RequiresTableForRegisteredRecords(RegisterName, Registers) Then
		Return "";
	EndIf;
	
	If Not DocumentsPosting.ThereIsQueryTable("TTOtherExpenses_", QueryTexts) Then
		QueryTextTableTTOtherExpenses_(Query, QueryTexts);
	EndIf;
	
	If Not DocumentsPosting.ThereIsQueryTable("TTLotsOfOtherExpenses", QueryTexts) Then
		QueryTextTableTTLotsOfOtherExpenses(Query, QueryTexts);
	EndIf;
	
	QueryText = AccumulationRegisters.OtherAssetsLiabilities.QueryTextTableOtherAssetsLiabilities();
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
	|	&Department AS Department,
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
	
	FullDocumentName = "Document.DeferredExpensesAllocation";
	ParameterValues = New Structure;
	ParameterValues.Insert("MetadataIdentifier", Common.MetadataObjectID("Document.DeferredExpensesAllocation"));
	ParameterValues.Insert("HouseholdOperationForRegistry", Enums.BusinessTransactions.DeferredExpenseAllocation);
	
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

#Region InfobaseUpdate

// See InfobaseUpdateSSL.OnAddUpdateHandlers
Procedure OnAddUpdateHandlers(Handlers) Export

#Region Documents_AllocationOfExpensesForFuturePeriods_ProcessDataToSwitchToNewVersion

	Handler = Handlers.Add();
	Handler.Procedure = "Documents.DeferredExpensesAllocation.ProcessDataForMigrationToNewVersion";
	Handler.Version = "11.5.7.228";
	Handler.ExecutionMode = "Deferred";
	Handler.Id = New UUID("173afe82-319c-4c13-91f4-d2ca087cdc11");
	Handler.Multithreaded = True;
	Handler.UpdateDataFillingProcedure = "Documents.DeferredExpensesAllocation.RegisterDataToProcessForMigrationToNewVersion";
	Handler.CheckProcedure = "InfobaseUpdate.DataUpdatedForNewApplicationVersion";
	Handler.Comment = NStr("vi = 'Điền trường ""Tên định danh của dòng"" trong phần bảng.';
							|ru = 'Заполняет поле ""Идентификатор строки"" в табличных частях.';
							|en = 'Populates ""Line ID"" field in tables.'; fa = 'Populates ""Line ID"" field in tables.';
							|it = 'Compila il campo ""ID riga"" nelle parti tabellari.';
							|pl = 'Wypełnia pole ""Identyfikator wiersza"" w sekcjach tabelarycznych.';
							|tr = 'Tablo bölümlerindeki ""Satır tanımlayıcı"" alanını doldurur.'");
	
	ItemsToRead = New Array;
	ItemsToRead.Add(Metadata.ChartsOfCharacteristicTypes.ExpenseItems.FullName());
	ItemsToRead.Add(Metadata.Documents.DeferredExpensesAllocation.FullName());
	Handler.ObjectsToRead = StrConcat(ItemsToRead, ",");
	
	Editable1 = New Array;
	Editable1.Add(Metadata.Documents.DeferredExpensesAllocation.FullName());
	Handler.ObjectsToChange = StrConcat(Editable1, ",");

#EndRegion

EndProcedure

// Parameters:
// 	Parameters - See InfobaseUpdate.MainProcessingMarkParameters
//
Procedure RegisterDataToProcessForMigrationToNewVersion(Parameters) Export
	
	SelectionParameters = Parameters.SelectionParameters;
	SelectionParameters.FullNamesOfObjects = EmptyRef().Metadata().FullName();
	SelectionParameters.OrderingFieldsOnUserOperations.Add("DATE DESC");
	SelectionParameters.OrderingFieldsOnProcessData.Add("DATE DESC");
	SelectionParameters.SelectionMethod = InfobaseUpdate.RefsSelectionMethod();
	
	Query = New Query;
	Query.Text =
	"SELECT
	|	Document.Ref AS Ref
	|FROM
	|	Document.DeferredExpensesAllocation AS Document
	|WHERE
	|	TRUE IN
	|		(SELECT TOP 1
	|			TRUE
	|		FROM
	|			Document.DeferredExpensesAllocation.CostAllocation AS TabPart
	|		WHERE
	|			TabPart.Ref = Document.Ref
	|			AND TabPart.RowID = """")
	|			
	|UNION
	|
	|SELECT
	|	Document.Ref AS Ref
	|FROM
	|	Document.DeferredExpensesAllocation AS Document
	|WHERE
	|	Document.Posted
	|		AND NOT Document.ManagementAccounting
	|		AND NOT Document.LocalAccounting
	|		AND NOT Document.TaxAccounting
	|			
	|UNION
	|
	|SELECT
	|	Document.Ref AS Ref
	|FROM
	|	Document.DeferredExpensesAllocation AS Document
	|INNER JOIN ChartOfCharacteristicTypes.ExpenseItems AS ARTICLES__
	|	ON ARTICLES__.Ref = Document.ExpenseItem
	|	
	|WHERE
	|	Document.Posted
	|		AND Document.LocalAccounting
	|		AND NOT Document.TaxAccounting
	|		AND ARTICLES__.CostAllocationOptionTax = VALUE(Enum.CostAllocationOptions.ToDeferredExpenses)";
	
	InfobaseUpdate.MarkForProcessing(Parameters, Query.Execute().Unload().UnloadColumn("Ref"));
	
EndProcedure

Procedure ProcessDataForMigrationToNewVersion(Parameters) Export
	
	FullObjectName = EmptyRef().Metadata().FullName();
	UpdatedData = InfobaseUpdate.DataToUpdateInMultithreadHandler(Parameters);
	
	If UpdatedData.Count() = 0 Then
		Parameters.ProcessingCompleted = InfobaseUpdate.DataProcessingCompleted(Parameters.Queue, FullObjectName);
		Return;
	EndIf;
	
	Query = New Query();
	Query.Text = "SELECT 
	|	ARTICLES__.Ref AS ExpenseItem,
	|	ARTICLES__.CostAllocationOptionManag = VALUE(Enum.CostAllocationOptions.ToDeferredExpenses) AS ManagementAccounting,
	|	ARTICLES__.CostAllocationOptionLocal = VALUE(Enum.CostAllocationOptions.ToDeferredExpenses) AS LocalAccounting,
	|	ARTICLES__.CostAllocationOptionTax = VALUE(Enum.CostAllocationOptions.ToDeferredExpenses) AS TaxAccounting
	|FROM ChartOfCharacteristicTypes.ExpenseItems AS ARTICLES__
	|WHERE
	|	ARTICLES__.CostAllocationOptionManag = VALUE(Enum.CostAllocationOptions.ToDeferredExpenses)
	|	OR ARTICLES__.CostAllocationOptionLocal = VALUE(Enum.CostAllocationOptions.ToDeferredExpenses)
	|	OR ARTICLES__.CostAllocationOptionTax = VALUE(Enum.CostAllocationOptions.ToDeferredExpenses)
	|";
	Selection = Query.Execute().Select();
	ArticlesSettings = New Map();
	While Selection.Next() Do
		ArticlesSettings.Insert(Selection.ExpenseItem, New Structure("ManagementAccounting,LocalAccounting,TaxAccounting", 
			Selection.ManagementAccounting, Selection.LocalAccounting, Selection.TaxAccounting));
	EndDo;
	
	For Each Document In UpdatedData Do
		
		BeginTransaction();
		
		Try
			Ref = Document.Ref;
			Block = New DataLock;
			
			LockItem = Block.Add(FullObjectName);
			LockItem.SetValue("Ref", Ref);
			LockItem.Mode = DataLockMode.Exclusive;
			
			Block.Lock();
			
			DocumentObject = Ref.GetObject();
			
			If DocumentObject <> Undefined Then
				TMCommonUse.FillInDocumentIDs(DocumentObject, "CostAllocation");
				SettingUpArticle = ArticlesSettings.Get(DocumentObject.ExpenseItem);
				If Not SettingUpArticle = Undefined Then
					If Not DocumentObject.ManagementAccounting And Not DocumentObject.LocalAccounting And Not DocumentObject.TaxAccounting Then
						DocumentObject.ManagementAccounting = SettingUpArticle.ManagementAccounting;
						DocumentObject.LocalAccounting = SettingUpArticle.LocalAccounting;
						DocumentObject.TaxAccounting = SettingUpArticle.TaxAccounting;
					EndIf;
					If SettingUpArticle.TaxAccounting And DocumentObject.LocalAccounting And Not DocumentObject.TaxAccounting Then
						DocumentObject.TaxAccounting = SettingUpArticle.TaxAccounting;
					EndIf;
				EndIf;
			EndIf;
			
			If DocumentObject <> Undefined And DocumentObject.Modified() Then
				InfobaseUpdate.WriteData(DocumentObject);
			Else
				InfobaseUpdate.MarkProcessingCompletion(Ref);
			EndIf;
			
			CommitTransaction();
			
		Except
			
			RollbackTransaction();
			InfobaseUpdateTM.ReportFailedProcessing(ErrorInfo(), Document.Ref);
			
		EndTry;
		
	EndDo;
	
	Parameters.ProcessingCompleted = InfobaseUpdate.DataProcessingCompleted(Parameters.Queue, FullObjectName);

EndProcedure

#EndRegion

#Region CreatingHyperlinkInProductionLog

Function CreateHyperlinkToDesign(Parameters) Export
	
	If Not AccessRight("Update", Metadata.Documents.DeferredExpensesAllocation) Then
		Return Undefined;
	EndIf;
	
	Query = New Query;
	Query.Text = QueryTextExpenseForAllocation(True);
	
	LBeginningOfPeriod = ?(ValueIsFilled(Parameters.Period), BegOfMonth(Parameters.Period), BegOfMonth(CurrentSessionDate()));
	LEndOfPeriod = ?(ValueIsFilled(Parameters.Period), EndOfMonth(Parameters.Period), EndOfMonth(CurrentSessionDate()));
	
	Query.SetParameter("BeginOfPeriod", LBeginningOfPeriod);
	Query.SetParameter("EndOfPeriod", LEndOfPeriod);
	Query.SetParameter("Organization", Parameters.Organization);
	Query.SetParameter("ByAllCompanies", Not ValueIsFilled(Parameters.Organization));
	Query.SetParameter("Department", Parameters.Department);
	Query.SetParameter("ByAllBusinessUnits", Not ValueIsFilled(Parameters.Department));
	
	HyperlinkText = NStr("vi = 'Phân bổ chi phí trả trước';
						|ru = 'Распределение расходов будущих периодов';
						|en = 'Deferred expense allocation'; fa = 'تسهیم هزینه‌های معوق';
						|it = 'Ripartizione spese dei riscontri attivi';
						|pl = 'Podział wydatków przyszłych okresów';
						|tr = 'Ertelenmiş giderler tahsisi'");
	
	SetPrivilegedMode(True);
	If Query.Execute().IsEmpty() Then
		Return New FormattedString(HyperlinkText,,StyleColors.EmptyTableField,,
			"Document.DeferredExpensesAllocation.Form.DocumentsListForm");
	Else
		Return New FormattedString(HyperlinkText,,,,
			"Document.DeferredExpensesAllocation.Form.DocumentsListForm");
	EndIf;
	
EndFunction

#EndRegion

#EndRegion

#EndIf
