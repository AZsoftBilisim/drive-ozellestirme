
#Region Public

// Performs a localized calculation of the cost.
//
// Parameters:
//	CalculationPeriod - Date - start of the period (month) before which the calculation should be performed
//	CompanyArray - Array - the organization, which is necessary to perform the calculation.
//	ClosingMonthIsInProgress - Boolean - flag for performing routine operations at the end of the month 
//	AutoTesting - Boolean - flag for performing automatic cost testing
//
// Returns:
//	Boolean - a sign of the implementation of a localized cost calculation.
//
Function CalculateEverything(Val CalculationPeriod, CompanyArray, ClosingMonthIsInProgress, AutoTesting) Export
	LocalizedCalculationIsPerformed = False;
	Return LocalizedCalculationIsPerformed;
EndFunction

// Updating the cost of goods by a routine task.
//
// Parameters:
//	Period - Date - starting date for the calculation.
//	
// Returns:
//	Boolean - a sign of the implementation of a localized cost calculation.
//
Function PreliminaryCostCalculation(Period = Undefined) Export
	LocalizedCalculationIsPerformed = False;
	Return LocalizedCalculationIsPerformed;
EndFunction

#Region CalculationStages

// The challenge procedures of localized cost.
//
// Parameters:
//	CalculationParameters - Structure - parameters of month closing operations.
//	
// Returns:
//	Boolean - a sign of the implementation of localized cost calculation
//
Function CalculateCost(CalculationParameters) Export
	LocalizedCalculationIsPerformed = False;
	Return LocalizedCalculationIsPerformed;
EndFunction

// Calling the material cost allocation procedures in the localized version.
//
// Parameters:
//	CalculationParameters - Structure - Operation options the end of the month
//
Procedure DistributionOfMaterialCosts(CalculationParameters) Export
	If CalculationParameters.MonthEndClosingMode = Enums.MonthEndClosingModes.PreliminaryClosing Then
		Return;
	EndIf;
	Return;
EndProcedure

// Calling VAT batch distribution procedures in the localized version.
//
// Parameters:
//	CalculationParameters - Structure - Operation options the end of the month
//	CalculationSchemeLine - ValueTableRow - String calculation of the parties
//	StageNumber - Number - The phase distribution of the parties ' VAT
//
Procedure DistributionOfVATLots(CalculationParameters, CalculationSchemeLine, StageNumber) Export
	
	If CalculationParameters.MonthEndClosingMode = Enums.MonthEndClosingModes.PreliminaryClosing Then
		
		Return;
		
	EndIf;
	
	If StageNumber = 1 Then
		
		
		// Step 11.1.2
		// Generates a temp table for the details of the product partyreferencesexternal links
		VATCostCalculation.PreparationOfDataForAccountingLBSiUSN_AdditionalExpensesAmount(CalculationParameters);
		
		// Stage 11.3
		// Generates movements by registers:
		// - Details of the cost of the part of the goods
		// - Details of the cost of the product partyreferences
		// - Details of the cost of the goods and the cost of the cost
		VATCostCalculation.DistributionOfPartiesNdsfifoMoving(CalculationParameters);
		
		// Generates temporary tables:
		// - VT is spent for the same amount of costs
		// Generates movements by registers:
		// - Details of the cost of the product partyreferences
		VATCostCalculation.DistributionOfVATLotsAccordingToAdditionalExpenseAmounts(CalculationParameters);
		
	ElsIf StageNumber = 2 Then
		
		
		// Stage 12.1
		// Generates movements by registers:
		// - Lots of other expenses
		// - Other expenses
		VATCostCalculation.PreparationOfDataForBatchesOfOtherExpenses(CalculationParameters);
		
	EndIf;

	Return;
EndProcedure

#EndRegion

#Region Initialize

// Initializes General calculation parameters that describe registers served by the calculation engine.
//
// Parameters:
//	CalculationParameters - Structure - cost calculation parameters
//	
Procedure InitializeMaintainedRegisters(CalculationParameters) Export
	
	
EndProcedure

// Adds to the list of documents that may have movements in different months or for several organizations.
//
// Parameters:
//	DifferentPeriods_ - Boolean - add documents with movements in different periods to the result
//	DifferentOrganizations - Boolean - add documents with movements for several organizations to the result
//	RegisterName - String - name of the accumulation register to get a list of documents for;
//		empty value - list of documents for all registers.
//	DescriptionOfDocuments - Map - The key is the Metadata object.
//
Procedure SupplementDocumentsWithDifferentPeriodsOrOrganizationsInRegisteredRecords(DifferentPeriods_, DifferentOrganizations, RegisterName, DescriptionOfDocuments) Export
	
EndProcedure

// Creates shared temporary tables for selecting data in queries.
//
Procedure InitializeTemporaryTablesForSelections(CalculationParameters) Export
EndProcedure

#EndRegion

#EndRegion

#Region Private

#Region StageProcedures_DistributionOfLaborCosts

// Distribution of labor costs between the "boilers" of production.
//
Procedure DistributionOfLaborCosts(CalculationParameters) Export
	
	If CalculationParameters.MonthEndClosingMode = Enums.MonthEndClosingModes.PreliminaryClosing Then
		Return;
	EndIf;
	
	
EndProcedure

// Consumption of labor from the "boilers" for production.
//
Procedure DistributionOfLaborCostsForGraduation(CalculationParameters) Export
	
	If CalculationParameters.MonthEndClosingMode = Enums.MonthEndClosingModes.PreliminaryClosing Then
		Return;
	EndIf;
	
	
EndProcedure


#Region FillingInSettlementBatchLaborCosts

Procedure FillInEstimatedBatchDistributionOfLaborCosts(CalculationParameters, SettlementBatch, Expense, Receipt) Export
	
	
EndProcedure

Procedure FillInEstimatedBatchDistributionOfLaborCostsForRelease(CalculationParameters, SettlementBatch, Expense, Receipt) Export
	
	
EndProcedure

#EndRegion

#EndRegion

#Region StepProcedures_1_2_3_4_5

Procedure SupplementRequestWithDataOnLaborCosts(QueryText) Export
EndProcedure

#EndRegion

#Region StageProcedures_FillingInLotsInRegisterCostOfGoods

Function RequestTextForBatchesOfGoods() Export
	
	QueryText = ""
		+ "";
	Return QueryText;	
	
EndFunction

#EndRegion

#Region ProceduresOfStep10_AllocationOfAdditionalCostsBetweenBatchesAndGoods

Function TextCustomsDeclarationsAndReceipts() Export // tue Declarations, the number of declarations
	QueryText = "
		|SELECT DISTINCT
		|	UNDEFINED AS Ref,
		|	UNDEFINED AS Inpayment
		|INTO
		|	Declarations
		|;
		|SELECT
		|	UNDEFINED AS Inpayment,
		|	1 AS Count
		|INTO
		|	NumberOfDeclarations
		|";
	Return QueryText;
EndFunction

#EndRegion

#Region ProceduresOfStep15_DistributionOfSharesOfProductionCosts

// Adds localized actual material costs to the query array.
// Parameters:
//	QueriesTexts - Array - contains the texts of the queries.
//
Procedure SupplementRequestWithActualMaterialCosts(QueriesTexts) Export
	
	
EndProcedure

// Adds localized preliminary material costs to the query array.
// Parameters:
//	QueriesTexts - Array - contains the texts of the queries.
//
Procedure SupplementRequestWithPreliminaryMaterialCosts(QueriesTexts) Export
	
	
EndProcedure

// Adds localized preliminary material costs to the query array.
// Parameters:
//	QueriesTexts - Array - contains the texts of the queries.
//
Procedure SupplementRequestWithDatabasesForDistributionOfSharesByStages(QueriesTexts) Export
	
	
EndProcedure

#EndRegion

#Region ProceduresOfStage16_DistributionOfSharesOfProductionCosts

// Complements the query array with localized material costs in work-in-progress.
// Parameters:
//	QueriesTexts - Array - contains the texts of the queries.
//
Procedure SupplementRequestWithMaterialCostsOfUnfinishedProduction(QueriesTexts) Export
	
	
EndProcedure

// Adds localized work in progress to the query array.
// Parameters:
//	QueriesTexts - Array - contains the texts of the queries.
//
Procedure SupplementRequestWithUnfinishedProductionLaborCosts(QueriesTexts) Export
	
	
EndProcedure

// Complements the query array with localized released products.
// Parameters:
//	QueriesTexts - Array - contains the texts of the queries.
//
Procedure SupplementRequestWithReleasedProducts(QueriesTexts) Export
	
	
EndProcedure

Function AddServiceTablesToQuery() Export
	
	Return "";

EndFunction


// Complements the query texts.
// 
// Parameters:
// 	QueriesTexts - Array -
//
Procedure SupplementRequestWithRestOfDistributionBases(QueriesTexts) Export
	
	
EndProcedure

Procedure AddLocalizedDataToRequestForUnfinishedProductionExpenses(QueriesTexts) Export
	
	
EndProcedure

#EndRegion

#Region StageProcedures_Contextual

// Used for all calls to fill in the billing batch.
//
Procedure FillInSettlementBatch(CalculationParameters, Context, SettlementBatch, Expense, Receipt, BatchIsFull) Export
	
	If BatchIsFull Then
		Return;
	EndIf;
	
	
EndProcedure

#EndRegion

#Region IncludeExcludeNDSVCost

Procedure IncludeExcludeNDSVCost(CalculationParameters, OnlyArticleByArticle = False) Export
	
	
	If CalculationParameters.BatchAccountingVersion22 And Not OnlyArticleByArticle
	 And CostCalculationAppliedAlgorithms.TemporaryTableExists(CalculationParameters, "TTAdditionalCostsForItemByItemCosts") Then
		VATCostCalculation.PreparationOfDataForInclusionExclusionOfVATAdditionalExpensesInCost24(CalculationParameters);
	EndIf;
	
EndProcedure

Procedure IncludeExcludeNDSVCostOfSales(CalculationParameters) Export
	
	
EndProcedure

#EndRegion
#Region RoutineOperations

Function PerformRoutineOperation(CalculationParameters) Export
	Cancel = False;
	Return Not Cancel;
		
EndFunction

#EndRegion
#Region RestorationsOfRegisteredRecords

Function RestoreMovementOfDocumentsInAccumulationRegister(Recorder) Export
	RestorationOfRegisteredRecordsIsPerformed = False;
	Return RestorationOfRegisteredRecordsIsPerformed;
EndFunction

// Complements the array of types of accounting documents for OS and IA.
// These types of documents have "non-standard" mechanics for conducting other income and expense registers.
//
// Parameters:
//	TypesOfLoggers - Array - Array of document types
//
Procedure SupplementTypesOfDocumentsOnSiIa(TypesOfLoggers) Export
EndProcedure

#EndRegion

#Region UniversalProceduresForDescribingMechanismData

// Returns a list of metadata objects that are used for batch calculation.
// The list does not include items that are both the source data of the batch and cost calculation mechanisms.
//
// Parameters:
//	IncomingData - Map - already initialized storage for the description of the incoming data
//	OnlyRequiringRecalculation - Boolean - if it is set, the list will be returned only for those data
//		whose change entails the need to recalculate batches and costs
//		When you change this data, an entry must be created in the data register of the Taskcountercountercountercountercountercountercountercountercountercounter.
//
Procedure IncomingMechanismData(IncomingData, OnlyRequiringRecalculation) Export
	

EndProcedure

// Returns a list of registers served by the batch calculation engine.
//
// Parameters:
//	OutgoingData - Map - the names of the registers that are serviced by the solver of the parties.
//
Procedure OutgoingMechanismData(OutgoingData) Export
	
	If CalculationOfCostCached.BatchAccountingVersion22() Then
		OutgoingData.Insert(Metadata.InformationRegisters.ItemizeGoodsCostItemizedAndOtherCosts, True);
		OutgoingData.Insert(Metadata.InformationRegisters.ItemizeGoodsLotCost,        			  True);
		OutgoingData.Insert(Metadata.InformationRegisters.ItemizeLotCostItemizedAndOtherCosts, True);
	Else
	EndIf;
	
EndProcedure

// Returns a list of registers calculated by the batch accounting engine version 2.2 and used for calculating the cost price.
//
Procedure UsedCachesOfBatchAccountingRegisters(IncomingData) Export
	
	// Listed here are the registers, which (S)
	// - calculated mechanism batch accounting version 2.2
	// - not calculated by the solver cost
	// - data are input to the solver cost (use the data caches registers)
	//
	// In case, if you separate startup cost (not from a batch accounting version 2.2),
	// these registers are not initialized to their caches can not handle.
	//
	// To do this, the following is done:
	// - before starting the cost calculation, these registers are "forcibly" initialized (in order to form their calculation caches)
	// - before recording movements, these registers are removed from the calculation parameters (it is not necessary to record them - movements on them were not formed)
	
	
EndProcedure

#EndRegion

#Region AdjustmentSoftwareInterface

// Supplements the list of accumulation registers for which adjustments are provided.
//
// Parameters:
//	RegistersWithAdjustments - Array - array of register metadata names with adjustments
//
Procedure SupplementRegistersWithAdjustmentsToInitialBalances(RegistersWithAdjustments) Export
	RegistersWithAdjustments.Add(Metadata.InformationRegisters.ItemizeGoodsCostItemizedAndOtherCosts.FullName());
	RegistersWithAdjustments.Add(Metadata.InformationRegisters.ItemizeGoodsLotCost.FullName());
	RegistersWithAdjustments.Add(Metadata.InformationRegisters.ItemizeLotCostItemizedAndOtherCosts.FullName());
EndProcedure

// Completes the description of the changes of registers of accumulation.
//
// Parameters:
//	TableOfTypesOfAdjustments - ValueTable - table with the description of adjustments of registers
//
Procedure CompleteDescriptionOfAdjustmentsToInitialBalances(TableOfTypesOfAdjustments) Export
EndProcedure

#EndRegion

#Region CostAccounting_

// Adds to the list of registers that are not used when cost accounting is disabled.
//
// Parameters:
//	ListOfRegisters - Map - a list of registers that are not used when cost accounting is disabled.
//
Procedure AddRegistersThatAreNotUsedWhenCostAccountingIsDisabled(ListOfRegisters) Export
EndProcedure

#EndRegion

#Region Testing

Procedure SupplementStagesWithDistributionOfBatches(StageList) Export
	
	
EndProcedure

Procedure AddStagesWithBatchTranslation(StageList) Export
	
	
	
EndProcedure

Procedure RequestTextForStageCalculation(StageName_, CalculationParameters, QueryText) Export
	
	VATCostCalculation.RequestTextForStageCalculation(StageName_, CalculationParameters, QueryText);

	
	
EndProcedure

// Completes the list of calculation stages.
// 
// Parameters:
// 	StageList - ValueList of String - 
Procedure ComplementStepsWithDataPreparationForFollowingSteps(StageList) Export
	
	
	Return; // so that the method is not empty without the personal data.
	
EndProcedure

#EndRegion

#Region WritingRegisterRecords

// Called before recording of the generated movements.
//
Procedure BeforeRecordingGeneratedRegisteredRecords(CalculationParameters) Export
	
	
EndProcedure

// Records generated new movements.
//
Procedure RecordGeneratedRegisteredRecords(CalculationParameters) Export
	
	If Not ValueIsFilled(CalculationParameters.SamplingRestrictions.NumberOfGnzRecords) Then
		// For debugging - calculation without changing the IB data
		Return;
	EndIf;
	
	ControlRegisters_ = New Array;
	
	VATCostCalculation.CreateTasksForVATAccountingMechanismsBatchAccounting22(CalculationParameters);
	
	SupplementControlRegistersWithAITRegisters(ControlRegisters_);
	
	
	ControlRegisters_ = CommonClientServer.CollapseArray(ControlRegisters_);
	If ControlRegisters_.Count() = 0 Then
		Return;
	EndIf;
	
	If CalculationParameters.CalculationOption <> Enums.LotAndCostCalculationOptions.LotsAndCost Then
		Return;
	EndIf;
		
	Query = New Query;
	QueryTexts = New Array;
	CostCalculationAppliedAlgorithms.InitializeRequestProperties(Query, CalculationParameters);
	
	For Each RegisterOfControl In ControlRegisters_ Do
		
		RegisterData = Undefined;
		CalculationParameters.RegisterRecords.Property(RegisterOfControl, RegisterData);
		If RegisterData = Undefined Or Not RegisterData.ThereIsChangedData Then
			Continue;
		EndIf;
		
		QueryText = QueryTextForChangesToRecordedData(RegisterData);
		QueryTexts.Add(QueryText);
		
	EndDo;
	
	If QueryTexts.Count() = 0 Then
		Return;
	EndIf;
	
	Query.Text = StrConcat(QueryTexts, Common.QueryBatchSeparator());
	CostCalculationAppliedAlgorithms.ExecuteRequestWithMeasurementForProtocol(CalculationParameters, Query);
	
	GenerateAITTaskRegisterEntries(Query.TempTablesManager);
	
EndProcedure


// The text of the query with the changed motion to the reflection in international accounting.
//
// Returns:
//	String - Query text
//
Function QueryTextTTDocumentsToBeReflectedLocalization() Export
	QueryText = "";
	Return QueryText;
EndFunction

Function QueryTextForChangesToRecordedData(RegisterData)
	
	RegisterMetadata = RegisterData.RegisterMetadata; // MetadataObjectAccumulationRegister
	
	Filter = New Structure;
	AdditionalParameters = Testing.AdditionalParametersForFormingComparisonRequest();
	AdditionalParameters.SelectionConditionsAfter = "Records.Period BETWEEN &BeginOfPeriod AND &EndOfPeriod
	|		AND Records.Active AND NOT Records.ReversingEntry
	|		AND Records.Organization IN(&CompanyArray)";
	AdditionalParameters.ExcludedFields.Insert("Active");
	// We will use as a basis a ready-made method that compares the Register Records when writing registers:
	QueriesTexts = MonthEndTransactionsServer.QueryTextsForCaseChangeTable(RegisterMetadata, Filter, AdditionalParameters);
	// We are interested in the last query where the comparison takes place, only we will remove from it the part with the destruction of the temporary table:
	QueriesTexts = StrSplit(QueriesTexts.SampleTextOfChangeTable, ";");
	QueryText = QueriesTexts.Get(0);
	// We do not have initial records (instead, access to register data is used), however, we have calculated data, we will use them when comparing:
	QueryText = StrReplace(QueryText, "InitialEntries" + RegisterMetadata.Name, RegisterData.NameOfCalculatedRegisterRevolutionsTable);
	// Instead of the standard "Type of movement", the "Service type of movement" field is used, let's return to the standard one:
	OverrideText = "CASE WHEN InitialEntries.OfficialTypeOfMovementParish THEN VALUE(AccumulationRecordType.Receipt) ELSE VALUE(AccumulationRecordType.Expense) END";
	QueryText = StrReplace(QueryText, "InitialEntries.RecordType", OverrideText);
	
	Return QueryText;
	
EndFunction

#EndRegion

#Region CachingRegisterData

// Add the names of the registers in the array.
//
// Parameters:
//	Registers - Structure - names of registers with data conversion records
//
Procedure AddRegistersWithDataConversionRecords(Registers) Export
	
	
EndProcedure

#EndRegion

#Region JobsForCalculatingCost

// Adds descriptions of registers for connecting them to the no-change date mechanism.
//
Procedure DescriptionOfRegistersForControlOfDatesOfProhibitionOfChange(DataSources) Export
	
	
EndProcedure

#EndRegion

#Region DocumentAmountsInAccountingCurrency

// Returns the structure of batch registers for which you want to update movements based on settlement data.
//
// Returns:
//	Structure - names of batch registers
//
Function PartyRegisters_() Export
	
	PartyRegisters = New Structure();
	Return PartyRegisters;
	
EndFunction

#EndRegion

#Region HandlersForMonthClosingStages

Procedure Usage_BatchAndCostCalculation(HandlerParameters) Export
	
	
EndProcedure

#EndRegion

#Region BatchAccountingModes

// Determines whether batch accounting version 2.2 is used on the specified date.
//
// Parameters:
//	Date - Date - date for which it is necessary to determine the mode of batch accounting.
//
// Returns:
//	Boolean - indication of the use of batch accounting version 2.2 on the specified date
//	If the date is not specified, then the fact of using batch accounting version 2.2 is determined.
//
Function BatchAccountingVersion22(Date) Export
	
	EnabledBatchAccountingVersion22 = True;
	Return EnabledBatchAccountingVersion22;
	
EndFunction

// Defines the" old " batch accounting mode, before switching to batch accounting version 2.2.
//
// Parameters:
//	Date - Date - date for which it is necessary to determine the mode of batch accounting.
//
// Returns:
//	Boolean, Undefined - indication of the use of batch accounting on the specified date
// 		If the Date parameter is not passed, or the Date is in the period of validity of the batch accounting version 2.2,
//		the value is returned Undefined - there is no point in such a check.
//
Function BatchAccountingWasUsedBeforeSwitchingToVersion22(Date) Export
	
	BatchAccountingWasIncluded = Undefined;
	Return BatchAccountingWasIncluded;
	
EndFunction

// Returns the date of switching to batch accounting version 2.2.
// the date may be empty , which means that batch accounting version 2.2 is enabled for all periods.
//
// Returns:
//	Date - the beginning of the month of transition to batch accounting version 2.2.
//
Function DateOfMigrationToBatchAccounting22() Export
	
	DateOfMigrationToBatchAccounting22 = Date(1,1,1);
	Return DateOfMigrationToBatchAccounting22;
	
EndFunction

#EndRegion

#Region CompanyManagementAccounting

// Determines whether management accounting for organizations is enabled on the specified date.
//
// Parameters:
//	Date - Date - the date for which you need to define the management accounting of organizations.
//
// Returns:
//	Boolean - indication of the use of management accounting of organizations on the specified date
//	If the date is not specified, then the fact of inclusion of batch accounting of organizations is determined.
//
Function CompanyManagementAccounting(Date) Export
	
	ManagementAccountingOfOrganizationsIsIncluded = True;
	Return ManagementAccountingOfOrganizationsIsIncluded;
	
EndFunction

// Returns the start date of management accounting for organizations.
// The date can be empty , which means that management accounting for organizations is enabled for all periods.
//
// Returns:
//	Date - the beginning of the month of management accounting of organizations
//
Function StartDateOfManagementAccountingOfOrganizations() Export
	
	StartDateOfManagementAccountingOfOrganizations = Date(1,1,1);
	Return StartDateOfManagementAccountingOfOrganizations;
	
EndFunction

#EndRegion

#Region Reports

// Supplements the text of the request for the report "List of goods by lot" with data for batch accounting 2.1.
//
// Parameters:
//	QueryText - String - Source text of the request
//
Procedure StatementOnLotsOfGoods_AddRequestText(QueryText) Export
EndProcedure

// Generates the query text for the report "cost Analysis of manufactured products" to get material costs.
//
// Returns:
//	String - Query text
//
Function AnalysisOfCostOfProduction_RequestText_() Export
EndFunction

#EndRegion

#Region AIT

#Region AllocationOfOtherCosts

// The text of the Balance of other expenses AIT.
// 
// Returns:
//  String - Query text
Function TextBalancesOfOtherExpensesAIT() Export
	
	QueryText = "
	|	SELECT TOP 0
	|		//Settings for ""textostatkiproch expenses"",
	|		VALUE(Catalog.Companies.EmptyRef),
	|		VALUE(Catalog.BusinessStructure.EmptyRef),
	|		VALUE(Catalog.LinesOfBusiness.EmptyRef),
	|		VALUE(ChartOfCharacteristicTypes.ExpenseItems.EmptyRef),
	|		UNDEFINED,
	|		0,
	|		0,
	|		0,
	|		0,
	|		0,
	|		0,
	|		0,
	|		0,
	|		0,
	|		0,
	|		0,
	|		0 AS EstimatedQuantity,
	|		FALSE AS EstimatedAmount,
	|		VALUE(Catalog.LinesOfBusiness.EmptyRef),
	|		VALUE(ChartOfCharacteristicTypes.ExpenseItems.EmptyRef)
	|";
	
	
	Return QueryText;
	
EndFunction

// Text Balances of other expenses CO AIT.
// 
// Returns:
//  String - Query text
Function TextBalancesOfOtherExpensesOfInternalRevenueService() Export
	
	QueryText = "
	|	SELECT TOP 0
	|		//Settings for ""textostatkiproch expenditures"" AS A requestsource,
	|		VALUE(Catalog.Companies.EmptyRef) AS Organization,
	|		VALUE(Catalog.BusinessStructure.EmptyRef) AS Department,
	|		VALUE(Catalog.LinesOfBusiness.EmptyRef)  AS LineOfBusiness,
	|		VALUE(ChartOfCharacteristicTypes.ExpenseItems.EmptyRef) AS ExpenseItem,
	|		UNDEFINED AS DimensionOfExpenses,
	|		0 AS Sum,
	|		0 AS AmountExcludingVAT,
	|		0 AS SumCompl,
	|		0 AS PermanentDifference,
	|		0 AS CostTD,
	|		0 AS AITAmount,
	|		0 AS SumMan,
	|		0 AS SumComplExpense,
	|		0 AS PermanentDifferenceExpense,
	|		0 AS CostTDExpense,
	|		0 AS AITAmountExpense,
	|		0 AS EstimatedQuantity,
	|		FALSE AS EstimatedAmount,
	|		VALUE(Catalog.LinesOfBusiness.EmptyRef) AS DirectionOfActivityForCommunication,
	|		VALUE(ChartOfCharacteristicTypes.ExpenseItems.EmptyRef) AS ItemOfExpenditureForCommunication
	|";
	
	
	Return QueryText;
	
EndFunction

// AIT text of the Registered Records of other expenses from CO.
// 
// Returns:
//  String - Query text
Function TextOfRegisteredRecordsOfOtherExpensesFromAIT() Export
	
	QueryText = "
	|	SELECT TOP 0
	|		//Settings for ""textmovementsprochem spending"" AS A requestersource,
	|		VALUE(Catalog.Companies.EmptyRef) AS Organization,
	|		VALUE(Catalog.BusinessStructure.EmptyRef) AS Department,
	|		VALUE(Catalog.LinesOfBusiness.EmptyRef)  AS LineOfBusiness,
	|		VALUE(ChartOfCharacteristicTypes.ExpenseItems.EmptyRef) AS ExpenseItem,
	|		UNDEFINED AS DimensionOfExpenses,
	|		0 AS Sum,
	|		0 AS AmountExcludingVAT,
	|		0 AS SumCompl,
	|		0 AS PermanentDifference,
	|		0 AS CostTD,
	|		0 AS AITAmount,
	|		0 AS SumMan,
	|		0 AS SumComplExpense,
	|		0 AS PermanentDifferenceExpense,
	|		0 AS CostTDExpense,
	|		0 AS AITAmountExpense,
	|		0 AS EstimatedQuantity,
	|		FALSE AS EstimatedAmount,
	|		VALUE(Catalog.LinesOfBusiness.EmptyRef) AS DirectionOfActivityForCommunication,
	|		VALUE(ChartOfCharacteristicTypes.ExpenseItems.EmptyRef) AS ItemOfExpenditureForCommunication
	|	
	|";
	
	
	Return QueryText;
	
EndFunction

// Text transit of expenses between CO according to AIT column.
// 
// Returns:
//  String - Query text
Function TextTransitOfExpensesBetweenCostCenterByColumnAIT() Export
	
	QueryText = "
	|	SELECT TOP 0
	|		//Settings for ""texttranslationspendings between the"" AS A requestersource,
	|		VALUE(Catalog.Companies.EmptyRef) AS Organization,
	|		VALUE(Catalog.BusinessStructure.EmptyRef) AS Department,
	|		VALUE(Catalog.LinesOfBusiness.EmptyRef)  AS LineOfBusiness,
	|		VALUE(ChartOfCharacteristicTypes.ExpenseItems.EmptyRef) AS ExpenseItem,
	|		UNDEFINED AS DimensionOfExpenses,
	|		0 AS Sum,
	|		0 AS AmountExcludingVAT,
	|		0 AS SumCompl,
	|		0 AS PermanentDifference,
	|		0 AS CostTD,
	|		0 AS AITAmount,
	|		0 AS SumMan,
	|		0 AS SumComplExpense,
	|		0 AS PermanentDifferenceExpense,
	|		0 AS CostTDExpense,
	|		0 AS AITAmountExpense,
	|		0 AS EstimatedQuantity,
	|		FALSE AS EstimatedAmount,
	|		VALUE(Catalog.LinesOfBusiness.EmptyRef) AS DirectionOfActivityForCommunication,
	|		VALUE(ChartOfCharacteristicTypes.ExpenseItems.EmptyRef) AS ItemOfExpenditureForCommunication
	|	
	|";
	
	
	Return QueryText;
	
EndFunction

// The Query Text of the article for distribution in AIT.
// 
// Returns:
//  String - Query text 
Function QueryTextOfArticleForAITDistribution() Export
	
	QueryText = 
		"SELECT TOP 0
		|	VALUE(ChartOfCharacteristicTypes.ExpenseItems.EmptyRef) AS Ref,
		|	FALSE AS Predefined,
		|	VALUE(Enum.CostAllocationOptions.EmptyRef) AS CostAllocationOption
		|INTO ItemsOfExpensesForAITDistribution
		|FROM
		|	ChartOfCharacteristicTypes.ExpenseItems AS Attributes
		|";
	
	
	Return QueryText;
	
EndFunction

// The Query Text of the CO for distribution in AIT.
// 
// Returns:
//  String - Query text 
Function AITTextOfCostCentersToForDistribution() Export
	
	QueryText = 
		"SELECT TOP 0
		|	Attributes.ConstCenter AS ConstCenter
		|
		|INTO CostCentersToAITDistribution
		|FROM
		|	TTOvz AS Attributes
		|
		|INDEX BY
		|	ConstCenter
		|";
	
	
	Return QueryText;
	
EndFunction

// Get the distribution settings for the document.
// 
// Parameters:
//  DocumentDistributions - DocumentObject.AllocationOfOtherCosts - Other cost allocation document
//  OnOvz - Boolean - Indication of distribution to CO
// 
// Returns:
//  Undefined, Structure - Get Distribution Settings For A Document:
// * AITCostAllocationOption - EnumRef.CostAllocationOptions - Cost allocation option for AIT
// * CostAllocationRuleAIT - CatalogRef.CostAllocationRules - The cost allocation rule for AIT
Function GetDistributionSettingsForDocument(DocumentDistributions, OnOvz) Export
	
	Settings = Undefined;
	
	
	Return Settings;
	
EndFunction

#EndRegion

#Region OtherExpenses

// Modification of the Query Text to form a table for writing to the "Other inputs" register.
// 
// Parameters:
//  QueryText - String - Query text
//  TableName - String - Name of the main query table
//  AdditionalFields - String -  Additional fields separated by commas
//  DifferentPeriodsInRegisteredRecordsArePossible - Boolean - specifies where the batch accounting parameters are stored, in the query parameters or in the temporary table vtparametersparty accounting for processing
// 
// Returns:
//  String - Query text
Function ChangeQueryTextOtherExpenses(QueryText, TableName, AdditionalFields = "", DifferentPeriodsInRegisteredRecordsArePossible = False) Export
	
	DefaultValues = True;
	If DefaultValues Then
		QueryText = StrReplace(QueryText, "&ConditionAmountAIT", "FALSE"); //@Query-part
		QueryText = StrReplace(QueryText, "&AITAmount",  "0"); //@Query-part
	Else
	EndIf;
	
	Return QueryText;
	
EndFunction

#EndRegion

#Region CostAdjustment

// Change the text of the amount of other expenses.
// 
// Parameters:
//  QueryText - String - Query text
//  CalculationParameters - Structure - Calculation parameters
// 
// Returns:
//  String - QueryText
Function ChangeTextOfAmountOfOtherExpenses(QueryText, CalculationParameters = Undefined) Export
	
	DefaultValues = True;
	If DefaultValues Then
		QueryText = StrReplace(QueryText, "&AITAmount", "0");
	Else
	EndIf;
	
	Return QueryText;
	
EndFunction

#EndRegion

#Region ProceduresOfStage_theFormationOfRegisteredRecordsForAITActualExpenses

// It generates Register Records for AIT's actual expenses according to the cost of goods and labor costs of Unfinished production.
// Called at the stage See CostCalculationCostAdjustment.GenerateRegisteredRecordsByRegisters 
// .
// 
// Parameters:
//  CalculationParameters - Structure - The calculation parameters.
Procedure ToFormRegisterRecordsOfActualExpensesOfLBDpoCostOfGoodsAndLaborCostsOfUnfinishedProduction(CalculationParameters) Export
	
	
	Return; // so that the method is not empty without the personal data.
	
EndProcedure

// Generates Register Records for AIT's actual expenses for other expenses.
// Called at the stage See CostCalculationCostAdjustment.GenerateRegisteredRecordsByRegistersFinancialResult 
// .
// 
// Parameters:
//  CalculationParameters - Structure - The calculation parameters.
Procedure GenerateRegisterRecordsForActualExpensesLBDpoAndOtherExpenses(CalculationParameters) Export
	
	
	Return; // so that the method is not empty without the personal data.
	
EndProcedure

#EndRegion

#Region AITAccounting

// The Query Text of AIT settings.
// Returns queries with different data sets depending on the parameters.
// 
// Parameters:
//  TempTableName - String - The name of the temporary table with data on other expenses.
//  CallSource - String - Description of the call source.
//  CalculationParameters - Structure - The calculation parameters.
//  DifferentPeriodsInRegisteredRecordsArePossible - Boolean - specifies where the batch accounting parameters are stored, in the query parameters or in the temporary table vtparametersparty accounting for processing
// 
// Returns:
//  String - The Query Text for AIT article distribution settings.
Function AITSettingsQueryText(TempTableName, CallSource, CalculationParameters = Undefined, DifferentPeriodsInRegisteredRecordsArePossible = False) Export
	
	DefaultValues = True;
	
	// When adding a new call source, it is necessary to check the methods:
	// - See InitializeAITDataAcquisitionParameters
	// - See ChangeSetOfParametersForRequestingAITSettingsForDocuments
	// and, if necessary, add new conditions to them.
	ParametersForAITDataAcquisition = InitializeAITDataAcquisitionParameters(TempTableName, CallSource);
	
	If DefaultValues Then
		QueryText = TextDescriptionOfTheseAITSettings(ParametersForAITDataAcquisition, CallSource);
		
		SubstituteAITTypeOfSeparateAccountingObjectInRequest(QueryText, "Expenses");
		ChangeSetOfParametersForRequestingAITSettingsForDocuments(QueryText, CallSource);
	Else
	EndIf;
	
	Return QueryText; // String
	
EndFunction

// Initialize AIT data acquisition parameters.
// 
// Parameters:
//  NameOfTemporarySourceTable - String - Name Of The Temporary Source Table
//  CallSource - String - Call Source
// 
// Returns:
//  Structure - Initialize AIT Data Acquisition Parameters:
// * NameOfTemporarySourceTable - String - I have tables with data on expenses
// * NeedTableCostCenter - Boolean - The need for additional TT for CO
// * AccountingPolicyOnly - Boolean - The need to obtain only basic settings of the FO and tax settings
// * RecognitionSettingsOnly - Boolean -  The need to obtain only the basic recognition settings (the fact of accounting for AIT by analysts)
// * RecognitionSettingsForItemAccountingAnalyticsKeys - Boolean -  The need to get recognition settings in the context of item accounting analytics keys
// * SubstitutingArticleSettingsForCostCentersForDistribution - Boolean - The need to replace the options and rules from the articles with data on CO HIA
// * AllocationRules - Boolean - The need to obtain distribution rules
// * DestructibleTT - String - List of TT for destruction
Function InitializeAITDataAcquisitionParameters(NameOfTemporarySourceTable, CallSource) Export
	
	ParametersForAITDataAcquisition = New Structure;
	ParametersForAITDataAcquisition.Insert("NameOfTemporarySourceTable",	NameOfTemporarySourceTable); // name of the table with expenditure data
	ParametersForAITDataAcquisition.Insert("NeedTableCostCenter",				False); // The need for additional TT for CO
	ParametersForAITDataAcquisition.Insert("AccountingPolicyOnly",			False); // The need to obtain only basic AIT accounting settings (FO and taxation settings)
	ParametersForAITDataAcquisition.Insert("RecognitionSettingsOnly",		False); // The need to obtain only the basic recognition settings (the fact of accounting for AIT by analysts)
	ParametersForAITDataAcquisition.Insert("RecognitionSettingsForItemAccountingAnalyticsKeys",	False); // The need to get recognition settings in the context of item accounting analytics keys
	ParametersForAITDataAcquisition.Insert("SubstitutingArticleSettingsForCostCentersForDistribution",			False); // The need to replace the options and rules from the articles with data on CO HIA. Only to document the distribution of other costs
	ParametersForAITDataAcquisition.Insert("AllocationRules",			False); // The need to obtain distribution rules
	ParametersForAITDataAcquisition.Insert("DestructibleTT",				""); // The list of TT to destroy at the end of the main request
	ParametersForAITDataAcquisition.Insert("ItemOfExpenditureForCommunication",		"ItemOfExpenditureForCommunication"); // The name of the Attribute of the expenditure item for the analysis of CO-related expenses
	
	DestructibleTT = New Array; // Array of String
	DestructibleTT.Add("AITAccountingPolicy");
	DestructibleTT.Add("ObjectsOfSeparateAccountingAITByOrganizations");
	DestructibleTT.Add("AITExpenseRecognitionSettingsArePreliminary");
	DestructibleTT.Add("AITExpenseRecognitionSettings");
	DestructibleTT.Add("PreliminarySettingsForDistributionOfAITArticles");
	
	// See Documents.AllocationOfOtherCosts.QueryTextReceivedOtherExpenses
	If CallSource = "DistributionOfOtherExpenses_QueryTextReceivedOtherExpenses" Then
		
		ParametersForAITDataAcquisition.SubstitutingArticleSettingsForCostCentersForDistribution	= True;
		ParametersForAITDataAcquisition.AllocationRules			= True;
		ParametersForAITDataAcquisition.NeedTableCostCenter				= True;
		
	// See CostCalculationCostAdjustment.TextTTWorkInProgress
	ElsIf CallSource = "CostCalculationCostAdjustment_TextTTWorkInProgress" 
		// See ChangeTextOfAmountOfOtherExpenses
		Or CallSource = "ChangeTextOfAmountOfOtherExpenses" Then
		
		ParametersForAITDataAcquisition.NeedTableCostCenter				= True;
		
	// See AccumulationRegisters.OtherExpenses.QueryTextTableOtherExpenses
	ElsIf CallSource = "OtherExpenses_QueryTextTableOtherExpenses"
		// See CostCalculationItemizedCosts.TextMovementArrivalOfDeviationsInValueOtherExpenses
		Or CallSource = "CostCalculationItemByItemExpenses_TextRegisteredRecordedReceiptOfDeviationsInCostOtherExpenses"
		// See the documents.Reflection of the payment in financial accounting.The text of the request for the table of labor costnotesperfect production
		Or CallSource = "SalaryReflectionInFinancialAccounting_QueryTextTableWIPLaborCosts"
		// See Documents.OtherIncomeExpenses.QueryTextTTDataCosts
		Or CallSource = "OtherIncomeExpenses_QueryTextTTTheseExpenses"
		// See Documents.DeferredExpensesAllocation.QueryTextTableTTInitialOtherExpenses
		Or CallSource = "DeferredExpensesAllocation_QueryTextTableTTInitialOtherExpenses"
		// See Documents.OBEntryOtherExpenses.QueryTextTTDataCosts
		Or CallSource = "EnteringBalancesOtherExpenses_QueryTextTTTheseExpenses" Then
		
		ParametersForAITDataAcquisition.AccountingPolicyOnly			= True;
		
		DestructibleTT = New Array; // Array of String
		
	// See CostCalculationCostAdjustment.AdjustInventoryWriteOffCosts
	ElsIf CallSource = "QueryTextForSolvingCostOfAIT"
		// See CostCalculationItemizedCosts.TextBaseOfDistributionOfSharesByStages
		Or CallSource = "CostCalculationItemByItemExpenses_TextBaseOfDistributionOfSharesByStages"
		// See CostCalculationLaborCosts.TextOfRequestForDistributionOfLaborCostsForIssue
		Or CallSource = "CalculationOfCostOfLaborCosts_QueryTextForDistributionOfLaborCostsForIssue"
		// See CostCalculationItemizedCosts.CalculationOfHIATransits
		Or CallSource = "CostCalculationItemByItemExpenses_TransitCalculationCostCenters"
		// See AITTextOfCostCentersToForDistribution
		Or CallSource = "AITTextOfCostCentersToForDistribution"
		// See Documents.RecyclableWasteAllocation.QueryTextTableTTInitialOtherExpenses
		Or CallSource = "DistributionOfReturnableWaste_QueryTextTTTableInitialOtherExpenses"
		// See CostCalculationAppliedAlgorithms.OrganizationsWithCostRegisteredRecords
		Or CallSource = "QueryTextOrganizationsWithCostRegisteredRecords" Then
		
		ParametersForAITDataAcquisition.RecognitionSettingsOnly		= True;
		
		DestructibleTT = New Array; // Array of String
		DestructibleTT.Add("AITAccountingPolicy");
		DestructibleTT.Add("ObjectsOfSeparateAccountingAITByOrganizations");
		DestructibleTT.Add("AITExpenseRecognitionSettingsArePreliminary");
		 
	ElsIf CallSource = "CalculationOfCostOfCarryingOutDocuments_AddQueryTextOfAITRecognitionSettings"
		// See the text of the request for the resolution of the service_stoymostndd
		Or CallSource = "CostCalculationCostAdjustment_AdjustCostOfWriteOffOfInventories" Then
		
		ParametersForAITDataAcquisition.RecognitionSettingsOnly		= True;
		ParametersForAITDataAcquisition.RecognitionSettingsForItemAccountingAnalyticsKeys = True;
		
		DestructibleTT = New Array; // Array of String
		DestructibleTT.Add("AITAccountingPolicy");
		DestructibleTT.Add("ObjectsOfSeparateAccountingAITByOrganizations");
		DestructibleTT.Add("AITExpenseRecognitionSettingsArePreliminary");
		DestructibleTT.Add("ObjectsOfSeparateAccountingAITForItemAccountingAnalytics");
	
	ElsIf CallSource = "QueryTextPreparationOfDataForDistributionOfActualExpensesLBDpoCostOfGoodsAndLaborCostsOfUnfinishedProduction" Then
		
		ParametersForAITDataAcquisition.RecognitionSettingsOnly		= True;
		ParametersForAITDataAcquisition.RecognitionSettingsForItemAccountingAnalyticsKeys = True;
		
		// In this option, you need to save the TT settings for recognizing the SDD expenses
		CommonClientServer.DeleteAllValueOccurrencesFromArray(
			DestructibleTT, "AITExpenseRecognitionSettings");
		
	// See CostCalculationAppliedAlgorithms.InitializeAuxiliaryTemporaryTables
	ElsIf  CallSource = "CostCalculationAppliedAlgorithms_InitializeAuxiliaryTemporaryTables" Then
		
		ParametersForAITDataAcquisition.RecognitionSettingsOnly		= True;
		
		// You need to save all the created TT.
		DestructibleTT = New Array; // Array of String
		
	// See the text of the request for the preparation of data for the distribution of actual expenditures to actual expenditures
	ElsIf CallSource = "QueryTextPreparationOfDataForDistributionOfActualExpensesOfLBDpoToOtherExpenses" Then
		
		ParametersForAITDataAcquisition.RecognitionSettingsOnly		= True;
		
		// In this option, you need to save the TT settings for recognizing the SDD expenses
		DestructibleTT = New Array; // Array of String
		DestructibleTT.Add("AITAccountingPolicy");
		DestructibleTT.Add("ObjectsOfSeparateAccountingAITByOrganizations");
		DestructibleTT.Add("AITExpenseRecognitionSettingsArePreliminary");
		DestructibleTT.Add("ObjectsOfSeparateAccountingAITForItemAccountingAnalytics");
		
	// See CostCalculationItemizedCosts.BatchTextForAttributingExpenses
	ElsIf CallSource = "CostCalculationItemByItemExpenses_BatchTextForAttributionOfExpenses" Then
		
		ParametersForAITDataAcquisition.NeedTableCostCenter				= True;
		
		// In this option, you need to save the TT settings for recognizing the SDD expenses
		CommonClientServer.DeleteAllValueOccurrencesFromArray(
			DestructibleTT, "AITExpenseRecognitionSettings");
	
	// See GetDistributionSettingsForDocument
	ElsIf CallSource = "GetDistributionSettingsForDocument" Then
		ParametersForAITDataAcquisition.AllocationRules			= True;
	// See Documents.AllocationOfOtherCosts.GetCostItemAllocationSettings
	ElsIf CallSource = "DistributionOfOtherExpenses_GetSettingsForDistributionOfItemsOfExpenses" Then
		ParametersForAITDataAcquisition.AllocationRules			= True;
		ParametersForAITDataAcquisition.NeedTableCostCenter				= True;
		ParametersForAITDataAcquisition.SubstitutingArticleSettingsForCostCentersForDistribution	= True;
		ParametersForAITDataAcquisition.ItemOfExpenditureForCommunication		= "ExpenseItem";
	Else
		// Default settings are used
	EndIf;
	
	If ParametersForAITDataAcquisition.NeedTableCostCenter Then
		DestructibleTT.Add("PreliminarySettingsForCostCentersAITDistribution");
	EndIf;
	ListOfDestroyedTT = StrConcat(DestructibleTT, ",");
	ParametersForAITDataAcquisition.DestructibleTT = ListOfDestroyedTT;
	
	Return ParametersForAITDataAcquisition;
	
EndFunction

// Change the set of parameters for AIT settings request.
// By default, the parameters are set for the month closing mechanisms, but if the call is for documents, then you need to replace the parameters.
// 
// Parameters:
//  QueryText - String - Query text
//  CallSource - String - Call Source
// 
// Returns:
//  String - Change the set of parameters for AIT settings request
Function ChangeSetOfParametersForRequestingAITSettingsForDocuments(QueryText, CallSource = "") Export
	
	// See AccumulationRegisters.OtherExpenses.QueryTextTableOtherExpenses
	If CallSource = "OtherExpenses_QueryTextTableOtherExpenses"
		Or CallSource = "CalculationOfCostOfCarryingOutDocuments_AddQueryTextOfAITRecognitionSettings"
		// See Documents.AllocationOfOtherCosts.GetCostItemAllocationSettings
		Or CallSource = "DistributionOfOtherExpenses_GetSettingsForDistributionOfItemsOfExpenses"
		// See the documents.Reflection of the payment in financial accounting.The text of the request for the table of labor costnotesperfect production
		Or CallSource = "SalaryReflectionInFinancialAccounting_QueryTextTableWIPLaborCosts"
		// See Documents.OtherIncomeExpenses.QueryTextTTDataCosts
		Or CallSource = "OtherIncomeExpenses_QueryTextTTTheseExpenses"
		// See Documents.DeferredExpensesAllocation.QueryTextTableTTInitialOtherExpenses
		Or CallSource = "DeferredExpensesAllocation_QueryTextTableTTInitialOtherExpenses"
		// See Documents.OBEntryOtherExpenses.QueryTextTTDataCosts
		Or CallSource = "EnteringBalancesOtherExpenses_QueryTextTTTheseExpenses"
		// See Documents.RecyclableWasteAllocation.QueryTextTableTTInitialOtherExpenses
		Or CallSource = "DistributionOfReturnableWaste_QueryTextTTTableInitialOtherExpenses" Then
		
		QueryText = StrReplace(QueryText, "&EndOfPeriod", "&Period"); //@Query-part
		QueryText = StrReplace(QueryText, "&ByAllCompanies", "FALSE"); //@Query-part
		QueryText = StrReplace(QueryText, "&CompanyArray", "&Organization"); //@Query-part
	EndIf;
	
	Return QueryText;
	
EndFunction

// Get the functional option accounting by AIT.
// 
// Returns:
//  Boolean - True if AIT accounting is enabled
Function GetFunctionalOptionAITAccounting() Export
	
	AITAccounting = False;
	
	Return AITAccounting;
	
EndFunction

// Check AIT accounting.
// The following are checked: the Accounting database, the constant datanachalachetapondd, the payer attribute in the organization's tax settings.
// 
// Parameters:
//  Period - Date - The date on which it is necessary to check the AIT accounting.
//  Organization - CatalogRef.Companies, Undefined - Organization
// 
// Returns:
//  Boolean - True if AIT accounting is enabled
Function RecordsAreKeptAccordingToAIT(Period, Organization = Undefined) Export
	
	RecordsAreKeptAccordingToAIT = False;
	
	Return RecordsAreKeptAccordingToAIT;
	
EndFunction

// Check AIT expense recognition for an expense item
// 
// Parameters:
//  ExpenseItem - ChartOfCharacteristicTypesRef.ExpenseItems - Item of expenses for verification
// 
// Returns:
//  Boolean - True if the item is recognized as AIT expenses
Function ItemOfExpensesIsRecognizedInAITExpenses(ExpenseItem) Export
	
	ArticleIsRecognizedAsGNI = False;
	
	Return ArticleIsRecognizedAsGNI;
	
EndFunction

// Replace the AIT type of the separate accounting object in the request.
// 
// Parameters:
//  QueryText - String - Query text
//  ParameterNames - String - The names of the parameters for which there are connections of temporary tables AIT, separated by commas without spaces. For cases when both objects have the same source table
//  TTNameForDivision - String - Names of temporary tables for divisions, if they differ for different objects
//  TTNameForLineOfBusiness - String - Names of temporary tables for business lines, if they differ for different objects
Procedure SubstituteAITTypeOfSeparateAccountingObjectInRequest(QueryText, ParameterNames, TTNameForDivision = "", TTNameForLineOfBusiness = "") Export
	
	DefaultSubstitution = True;
	
	If DefaultSubstitution Then
		ListOfReplacements = New Map;
		
		ListOfReplacements.Insert("&EmptyLinkToSeparateAccountingObjectAIT",
									"VALUE(Catalog.BusinessStructure.EmptyRef)"); //@query-part-1 @query-part-2
		
		ParametersList = StrSplit(ParameterNames, ",");
		
		// If different tables are used, then the replacement will only be 1
		If ValueIsFilled(TTNameForLineOfBusiness) And ValueIsFilled(TTNameForDivision) Then
			ListOfReplacements.Insert("&TableSource_ObjectOfSeparateAccountingAIT",
									"UNDEFINED"); //@query-part-1 @query-part-2
		// There may be several replacements for identical source tables
		Else
			For Each ParameterName In ParametersList Do
				ListOfReplacements.Insert(StrTemplate("&%1", ParameterName),
									"UNDEFINED"); //@query-part-1 @query-part-2
			EndDo;
		EndIf;
		
		For Each Replacement In ListOfReplacements Do
			QueryText = StrReplace(QueryText, Replacement.Key, Replacement.Value);
		EndDo;
	Else
	EndIf;
EndProcedure

// Complements the array of blocked object Attributes (See ChartsOfCharacteristicTypes.ExpenseItems.GetObjectAttributesToLock)
// .
//
// Parameters:
// 	AttributesToLock - Array of String - The locking details of the object
// 	WithoutFormElements - Boolean - Add only details to the array, without form control elements.
Procedure AddBlockedDetailsOfObjectAccordingToAIT(AttributesToLock, WithoutFormElements = False) Export
	
	
	Return; // so that the method is not empty without the personal data.
	
EndProcedure
// The Query Text for AIT settings destruction.
// 
// Returns:
//  String - The Query Text for AIT settings destruction.
Function QueryTextForDestroyingAITSettings() Export
	Return "
	|DROP AITArticleDistributionSettings
	|;
	|DROP SettingsForDistributionOfAITArticlesByCostCenter
	|;
	|";
EndFunction

// Substitute AIT amount in the request. For other expenses.
// Generates AIT string for incoming Registered Records based on the TA formula: SummaRegl - PD - TD
// With empty PD and TD, the sum of AIT = the sum of the REGL.
// For consumable Registered Records, SummaNDD = 0. The exception is AIT explicitly stated amounts in the document.
// 
// Parameters:
//  QueryText - String - Query text
//  TableName - String - Name Of The Main Table
//  RecordType - String - The type of Registered Recorded in the request. Options: Request, Arrival, Expense.
//  NameOfLocalAmountField - String - The name of the Local amount field in the request.
//  NameOfPDField - String - The name of the permanent difference field in the request. Empty by default.
//  NameOfTDField - String - Name of the time difference field in the request. Empty by default.
//  PeriodParameter_ - String - Period parameter, if the period is passed in the table using the parameter. Empty by default.
//  ArticleFieldIsMissing - Boolean - Indicates that the article field is missing.
Procedure SubstituteAmountOfPersonalIncomeTaxInRequest(QueryText, TableName, RecordType, NameOfLocalAmountField, NameOfPDField = "", NameOfTDField = "", PeriodParameter_ = "", ArticleFieldIsMissing = False) Export
	
	DefaultValues = True;
	
	If DefaultValues Then
		QueryText = StrReplace(QueryText, "&AITAmount", "0"); //@Query-part
	Else
	EndIf;
	
EndProcedure

// Insert a description of the service temporary register tables.
// 
// Parameters:
//  RegisterDescription - Structure - register description
Procedure InsertDescriptionOfServiceTemporaryTablesOfRegisterActualExpensesAITProductionImplementation(RegisterDescription) Export
	
	
	Return; // so that the method is not empty without the personal data.
	
EndProcedure

// Check register metadata actual expenses ndproduction implementation.
// 
// Parameters:
//  RegisterMetadata - MetadataObjectAccumulationRegister - Register metadata
// 
// Returns:
//  Boolean - Check register metadata actual expenses NDPRODUCTION implementation
Function CheckAITRegisterMetadataActualExpensesProductionImplementation(RegisterMetadata) Export
	
	ThisIsRightRegister = False;
	
	Return ThisIsRightRegister;
	
EndFunction

// Calculation of the cost in terms of AIT (income added tax) for goods.
// The resource of the register "Cost of goods" is calculated. The cost of NDD.
//
// Parameters:
//	CalculationParameters - Structure - cost calculation parameters:
// * MonthEndClosingMode - EnumRef.MonthEndClosingModes - Month closure mode.
// * DistributionOfAdditionalCostsBetweenPartiesAndGoods - Boolean - indicates the distribution of additional expenses between batches and goods.
// * BatchCalculationStarted - Boolean - Indicates that batch calculation is running.
Procedure CostCalculation_AITCost(CalculationParameters) Export
	
	
	Return; // so that the method is not empty without the personal data.
	
EndProcedure

// Adds to the array the names of registers that should be monitored for AIT purposes.
//
//	Parameters:
//	ControlRegisters - Array of String - array of elements of the "String" type.
//
Procedure SupplementControlRegistersWithAITRegisters(ControlRegisters) Export
	
	
	Return; // so that the method is not empty without the personal data.
	
EndProcedure

// Generates entries in the task registers by the end of the month.
// 
// Parameters:
// 	TempTablesManager - TempTablesManager -
Procedure GenerateAITTaskRegisterEntries(TempTablesManager) Export
	
	
	Return; // so that the method is not empty without the personal data.
	
EndProcedure

// Set the request parameters according to AIT settings.
// 
// Parameters:
//  Query - Query - Request for setting parameters
Procedure SetRequestParametersAccordingToAITSettings(Query) Export
	
	AITAccounting = False;
	StartDateOfAITAccounting = Date(1,1,1);
	
	
	Query.SetParameter("AITAccounting", AITAccounting);
	Query.SetParameter("StartDateOfAITAccounting", StartDateOfAITAccounting);
	
EndProcedure

// Returns a list of registers served by the batch calculation engine.
//
// Parameters:
//	OutgoingData - Map - the names of the registers that are serviced by the solver of the parties.
//
Procedure AITMechanismOutgoingData(OutgoingData) Export
	
	
	Return; // so that the method is not empty without the personal data.
	
EndProcedure

// Returns the Query Text to get organizations that have Registered Records for the cost price.
// 
// Returns:
//  String - Query text
Function QueryTextOrganizationsWithCostRegisteredRecords() Export
	
	QueryText = "
	|SELECT DISTINCT TOP 0
	|	VALUE(Catalog.Companies.EmptyRef) AS Organization
	|";
	
	
	Return QueryText; // so that the method is not empty without the personal data.
	
EndFunction

#EndRegion

#Region DocumentsPosting

// Add AIT amount field to additional fields.
// 
// Parameters:
//  AdditionalFields - String - Additional fields separated by commas
Procedure AddAdditionalFieldsByAIT(AdditionalFields) Export
	
	If ValueIsFilled(AdditionalFields) Then
		AdditionalFields = "AITAmount," + AdditionalFields;
	Else
		AdditionalFields = "AITAmount";
	EndIf;
	
EndProcedure

// Insert AIT cost in the request.
// 
// Parameters:
//  QueryText - String - Query text
//  Operation - String - Cost Operation
//  CheckingRecognitionSettings - Boolean - Indicates whether the recognition settings need to be checked (for Unfinished production Operations).
Procedure SubstituteCostOfPersonalDataRequest(QueryText, Operation, CheckingRecognitionSettings = False) Export
	
	DefaultValues = True;
	
	If DefaultValues Then
		QueryText = StrReplace(QueryText, "&CostOfPersonalIncomeTax", "0"); //@Query-part
	Else
	EndIf;
	
EndProcedure

// Add request parameters for batch accounting registers.
// 
// Parameters:
//  ParametersStructure - Structure - parameter structure 
Procedure AddStructureOfRequestParametersForConducting(ParametersStructure) Export
	
	DefaultValues = True;
	
	If DefaultValues Then
		ParametersStructure.Insert("Constant_StartDateOfAITAccounting", Date(1,1,1));
	Else
	EndIf;
	
EndProcedure

// Add AIT constants to the request parameters.
// 
// Parameters:
//  Query - Query - Request to set parameters in. 
Procedure AddAITConstantsToRequestParameters(Query) Export
	
	DefaultValues = True;
	
	If DefaultValues Then
		Query.SetParameter("Constant_StartDateOfAITAccounting", Date(1,1,1));
		Query.SetParameter("Constant_UseAITAccounting", False);
	Else
	EndIf;
	
EndProcedure

#EndRegion 

#Region GettingAITSettings

// Generates the text of the description of these AIT settings.
// 
// Parameters:
//  ParametersForAITDataAcquisition - Structure - Parameters For AIT Data Acquisition:
// * NameOfTemporarySourceTable - String - name of the table with expenditure data
// * NeedTableCostCenter - Boolean - The need for additional TT for CO
// * AccountingPolicyOnly - Boolean - The need to obtain only basic settings of the FO and tax settings
// * RecognitionSettingsOnly - Boolean -  The need to obtain only basic AIT application settings (FO accounting and organization taxation settings)
// * SubstitutingArticleSettingsForCostCentersForDistribution - Boolean - The need to replace the options and rules from the articles with data on CO HIA
// * AllocationRules - Boolean - The need to obtain distribution rules
// * OptionsForAITExpenseRecognition - String - A string of AIT expense recognition options for use in query parameters
// * DestructibleTT - String - List of TT for destruction
//  CallSource - String - Name of the call source
// 
// Returns:
//  String - Text Description Of These AIT Settings
Function TextDescriptionOfTheseAITSettings(ParametersForAITDataAcquisition, CallSource) Export
	
	QueryTexts = New Array; // Array of String
	
	QueryTexts.Add(QueryTextDescriptionOfAITAccountingPolicy(CallSource));
	
	If Not ParametersForAITDataAcquisition.AccountingPolicyOnly Then
		
		QueryTexts.Add(QueryTextDescriptionOfAITExpenseRecognitionSettings());
		
		If ParametersForAITDataAcquisition.RecognitionSettingsForItemAccountingAnalyticsKeys Then
			QueryTexts.Add(QueryTextDescriptionOfAITExpenseRecognitionSettingsForItemAccountingAnalytics());
		EndIf;
		
		If Not ParametersForAITDataAcquisition.RecognitionSettingsOnly Then
		
			QueryTexts.Add(QueryTextDescriptionOfAITArticleDistributionPresets(ParametersForAITDataAcquisition));
			QueryTexts.Add(QueryTextDescriptionOfAITArticleDistributionSettings());
			
			If ParametersForAITDataAcquisition.NeedTableCostCenter Then
				
				QueryTexts.Add(QueryTextDescriptionOfAITSettingsDataForCostCenters());
			EndIf;
		EndIf;
	EndIf;
	
	QueryText = StrConcat(QueryTexts, Common.QueryBatchSeparator());
	
	AddTextDestroyTemporaryTablesToQuery(QueryText, ParametersForAITDataAcquisition.DestructibleTT);
	
	Return QueryText;
	
EndFunction

// The text of the description of the TT AccountPoliticaPoNDD.
// 
// Parameters:
//  CallSource - String - Description of the call source
//
// Returns:
//  String - Text Description Of Data 
Function QueryTextDescriptionOfAITAccountingPolicy(CallSource = "") Export
	
	AITNameOfTTAccountingPolicy = "AITAccountingPolicy"; //@Query-part
	
	// For Registering Records for other expenses, the accounting policy is TT called Accounting Policy. The accounting policy is called accounting expenses,
	// so as not to overlap with the same table in the cost of goods
	If CallSource = "OtherExpenses_QueryTextTableOtherExpenses" Then
		AITNameOfTTAccountingPolicy = "AITAccountingPolicyOtherExpenses"; //@Query-part
	EndIf;
	
	QueryText = StrTemplate("
		|SELECT TOP 0
		|	VALUE(Catalog.Companies.EmptyRef) AS Organization,
		|	FALSE AS PayerOfAdditionalIncomeTaxFromHydrocarbonProductionAIT
		|INTO %1
		|",
		AITNameOfTTAccountingPolicy); //@query-part-1
		
	Return QueryText;
	
EndFunction

// The text of the description of the TT customizationrecognizationspendd.
// 
// Returns:
//  String - Text Description Of Data 
Function QueryTextDescriptionOfAITExpenseRecognitionSettings()
	
	QueryText = "
		|SELECT TOP 0
		|	&EmptyLinkToSeparateAccountingObjectAIT AS ObjectOfSeparateAccountingAIT,
		|	VALUE(Catalog.Companies.EmptyRef) AS Organization,
		|	FALSE AS ExpensesAreIncludedInCost,
		|	NULL AS ExpenseRecognitionOption,
		|	VALUE(Catalog.CostAllocationRules.EmptyRef) AS CostSharingRule
		|INTO AITExpenseRecognitionSettings
		|";
		
	Return QueryText;
	
EndFunction

// The text of the description of the TT customizationrecognizationspenddpoanalyticesaccountmentsreferences.
// 
// Returns:
//  String - Text Description Of Data 
Function QueryTextDescriptionOfAITExpenseRecognitionSettingsForItemAccountingAnalytics()
	
	QueryText = "
		|SELECT TOP 0
		|	VALUE(Catalog.InventoryLocationAttributeKeys.EmptyRef)	AS ItemsLocationAttributes,
		|	VALUE(Catalog.Companies.EmptyRef)						AS Organization,
		|	FALSE 																AS ExpensesAreIncludedInCost,
		|	NULL																AS ExpenseRecognitionOption,
		|	VALUE(Catalog.CostAllocationRules.EmptyRef)		AS CostSharingRule
		|INTO AITExpenseRecognitionSettingsForItemAccountingAnalytics
		|";
		
	Return QueryText;
	
EndFunction

// The text of the description TT of the preliminary designationdistributionstateindd.
// 
// Parameters:
//  ParametersForAITDataAcquisition - Structure - Parameters For AIT Data Acquisition:
// * NameOfTemporarySourceTable - String - name of the table with expenditure data
// * NeedTableCostCenter - Boolean - The need for additional TT for CO
// * AccountingPolicyOnly - Boolean - The need to obtain only basic settings of the FO and tax settings
// * RecognitionSettingsOnly - Boolean -  The need to obtain only the basic recognition settings (the fact of accounting for AIT by analysts)
// * SubstitutingArticleSettingsForCostCentersForDistribution - Boolean - The need to replace the options and rules from the articles with data on CO HIA
// * AllocationRules - Boolean - The need to obtain distribution rules
// * OptionsForAITExpenseRecognition - String - A string of AIT expense recognition options for use in query parameters
// * DestructibleTT - String - List of TT for destruction
// 
// Returns:
//  String - Text Description Of Data
Function QueryTextDescriptionOfAITArticleDistributionPresets(ParametersForAITDataAcquisition)
	
	QueryText = "";
	
	// For data with CO, additional fields are added, because it will be used in see The textsanastroykirasdistributionstateynddpoovz
	If ParametersForAITDataAcquisition.NeedTableCostCenter Then
		QueryText = "
				|SELECT TOP 0
				|	VALUE(ChartOfCharacteristicTypes.ExpenseItems.EmptyRef) AS ExpenseItem,
				|	NULL AS ConstCenter,
				|	&EmptyLinkToSeparateAccountingObjectAIT AS ObjectOfSeparateAccountingAIT,
				|	VALUE(Catalog.Companies.EmptyRef) AS Organization,
				|	FALSE AS ExpensesAreIncludedInCost,
				|	VALUE(Enum.CostAllocationOptions.EmptyRef) AS CostAllocationOptionLocal,
				|	VALUE(Enum.CostAllocationOptions.EmptyRef) AS CostAllocationOptionTax,
				|	VALUE(Catalog.CostAllocationRules.EmptyRef) AS LocalDistributionRule,
				|	VALUE(Catalog.CostAllocationRules.EmptyRef) AS TADistributionRule,
				|	VALUE(Catalog.CostAllocationRules.EmptyRef) AS RuleOfDistributionOfPersonalIncomeTax,
				|	FALSE AS ThisIsOVZ
				|INTO PreliminarySettingsForDistributionOfAITArticles
				|";
	Else
		QueryText = "
				|SELECT TOP 0
				|	VALUE(ChartOfCharacteristicTypes.ExpenseItems.EmptyRef) AS ExpenseItem,
				|	&EmptyLinkToSeparateAccountingObjectAIT AS ObjectOfSeparateAccountingAIT,
				|	VALUE(Catalog.Companies.EmptyRef) AS Organization,
				|	FALSE AS ExpensesAreIncludedInCost,
				|	VALUE(Enum.CostAllocationOptions.EmptyRef) AS CostAllocationOptionLocal,
				|	VALUE(Enum.CostAllocationOptions.EmptyRef) AS CostAllocationOptionTax,
				|	VALUE(Catalog.CostAllocationRules.EmptyRef) AS LocalDistributionRule,
				|	VALUE(Catalog.CostAllocationRules.EmptyRef) AS TADistributionRule,
				|	VALUE(Catalog.CostAllocationRules.EmptyRef) AS RuleOfDistributionOfPersonalIncomeTax,
				|	FALSE AS ThisIsOVZ
				|INTO PreliminarySettingsForDistributionOfAITArticles
				|";
	EndIf;
		
	Return QueryText;
	
EndFunction

// The text of the description of the TT setting of the distribution of the Stat.
// 
// Returns:
//  String - Text Description Of Data 
Function QueryTextDescriptionOfAITArticleDistributionSettings()
	
	QueryText = "
		|SELECT TOP 0
		|	VALUE(ChartOfCharacteristicTypes.ExpenseItems.EmptyRef) AS ExpenseItem,
		|	VALUE(Catalog.BusinessStructure.EmptyRef) AS ObjectOfSeparateAccountingAIT,
		|	VALUE(Catalog.Companies.EmptyRef) AS Organization,
		|	FALSE AS ExpensesAreIncludedInCost,
		|	VALUE(Enum.CostAllocationOptions.EmptyRef) AS AITCostAllocationOption,
		|	VALUE(Catalog.CostAllocationRules.EmptyRef) AS CostAllocationRuleAIT,
		|	NULL AS ExpenseRecognitionOption
		|INTO AITArticleDistributionSettings
		|";
		
	Return QueryText;
	
EndFunction

// The text of the description of the TT setingsdistributionstateynddpoovz.
// 
// Returns:
//  String - Text description of these AIT settings for CO
Function QueryTextDescriptionOfAITSettingsDataForCostCenters()
	
	QueryText = "
		|SELECT TOP 0
		|	NULL AS ConstCenter,
		|	FALSE AS ExpensesAreIncludedInCost,
		|	VALUE(Enum.CostAllocationOptions.EmptyRef) AS AITCostAllocationOption,
		|	VALUE(Catalog.CostAllocationRules.EmptyRef) AS CostAllocationRuleAIT,
		|	NULL AS ExpenseRecognitionOption
		|INTO SettingsForDistributionOfAITArticlesByCostCenter
		|";
		
	Return QueryText;
	
EndFunction

// Add the text of the destruction of temporary tables to the query.
// Does not require a temporary table manager, but is sensitive to table names.
// 
// Parameters:
//  QueryText - String - Query text
//  TablesNames - String - Comma-separated table names
Procedure AddTextDestroyTemporaryTablesToQuery(QueryText, TablesNames)
	
	If Not ValueIsFilled(TablesNames) Then
		Return; // So that you don't have to do table name checks when calling this procedure.
	EndIf;
	
	TableStructure = New Structure(TablesNames);
	
	For Each KeyAndValue In TableStructure Do
		
		If StrFind(QueryText, KeyAndValue.Key) = 0 Then
			Continue;
		EndIf;
		
		QueryText = QueryText 
			+ ?(QueryText = "", "", "
			|;
			|////////////////////////////////////////////////////////////////////////////////
			|
			|") + "DROP " + KeyAndValue.Key;
		
	EndDo;
	
EndProcedure

#EndRegion

#EndRegion

// Adds the names of functional options to the string.
//
// Parameters:
//	FONames - String - a string listing the names of functional options
//
Procedure CompleteNamesOfFunctionalOptions(FONames) Export
EndProcedure

// Complementary to the calculation parameters of the parties and costs.
//
// Parameters:
//	CalculationParameters - Structure - the parameters used in the calculation of the parties and the cost
//
Procedure AddCalculationParameters(CalculationParameters) Export
	
	#Region OrganizationsAndPolicies
	
	// Organizations and their accounting policies.

	
	CalculationParameters.AccountingPolicies.Insert("AccountingForBatchesOfVATVersion22", 	   New Structure);
	CalculationParameters.AccountingPolicies.AccountingForBatchesOfVATVersion22.Insert(
		"UsedInCurPeriod",
		New Array);
	CalculationParameters.AccountingPolicies.AccountingForBatchesOfVATVersion22.Insert(
		"UsedInLastPeriod",
		New Array);
	
	CalculationParameters.AccountingPolicies.Insert("AccountingForBatchesOfVATVersion24", 	   New Structure);
	CalculationParameters.AccountingPolicies.AccountingForBatchesOfVATVersion24.Insert(
		"UsedInCurPeriod",
		New Array);
	CalculationParameters.AccountingPolicies.AccountingForBatchesOfVATVersion24.Insert(
		"UsedInLastPeriod",
		New Array);
	
	CalculationParameters.AccountingPolicies.Insert("VATLotsAreNotRecorded",    New Structure);
	CalculationParameters.AccountingPolicies.VATLotsAreNotRecorded.Insert(
		"UsedInCurPeriod",
		New Array);
	CalculationParameters.AccountingPolicies.VATLotsAreNotRecorded.Insert(
		"UsedInLastPeriod",
		New Array);
	
	CalculationParameters.AccountingPolicies.Insert("AccountingOfBatchesOfVATAdditionalExpensesAmount",   New Structure);
	CalculationParameters.AccountingPolicies.AccountingOfBatchesOfVATAdditionalExpensesAmount.Insert(
		"UsedInCurPeriod",
		New Array);
	
	
	CalculationParameters.AccountingPolicies.Insert("DrillDownProductCostToInitialCosts", New Structure);
	CalculationParameters.AccountingPolicies.DrillDownProductCostToInitialCosts.Insert(
		"UsedInCurPeriod",
		New Array);
	CalculationParameters.AccountingPolicies.DrillDownProductCostToInitialCosts.Insert(
		"UsedInLastPeriod",
		New Array);
	
	RequestAccountingPolicies = New Query;
	RequestAccountingPolicies.Text = "
	|SELECT ALLOWED
	|	CatCompanies.ParentCompany AS ParentCompany,
	|	CatCompanies.Ref AS Organization
	|INTO TTParentOrganizations
	|FROM
	|	Catalog.Companies AS CatCompanies
	|WHERE
	|	CatCompanies.Ref IN (&Companies)
	|
	|INDEX BY
	|	ParentCompany
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	FinancialAccountingPolicySliceLast.Organization AS Organization,
	|	FinancialAccountingPolicySliceLast.ItemizeMaterialAndItemizedExpensesInInventoryCost,
	|	FinancialAccountingPolicySliceLast.InventoryValuationMethod,
	|	FinancialAccountingPolicySliceLast.DrillDownProductCostToInitialCosts
	|INTO TTFinAccounting
	|FROM
	|	InformationRegister.FinancialAccountingPolicy.SliceLast(&Period, Organization IN
	|		(SELECT
	|			ParentCompany
	|		FROM
	|			TTParentOrganizations)) AS FinancialAccountingPolicySliceLast
	|
	|INDEX BY
	|	Organization
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	TaxationSystemSettingsSliceLast.Organization AS Organization,
	|	TaxationSystemSettingsSliceLast.TaxationSystem,
	|	TaxationSystemSettingsSliceLast.PayerOfAdditionalIncomeTaxFromHydrocarbonProductionAIT AS PayerOfAdditionalIncomeTaxFromHydrocarbonProductionAIT
	|INTO TTTaxSystem
	|FROM
	|	InformationRegister.TaxationSystemSettings.SliceLast(&Period, Organization IN
	|		(SELECT
	|			ParentCompany
	|		FROM
	|			TTParentOrganizations)) AS TaxationSystemSettingsSliceLast
	|
	|INDEX BY
	|	Organization
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	VATAccountingSettingsSliceLast.Organization AS Organization,
	|	VATAccountingSettingsSliceLast.SeparateAccountingOfGoodsByVATTaxation
	|INTO TTVATAccounting
	|FROM
	|	InformationRegister.VATAccountingSettings.SliceLast(&Period, Organization IN
	|		(SELECT
	|			ParentCompany
	|		FROM
	|			TTParentOrganizations)) AS VATAccountingSettingsSliceLast
	|
	|INDEX BY
	|	Organization
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	FinancialAccountingPolicySliceLast.Organization AS Organization,
	|	FinancialAccountingPolicySliceLast.ItemizeMaterialAndItemizedExpensesInInventoryCost,
	|	FinancialAccountingPolicySliceLast.InventoryValuationMethod,
	|	FinancialAccountingPolicySliceLast.DrillDownProductCostToInitialCosts
	|INTO TTFinAccountingForPreviousPeriod
	|FROM
	|	InformationRegister.FinancialAccountingPolicy.SliceLast(&PreviousPeriod, Organization IN
	|		(SELECT
	|			ParentCompany
	|		FROM
	|			TTParentOrganizations)) AS FinancialAccountingPolicySliceLast
	|
	|INDEX BY
	|	Organization
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	TaxationSystemSettingsSliceLast.Organization AS Organization,
	|	TaxationSystemSettingsSliceLast.TaxationSystem,
	|	TaxationSystemSettingsSliceLast.PayerOfAdditionalIncomeTaxFromHydrocarbonProductionAIT AS PayerOfAdditionalIncomeTaxFromHydrocarbonProductionAIT
	|INTO TTTaxSystemLastPeriod
	|FROM
	|	InformationRegister.TaxationSystemSettings.SliceLast(&PreviousPeriod, Organization IN
	|		(SELECT
	|			ParentCompany
	|		FROM
	|			TTParentOrganizations)) AS TaxationSystemSettingsSliceLast
	|
	|INDEX BY
	|	Organization
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	VATAccountingSettingsSliceLast.Organization AS Organization,
	|	VATAccountingSettingsSliceLast.SeparateAccountingOfGoodsByVATTaxation
	|INTO TTVATAccountingForPreviousPeriod
	|FROM
	|	InformationRegister.VATAccountingSettings.SliceLast(&PreviousPeriod, Organization IN
	|		(SELECT
	|			ParentCompany
	|		FROM
	|			TTParentOrganizations)) AS VATAccountingSettingsSliceLast
	|
	|INDEX BY
	|	Organization
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	TTParentOrganizations.Organization AS Organization,
	|	ISNULL(TTTaxSystem.TaxationSystem, VALUE(Enum.TaxationSystems.Shared3)) AS
	|		TaxationSystem,
	|	ISNULL(TTFinAccounting.ItemizeMaterialAndItemizedExpensesInInventoryCost, FALSE) AS ItemizeMaterialAndItemizedExpensesInInventoryCost,
	|	ISNULL(TTFinAccounting.InventoryValuationMethod,
	|		VALUE(Enum.InventoryValuationMethods.AveragePerMonth)) AS InventoryValuationMethod,
	|	ISNULL(TTFinAccounting.DrillDownProductCostToInitialCosts,
	|		TRUE) AS DrillDownProductCostToInitialCosts,
	|	ISNULL(TTVATAccounting.SeparateAccountingOfGoodsByVATTaxation, FALSE) AS SeparateAccountingOfGoodsByVATTaxation,
	|	ISNULL(TTTaxSystem.PayerOfAdditionalIncomeTaxFromHydrocarbonProductionAIT, FALSE) AS PayerOfAdditionalIncomeTaxFromHydrocarbonProductionAIT
	|FROM
	|	TTParentOrganizations AS TTParentOrganizations
	|		LEFT JOIN TTTaxSystem AS TTTaxSystem
	|		ON TTParentOrganizations.ParentCompany = TTTaxSystem.Organization
	|		LEFT JOIN TTFinAccounting AS TTFinAccounting
	|		ON TTParentOrganizations.ParentCompany = TTFinAccounting.Organization
	|		LEFT JOIN TTVATAccounting AS TTVATAccounting
	|		ON TTParentOrganizations.ParentCompany = TTVATAccounting.Organization
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	TTParentOrganizations.Organization AS Organization,
	|	ISNULL(TTTaxSystemLastPeriod.TaxationSystem,
	|		VALUE(Enum.TaxationSystems.Shared3)) AS TaxationSystem,
	|	ISNULL(TTFinAccountingForPreviousPeriod.ItemizeMaterialAndItemizedExpensesInInventoryCost, FALSE) AS ItemizeMaterialAndItemizedExpensesInInventoryCost,
	|	ISNULL(TTFinAccountingForPreviousPeriod.InventoryValuationMethod,
	|		VALUE(Enum.InventoryValuationMethods.AveragePerMonth)) AS InventoryValuationMethod,
	|	ISNULL(TTFinAccountingForPreviousPeriod.DrillDownProductCostToInitialCosts,
	|		TRUE) AS DrillDownProductCostToInitialCosts,
	|	ISNULL(TTVATAccountingForPreviousPeriod.SeparateAccountingOfGoodsByVATTaxation, FALSE) AS SeparateAccountingOfGoodsByVATTaxation,
	|	ISNULL(TTTaxSystemLastPeriod.PayerOfAdditionalIncomeTaxFromHydrocarbonProductionAIT, FALSE) AS PayerOfAdditionalIncomeTaxFromHydrocarbonProductionAIT
	|FROM
	|	TTParentOrganizations AS TTParentOrganizations
	|		LEFT JOIN TTTaxSystemLastPeriod AS TTTaxSystemLastPeriod
	|		ON TTParentOrganizations.ParentCompany = TTTaxSystemLastPeriod.Organization
	|		LEFT JOIN TTFinAccountingForPreviousPeriod AS TTFinAccountingForPreviousPeriod
	|		ON TTParentOrganizations.ParentCompany = TTFinAccountingForPreviousPeriod.Organization
	|		LEFT JOIN TTVATAccountingForPreviousPeriod AS TTVATAccountingForPreviousPeriod
	|		ON TTParentOrganizations.ParentCompany = TTVATAccountingForPreviousPeriod.Organization";
	
	RequestAccountingPolicies.SetParameter("Companies", CalculationParameters.CompanyArray);
	RequestAccountingPolicies.SetParameter("Period", CalculationParameters.PayrollPeriod.BeginOfPeriod);
	RequestAccountingPolicies.SetParameter("PreviousPeriod", CalculationParameters.PayrollPeriod.BeginningOfPreviousPeriod);
	
	Result						= RequestAccountingPolicies.ExecuteBatch();
	
	AccountingPolicies					= Result[7].Unload();
	PastAccountingPolicies	= Result[8].Unload();
	
	For Each AccountingPolicyParameters In AccountingPolicies Do
		
		AccountingPolicyParameterOfPreviousPeriod = PastAccountingPolicies.Find(
			AccountingPolicyParameters.Organization,
			"Organization");
		
		CalculationParameters.AccountingPolicies.ValuationMethods.Insert(
			AccountingPolicyParameters.Organization,
			AccountingPolicyParameters.InventoryValuationMethod);
		
		
		// Accounting parties...
		If CalculationParameters.BatchAccountingVersion22
		 And (AccountingPolicyParameters.SeparateAccountingOfGoodsByVATTaxation
		 	Or AccountingPolicyParameters.ItemizeMaterialAndItemizedExpensesInInventoryCost
			Or AccountingPolicyParameters.PayerOfAdditionalIncomeTaxFromHydrocarbonProductionAIT
			
		
			) Then
			
			If AccountingPolicyParameters.InventoryValuationMethod = Enums.InventoryValuationMethods.FIFORollingValuation Then
				OrganizationsWithAccountingPolicies = CalculationParameters.AccountingPolicies.AccountingForBatchesOfVATVersion24.UsedInCurPeriod; // Array
				OrganizationsWithAccountingPolicies.Add(AccountingPolicyParameters.Organization);
			Else
				OrganizationsWithAccountingPolicies = CalculationParameters.AccountingPolicies.AccountingForBatchesOfVATVersion22.UsedInCurPeriod; // Array
				OrganizationsWithAccountingPolicies.Add(AccountingPolicyParameters.Organization);
			EndIf;
			
			OrganizationsWithAccountingPolicies = CalculationParameters.AccountingPolicies.AccountingOfBatchesOfVATAdditionalExpensesAmount.UsedInCurPeriod; // Array
			OrganizationsWithAccountingPolicies.Add(AccountingPolicyParameters.Organization);
			
			// Adjustment of the detailing of the cost of production to the initial costs will be applied only with the assessment methods
			// "Monthly average" and "Medium-slip".
			If (AccountingPolicyParameters.DrillDownProductCostToInitialCosts
			 		And Not AccountingPolicyParameters.InventoryValuationMethod = Enums.InventoryValuationMethods.FIFORollingValuation)
			 And AccountingPolicyParameters.TaxationSystem = Enums.TaxationSystems.Shared3 Then
				OrganizationsWithAccountingPolicies = CalculationParameters.AccountingPolicies.DrillDownProductCostToInitialCosts.UsedInCurPeriod; // Array
				OrganizationsWithAccountingPolicies.Add(AccountingPolicyParameters.Organization);
			EndIf;
			
		Else
			OrganizationsWithAccountingPolicies = CalculationParameters.AccountingPolicies.VATLotsAreNotRecorded.UsedInCurPeriod; // Array
			OrganizationsWithAccountingPolicies.Add(AccountingPolicyParameters.Organization);
		EndIf;
		
		If CalculationParameters.BatchAccountingVersion22
		 And (AccountingPolicyParameterOfPreviousPeriod.SeparateAccountingOfGoodsByVATTaxation
		 	Or AccountingPolicyParameterOfPreviousPeriod.ItemizeMaterialAndItemizedExpensesInInventoryCost
			Or AccountingPolicyParameterOfPreviousPeriod.PayerOfAdditionalIncomeTaxFromHydrocarbonProductionAIT
			
		
			) Then
			
			If AccountingPolicyParameterOfPreviousPeriod.InventoryValuationMethod = Enums.InventoryValuationMethods.FIFORollingValuation Then
				OrganizationsWithAccountingPolicies = CalculationParameters.AccountingPolicies.AccountingForBatchesOfVATVersion24.UsedInLastPeriod; // Array
				OrganizationsWithAccountingPolicies.Add(AccountingPolicyParameters.Organization);
			Else
				OrganizationsWithAccountingPolicies = CalculationParameters.AccountingPolicies.AccountingForBatchesOfVATVersion22.UsedInLastPeriod; // Array
				OrganizationsWithAccountingPolicies.Add(AccountingPolicyParameters.Organization);
			EndIf;
			
			If (AccountingPolicyParameterOfPreviousPeriod.DrillDownProductCostToInitialCosts
					Or AccountingPolicyParameterOfPreviousPeriod.InventoryValuationMethod = Enums.InventoryValuationMethods.FIFORollingValuation)
				And AccountingPolicyParameterOfPreviousPeriod.TaxationSystem = Enums.TaxationSystems.Shared3 Then
				
				OrganizationsWithAccountingPolicies = CalculationParameters.AccountingPolicies.DrillDownProductCostToInitialCosts.UsedInLastPeriod; // Array
				OrganizationsWithAccountingPolicies.Add(AccountingPolicyParameters.Organization);
			EndIf;
			
		Else
			OrganizationsWithAccountingPolicies = CalculationParameters.AccountingPolicies.VATLotsAreNotRecorded.UsedInLastPeriod; // Array
			OrganizationsWithAccountingPolicies.Add(AccountingPolicyParameters.Organization);
		EndIf;
		
			
		
	EndDo;
	
	#EndRegion

	
EndProcedure

// Complements the request properties.
//
// Parameters:
//	Query - Query - Request to set parameters for
//  CalculationParameters - See CostCalculationAppliedAlgorithms.InitializeGeneralCalculationParameters
//
Procedure AddRequestProperties(Query, CalculationParameters) Export
	Query.SetParameter("OrganizationsIncludingVATLotsVersion22", 				 CalculationParameters.AccountingPolicies.AccountingForBatchesOfVATVersion22.UsedInCurPeriod);
	Query.SetParameter("OrganizationsIncludingVATLotsVersion24", 				 CalculationParameters.AccountingPolicies.AccountingForBatchesOfVATVersion24.UsedInCurPeriod);
	Query.SetParameter("OrganizationsTakingIntoAccountBatchesOfVATVersion22INLastPeriod",  CalculationParameters.AccountingPolicies.AccountingForBatchesOfVATVersion22.UsedInLastPeriod);
	Query.SetParameter("OrganizationsWithVATBatchesOfVersion24InPreviousPeriod",  CalculationParameters.AccountingPolicies.AccountingForBatchesOfVATVersion24.UsedInLastPeriod);
	Query.SetParameter("OrganizationsExcludingLotsOfVAT",  						 CalculationParameters.AccountingPolicies.VATLotsAreNotRecorded.UsedInCurPeriod);
	Query.SetParameter("OrganizationsExcludingNDSPartiesInPreviousPeriod",  		 CalculationParameters.AccountingPolicies.VATLotsAreNotRecorded.UsedInLastPeriod);
	Query.SetParameter("OrganizationsIncludingLotsOfVATAdditionalExpensesAmount",				 CalculationParameters.AccountingPolicies.AccountingOfBatchesOfVATAdditionalExpensesAmount.UsedInCurPeriod);
	
	Query.SetParameter("OrganizationsDetailingCostOfProductionToInitialCosts",
		CalculationParameters.AccountingPolicies.DrillDownProductCostToInitialCosts.UsedInCurPeriod);
	Query.SetParameter("OrganizationsWithDetailedCostOfProductionUpToInitialCostsWereUsedInLastPeriod",
		CalculationParameters.AccountingPolicies.DrillDownProductCostToInitialCosts.UsedInLastPeriod);
	
EndProcedure

// Complements the request parameters for conducting documents.
//
// Parameters:
//	Attributes - Arbitrary - the details of the document to determine the parameters of batch accounting
//	Period - Date - period for receiving data
//  Organization - CatalogRef.Companies, Undefined - The company to receive the data
//	ParametersStructure - Structure - list of parameters with set values
//
Procedure AddRequestParametersForConducting(Attributes, Period, Organization, ParametersStructure) Export
	
	// Initialization of localized parameters with default values.
	ParametersStructure.Insert("SeparateAccountingOfItemizedProductionCostsForVATTaxation", False);
	ParametersStructure.Insert("ExpenseItemVATWriteOff", ChartsOfCharacteristicTypes.ExpenseItems.EmptyRef());
	ParametersStructure.Insert("ExpenseDimensionVATWriteOff", ChartsOfCharacteristicTypes.ExpenseItems.EmptyRef());
	ParametersStructure.Insert("PayerOfAdditionalIncomeTaxFromHydrocarbonProductionAIT", Undefined);
	
EndProcedure

// Returns an indication that the specified case is localizable.
//
// Parameters:
//	RegisterName - String - name of the register to check
//
// Returns:
//	Boolean - the sign of a localized register
//
Function ThisIsLocalizableInformationRegister(RegisterName) Export
	
	If RegisterName = Metadata.InformationRegisters.ItemizeGoodsLotCost.Name
	 Or RegisterName = Metadata.InformationRegisters.ItemizeLotCostItemizedAndOtherCosts.Name
	 Or RegisterName = Metadata.InformationRegisters.ItemizeGoodsCostItemizedAndOtherCosts.Name Then
		Return True;
	EndIf;
	
	Return False;
	
EndFunction

#EndRegion
