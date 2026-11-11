/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// Batch accounting mechanism version 2.2
//
///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//

#Region Public

// Start batch calculation.
//
// Parameters:
//	StartupParameters - Structure - Contains keys:
//		* Date - Date - the calculation period
//		* CompanyArray - CatalogRef.Companies - calculate only for the specified company; batches will also be recalculated for companies connected by the Intercampany scheme with the specified
//					- Array of CatalogRef.Companies- array of companies for which batches should be calculated, other companies are not calculated
//		* CalculationScheme - See CostCalculationAppliedAlgorithms.BatchCalculationScheme
//		* PlaceOfCalculationCall - String - where the calculation was called from, for the record
//		* ClosingMonthIsInProgress - Boolean - whether to call the calculation from the month closing mechanism
//		* CalculationID - UUID - calculation ID
//	CalculationParameters - Structure - the calculation parameters are generated in the calling mechanism.
//	DebugParameters - Structure - It is intended for redefining the properties of the structure of the calculation parameters of the same name.
//		For more information, see explanations in the calculation code of the highest values of the individual algorithms.initializeparameterscountparties to the parameterreferences.
//
Procedure CalculateEverything(StartupParameters, CalculationParameters = Undefined, DebugParameters = Undefined) Export
	
	SetPrivilegedMode(True);
	
	ClosingMonthIsInProgress = StartupParameters.Property("ClosingMonthIsInProgress");
	
	If StartupParameters.Property("CalculationID") Then
		CalculationID = StartupParameters.CalculationID;
	Else
		CalculationID = New UUID;
	EndIf;
	
	If StartupParameters.Property("AutoTesting") And StartupParameters.AutoTesting Then
		AutoTesting = True; // called during testing
	Else
		AutoTesting = False;
	EndIf;
	
	If CalculationOfCostLocalization.CalculateEverything(StartupParameters.Date, StartupParameters.CompanyArray, ClosingMonthIsInProgress, AutoTesting) Then
		Return;
	EndIf;
	
	// Initialize the debugging parameters.
	CostCalculationAppliedAlgorithms.InitializeDebuggingOptions(DebugParameters, StartupParameters);
	
	// Let's check if the IB update is finished
	CostCalculationAppliedAlgorithms.CheckDataLockWhenUpdatingInformationSecurity(False, True, DebugParameters);
	
	#Region CalculationScheme

	// We will determine for which periods and organizations recalculation is required
	If StartupParameters.Property("CalculationScheme") Then
		
		CalculationScheme = StartupParameters.CalculationScheme;
		
		If StartupParameters.Property("TemporaryTable") Then
			TemporaryTable = StartupParameters.TemporaryTable;
		Else
			TemporaryTable = CostCalculationAppliedAlgorithms.GenerateTTTasksBeforeCalculation(-1, Undefined);
		EndIf;
		
		TaskNumberBeforeCalculation = InformationRegisters.JobsForCalculatingCost.GetTaskNumber();
		
	Else
		
		TaskNumberBeforeCalculation = CostCalculationAppliedAlgorithms.IncreaseTaskNumberForCostCalculation();
		
		BeginTransaction();
		
		Try
			
			OnlyOneOrganization = ?(StartupParameters.Property("OnlyOneOrganization"), StartupParameters.OnlyOneOrganization, False);
			
			// We will determine for which periods and organizations recalculation is required.
			CalculationScheme = CostCalculationAppliedAlgorithms.BatchCalculationScheme(
				StartupParameters.Date,
				StartupParameters.CompanyArray,
				TaskNumberBeforeCalculation,
				OnlyOneOrganization);
				
			If CalculationScheme.Count() > 0 Then
				TemporaryTable = CostCalculationAppliedAlgorithms.GenerateTTTasksBeforeCalculation(
					TaskNumberBeforeCalculation,
					CalculationScheme[CalculationScheme.Count() - 1].Companies);
			EndIf;
			
			CommitTransaction();
			
		Except
			RollbackTransaction();
			ErrorText = DetailErrorDescription(ErrorInfo());
			Raise ErrorText;
		EndTry;
		
	EndIf;
	
	ClosingMonthIsInProgress = StartupParameters.Property("ClosingMonthIsInProgress");
	
	DateOfMigrationToBatchAccounting22 = CalculationOfCostCached.DateOfMigrationToBatchAccounting22();
	
	If CalculationScheme.Count() > 0 And BegOfMonth(CalculationScheme[0].Date) < DateOfMigrationToBatchAccounting22 Then
		
		// Some periods need to be calculated in version 2.1
		For Each CalculationSchemeLine In CalculationScheme Do
			If EndOfMonth(CalculationSchemeLine.Date) + 1 = DateOfMigrationToBatchAccounting22 // the last month before switching to PU 2.2
			 Or CalculationSchemeLine = CalculationScheme[CalculationScheme.Count() - 1] Then // the last line of the calculation scheme
				Break; // we found a line of the scheme, according to which it is necessary to calculate the batches in version 2.1
			EndIf;
		EndDo;
		
		CalculationOfCostLocalization.CalculateEverything(CalculationSchemeLine.Date, CalculationSchemeLine.Companies, ClosingMonthIsInProgress, AutoTesting);
		
		TaskNumberBeforeCalculation = CostCalculationAppliedAlgorithms.IncreaseTaskNumberForCostCalculation();
	
		BeginTransaction();
		
		Try
			
			OnlyOneOrganization = ?(StartupParameters.Property("OnlyOneOrganization"), StartupParameters.OnlyOneOrganization, False);
			
			// Let's update the calculation scheme
			CalculationScheme = CostCalculationAppliedAlgorithms.BatchCalculationScheme(
				StartupParameters.Date,
				StartupParameters.CompanyArray,
				TaskNumberBeforeCalculation,
				OnlyOneOrganization);
			
			If CalculationScheme.Count() > 0 Then
				TemporaryTable = CostCalculationAppliedAlgorithms.GenerateTTTasksBeforeCalculation(
					TaskNumberBeforeCalculation,
					CalculationScheme[CalculationScheme.Count() - 1].Companies);
			EndIf;
			
			CommitTransaction();
			
		Except
			RollbackTransaction();
			ErrorText = DetailErrorDescription(ErrorInfo());
			Raise ErrorText;
		EndTry;
		
	EndIf;
	
	If CalculationScheme.Count() = 0 Then
		// Calculation is not required
		Comment = StringFunctionsClientServer.SubstituteParametersToString(
			NStr("vi = 'Trong kỳ ""%1"" đến ""%2"", việc tính toán các lô của phiên bản 2.2 là không bắt buộc.';
				|ru = 'За период ""%1"" по ""%2"" расчет партий версии 2.2 не требуется.';
				|en = 'Lot calculation of version 2.2 for the period from ""%1"" to ""%2"" is not required.'; fa = 'Lot calculation of version 2.2 for the period from ""%1"" to ""%2"" is not required.';
				|it = 'Per il periodo da ""%1"" a ""%2"" non è necessario contare i lotti versione 2.2.';
				|pl = 'Za okres ""%1"" wg ""%2"" obliczenie partii wersji 2.2 nie jest potrzebne.';
				|tr = '""%1"" ile ""%2"" arasındaki dönem için sürüm 2.2 lotlarının hesaplanması gerekli değildir.'", Common.DefaultLanguageCode()),
			CostCalculationProtocol.PresentationOfCalculationPeriod(StartupParameters.Date),
			CostCalculationAppliedAlgorithms.CalculatedCompanies(StartupParameters.CompanyArray, ", ", True));
		WriteLogEvent(
			CostCalculationAppliedAlgorithms.EventLogEventName(
				New Structure("BatchCalculationStarted", True),
				NStr("vi = 'Không cần tính toán';
					|ru = 'Расчет не требуется';
					|en = 'Calculation not required'; fa = 'Calculation not required';
					|it = 'Calcolo non richiesto';
					|pl = 'Obliczenie nie jest potrzebne';
					|tr = 'Hesaplama gerekmiyor'", Common.DefaultLanguageCode())),
			EventLogLevel.Information,,,
			Comment);
		Return;
	ElsIf BegOfMonth(CalculationScheme[0].Date) < DateOfMigrationToBatchAccounting22 Then
		// The calculation is impossible - for some reason, the recalculation of periods in version 2.1 has not been performed.
		Comment = StringFunctionsClientServer.SubstituteParametersToString(
			NStr("vi = 'Trong kỳ ""%1"" đến ""%2"", việc tính toán các lô của phiên bản 2.2 là không thể - việc tính toán các lô của phiên bản 2.1 cho các kỳ trước được thực hiện có lỗi.';
				|ru = 'За период ""%1"" по ""%2"" расчет партий версии 2.2 невозможен - расчет партий версии 2.1 за предыдущие периоды выполнен с ошибками.';
				|en = 'Cannot execute lot calculation of version 2.2 for the period from ""%1"" to ""%2"" - errors occurred when executing lot calculation of version 2.1 for the previous periods.'; fa = 'Cannot execute lot calculation of version 2.2 for the period from ""%1"" to ""%2"" - errors occurred when executing lot calculation of version 2.1 for the previous periods.';
				|it = 'Per il periodo da ""%1"" a ""%2"" la contabilità dei lotti versione 2.2 è impossibile - la contabilità dei lotti versione 2.1 per i periodi precedenti è terminata con errori.';
				|pl = 'Za okres ""%1"" wg ""%2"" obliczenie partii wersji 2.2 jest niemożliwe - obliczenie partii wersji 2.1 za poprzednie okresy jest wykonane z błędami.';
				|tr = '""%1"" ila ""%2"" dönemi için sürüm 2.2 lotlarının hesaplanması imkansızdır - önceki dönemler için sürüm 2.1 lotlarının hesaplanması hatalı olarak gerçekleştirilir.'", Common.DefaultLanguageCode()),
			CostCalculationProtocol.PresentationOfCalculationPeriod(StartupParameters.Date),
			CostCalculationAppliedAlgorithms.CalculatedCompanies(StartupParameters.CompanyArray, ", ", True));
		WriteLogEvent(
			CostCalculationAppliedAlgorithms.EventLogEventName(
				New Structure("BatchCalculationStarted", True),
				NStr("vi = 'Không thể tính toán';
					|ru = 'Расчет невозможен';
					|en = 'Cannot calculate'; fa = 'Cannot calculate';
					|it = 'Calcolo non possibile';
					|pl = 'Obliczenie jest niemożliwe';
					|tr = 'Hesaplama yapılamaz'", Common.DefaultLanguageCode())),
			EventLogLevel.Error,,,
			Comment);
		Return;
	EndIf;
	
	#EndRegion
	
	// Let's remember the activity status of the current totals of the serviced registers
	StateOfRegisterTotals = CostCalculationAppliedAlgorithms.StateOfRegisterTotals();
	
	Calculated_Period = CurrentSessionDate();
	
	For Each CalculationSchemeLine In CalculationScheme Do
		
		Calculated_Period = BegOfMonth(CalculationSchemeLine.Date);
		
		If CalculationOfCostCached.ValuesOfTechnologicalParameters().DisableCostCalculationInPastPeriods 
		 And BegOfMonth(CalculationSchemeLine.Date) < BegOfMonth(StartupParameters.Date) Then
			// Skip the calculation periods preceding the current one.
			Continue;
		EndIf;
		
		If Not ClosingMonthIsInProgress Or BegOfMonth(StartupParameters.Date) <> BegOfMonth(CalculationSchemeLine.Date) Then
			// We will perform the operations of the month closing mechanism that are called before the calculation of the stage, if the calculation is not called within the framework of the month closing.
			// When the month is closed, these actions will be performed by the month closing mechanism itself.
			If Not CostCalculationAppliedAlgorithms.PerformMonthClosingOperationsToPrepareForStageCalculation(CalculationSchemeLine, CalculationID, Not ClosingMonthIsInProgress) Then
				Break;
			EndIf;
		EndIf;

		InformationRegisters.SetUpLockFromChanges.CheckLocksBeforeStartingCalculation(
			CalculationSchemeLine.Companies,
			StartupParameters.BeginOfPeriod);
		
		// Initialize the calculation parameters
		ParametersForStartingPeriodCalculation = InitializeParametersForStartingPeriodCalculation(CalculationSchemeLine,
			StartupParameters.BeginOfPeriod, StartupParameters.EndOfPeriod);
		
		ParametersForStartingPeriodCalculation.Insert("AutoTesting", AutoTesting);
		If StartupParameters.Property("PlaceOfCalculationCall") Then
			ParametersForStartingPeriodCalculation.Insert("PlaceOfCalculationCall", StartupParameters.PlaceOfCalculationCall);
		EndIf;
		If StartupParameters.Property("MonthEndClosingMode") Then
			If BegOfMonth(CalculationSchemeLine.Date) < BegOfMonth(StartupParameters.Date) Then
				ParametersForStartingPeriodCalculation.Insert("MonthEndClosingMode", Enums.MonthEndClosingModes.FinalClosing);
			Else
				ParametersForStartingPeriodCalculation.Insert("MonthEndClosingMode", StartupParameters.MonthEndClosingMode);
			EndIf;
		Else
			ParametersForStartingPeriodCalculation.Insert("MonthEndClosingMode", Enums.MonthEndClosingModes.EmptyRef());
		EndIf;
		
		ParametersForStartingPeriodCalculation.Insert("TaskNumberBeforeCalculation", TaskNumberBeforeCalculation);
		
		// Generates temporary tables:
		// - Accounting policies of organizations (accounting policies of calculated organizations)
		// - In the accounting policy of the last period (similar, but for the previous month)
		// - In the rules for filling in the field records (rules for checking primary records of the cost register)
		// - Vtboranalyticapartners (partner analytics keys with calculated organizations)
		// - Inanalytic accounting for partners and reports to the givers (partner analytics keys from the documents "Report to the giver")
		// - In the cost of party goods (an extended analogue of the register of information about the cost of goods with the fields of parties; so far empty).
		CostCalculationAppliedAlgorithms.InitializeBatchCalculationParameters(ParametersForStartingPeriodCalculation, CalculationParameters, DebugParameters);
		
		CalculationParameters.Insert("InitialTasksForCalculatingCost", 	TemporaryTable);
		CalculationParameters.Insert("CalculationIDForClosingMonth", 	CalculationID);
		CalculationParameters.Insert("SaveSLU", True);
		CalculationParameters.Insert("NodeCount",     0);
		CalculationParameters.Insert("NumberOfLocalNodes", 0);
		If StartupParameters.Property("OnlyOneOrganization") Then
			CalculationParameters.Insert("OnlyOneOrganization", 	StartupParameters.OnlyOneOrganization);
		EndIf;
		
		If CalculationParameters.CostCalculationDocuments.Count() = 0 Then
			
			// The current line of the calculation scheme does not require the calculation of the cost.
			// Completing the calculation of the period
			CostCalculationAppliedAlgorithms.RecordGeneratedRegisteredRecords(
				CalculationParameters,
				DebugParameters.CalculationProtocols);
			
			If Not ClosingMonthIsInProgress Or BegOfMonth(StartupParameters.Date) <> BegOfMonth(CalculationSchemeLine.Date) Then
				// We will perform the operations of the month closing mechanism that are called after the calculation of the stage, if the calculation is not called within the framework of the month closing.
				// When the month is closed, these actions will be performed by the month closing mechanism itself.
				CostCalculationAppliedAlgorithms.PerformMonthClosingOperationsToCompleteStageCalculation(CalculationSchemeLine, CalculationID);
			EndIf;
			
			Continue;
			
		EndIf;
		
		// Stage 0 - preparation for the calculation
		// - corrects incorrect source data
		// - performs data validation
		CostCalculationDataPreparation.PreparationOfInitialDataForCalculation(CalculationParameters);
		
		CostCalculationAppliedAlgorithms.CheckCorrectnessOfSourceDataBeforeCalculation(CalculationParameters);
		
		// Stage 1
		// Forms movements according to registers:
		// - Labor cost of perfecting production
		CalculationOfCostLocalization.DistributionOfLaborCosts(CalculationParameters);
		
		// Stage 4
		// Generates movements by registers:
		// - Cost of goods
		CostCalculationMaterialCosts.DistributionOfProductsForProduction(CalculationParameters);
		
		// Stages of distribution of material costs in the localized version.
		CalculationOfCostLocalization.DistributionOfMaterialCosts(CalculationParameters);
		
		// Stage 7
		// Generates temporary tables:
		// - Vtdistribution of other costs
		CostCalculationItemizedCosts.CalculationOfSharesOfDistributionOfOtherCosts(CalculationParameters);
		
		// Stage 8
		// Generates movements by registers:
		// - Cost of goods
		CostCalculationFillingInformationAboutLots.FillingOfLotsInRegisterCostOfGoods(CalculationParameters);
		CostCalculationLaborCosts.DistributionOfLaborCostsForGraduation(CalculationParameters);
		
		CalculationOfCostLocalization.DistributionOfLaborCostsForGraduation(CalculationParameters);
		
		// Stage 5
		// Generates movements by registers:
		// - Cost of goods
		CostCalculationMaterialCosts.DistributionOfProductsForRelease(CalculationParameters);
		
		// Stage 8a
		// Generates movements by registers:
		// - Revenue and cost of sales
		CostCalculationFillingInformationAboutLots.FillingOfLotsInRegisterRevenueAndCostOfSales(CalculationParameters);
		
		// Stage 8b
		// Generates movements by registers:
		// - Cost of goods
		CostCalculationLaborCosts.TransferOfLaborCosts(CalculationParameters);
		
		// Cost calculation stage

		// - The cost of Party goods
		CostCalculationCostAdjustment.AdjustmentOfCostOfRefundsOfCorrectionsOfPastPeriods(StartupParameters, CalculationParameters, DebugParameters);
		CostCalculationFillingInformationAboutLots.ReverseOrderOfCalculationOfBatchesOfCorrectedDocuments(CalculationParameters);
		
		CostCalculationItemizedCosts.DistributeDeviationsInValue(CalculationParameters);
		CostCalculationLESSolution.CostCalculation_ProvisionsForImpairmentOfInventories(CalculationParameters);
		CostCalculationLESSolution.CostCalculation_MaterialAndLaborCosts(CalculationParameters);
		
		// The stage of reflecting the invoice for the delivery of goods using the cost estimation method "Medium-sliding".
		// Generates Registered Records by registers:
		// - Cost of goods
		// - Deviations in the cost of goods
		CostCalculationFillingInformationAboutLots.InvoicingOfDeliveriesAtMediumSlip(CalculationParameters);
		
		// Stage 10
		// Generates movements by registers:
		// - Cost of goods
		// - Other expenses
		// - Lots of other expenses
		// - Movementnotable income expenses
		CostCalculationItemizedCosts.InitializeHIATable(CalculationParameters);
		CostCalculationCostAdjustment.GenerateRegisteredRecordsBasedOnDeviationsInCostOfGoods(CalculationParameters);
		CostCalculationItemizedCosts.DistributionOfAdditionalCostsBetweenPartiesAndGoods(CalculationParameters);
		CostCalculationLESSolution.CostCalculation_AdditionalExpenses(CalculationParameters);
		CostCalculationCostAdjustment.AdjustCostOfAdditionalExpenses(CalculationParameters, True);
		CostCalculationCostAdjustment.StornoSuspendedProductionCosts(CalculationParameters);
		// Stage 11. Distribution of VAT lots in the localized version.
		CalculationOfCostLocalization.DistributionOfVATLots(CalculationParameters, CalculationSchemeLine, 1);
		
		// Generates movements by registers:
		// - Cost of goods
		// - Other expenses
		CalculationOfCostLocalization.IncludeExcludeNDSVCost(CalculationParameters);
		
		// The stage of cost calculation:
		//   - to calculate additional expenses
		//   - for the calculation of upr. and regl. amounts including included/excluded VAT
		// Fills in temporary tables:
		// - The cost of Party goods
		CostCalculationLESSolution.CostCalculation_InclusionExclusionOfVAT(CalculationParameters);
		
		// Stage 14
		// Generates temporary tables:
		// - In-the-out-of-the-way-of-the-way-of-the-way-of-the-way-of-the-way-of-the-way-of-the-way
		// - Vttransit spending between the two
		CostCalculationItemizedCosts.CalculationOfHIATransits(CalculationParameters);

		// Stage 15
		// Generates temporary tables:
		// - Up to production costs (used in the calculation of s/s)
		CostCalculationItemizedCosts.DistributeSharesOfProductionCosts(CalculationParameters);
		
		// Stage 15.1
		// Generates temporary tables:
		// - Direct production costs (used in the calculation of s/s)
		CostCalculationItemizedCosts.DistributeDirectProductionCosts(CalculationParameters);
		
		// Stage 16
		// Generates temporary tables:
		// - vtProchiEraskhoDnezavershennoGoproduction (used in the calculation of s / s).
		CostCalculationItemizedCosts.DistributionOfItemByItemExpensesForOutputProducts(CalculationParameters);
		
		CostCalculationLESSolution.PreparationOfDataForSolvingSLEItemByItemExpensesVATAccounting(CalculationParameters);
		
		// Stage 11.3. Distribution of VAT lots in the localized version.
		CalculationOfCostLocalization.DistributionOfVATLots(CalculationParameters, CalculationSchemeLine, 2);
		
		// Inclusion/exclusion of VAT in the cost in terms of item-by-item production costs.
		CalculationOfCostLocalization.IncludeExcludeNDSVCost(CalculationParameters, True);
		
		// The cost calculation stage:
		//   - to calculate the item-by-item production costs
		//   - to calculate the permanent and temporary difference
		// Fills in temporary tables:
		// - The cost of Party goods
		CalculationOfCostLocalization.PerformRoutineOperation(CalculationParameters);
		CostCalculationLESSolution.CostCalculation_ItemByItemExpensesAndTaxAccounting(CalculationParameters);
		
		// The stage of formation of the cost of personal income tax.
		// Refills temporary tables:
		// - The cost of Party goods
		// - What is the cost of non-perfected productionregl
		// - What is the cost of additional spending?
		// Generates temporary tables:
		// - Vtstoimostind
		CalculationOfCostLocalization.CostCalculation_AITCost(CalculationParameters);
		
		// The stage of correction of negative party balances resulting from the correction of documents.
		// Generates movements by registers:
		// - Cost of goods
		CostCalculationFillingInformationAboutLots.GoodsLotsMisgrading(CalculationParameters);
		
		CostCalculationLESSolution.PreparingDataForCostOfGoods(CalculationParameters);
		
		// Stage 17 (calculation of the actual cost)
		// Generates movements by registers:
		// - See CalculationOfCost.OutgoingMechanismData
		CostCalculationCostAdjustment.GenerateRegisteredRecordsByRegisters(StartupParameters, CalculationParameters, DebugParameters);
		
		// Stage 18
		// Write off sales expenses
		// Generates movements by registers:
		// - Revenue and cost of sales
		// - Other expenses
		CostCalculationItemizedCosts.DistributionOfItemByItemSalesExpenses(CalculationParameters);
		CostCalculationCostAdjustment.GenerateYourSalesExpenses(CalculationParameters);
		
		// Generates movements by registers:
		// - Financial results
		// - Other active arrays
		// - Movements in the registers of the management balance.
		CostCalculationCostAdjustment.GenerateRegisteredRecordsByRegistersFinancialResult(StartupParameters, CalculationParameters, DebugParameters);

		// We record the generated movements and complete the calculation of the period
		CostCalculationAppliedAlgorithms.RecordGeneratedRegisteredRecords(
			CalculationParameters,
			DebugParameters.CalculationProtocols);
		
		If Not ClosingMonthIsInProgress Or BegOfMonth(StartupParameters.Date) <> BegOfMonth(CalculationSchemeLine.Date) Then
			// We will perform the operations of the month closing mechanism that are called after the calculation of the stage, if the calculation is not called within the framework of the month closing.
			// When the month is closed, these actions will be performed by the month closing mechanism itself.
			CostCalculationAppliedAlgorithms.PerformMonthClosingOperationsToCompleteStageCalculation(CalculationSchemeLine, CalculationID);
		EndIf;
		
	EndDo;
	
	// Let's return the activity indicator of the current totals to the state that was before the calculation began.
	If AutoTesting Then
		CostCalculationAppliedAlgorithms.ReturnStateOfRegisterTotals(
			StateOfRegisterTotals,
			EndOfMonth(EndOfMonth(Calculated_Period) + 1)); // at the end of next month
	Else
		CostCalculationAppliedAlgorithms.ReturnStateOfRegisterTotalsByBackgroundJob(StateOfRegisterTotals);
	EndIf;
	
EndProcedure

// Updating the cost of goods by a routine task.
//
// Parameters:
//	Period - Date - the calculation period
//	CalculationParameters - Structure - the calculation parameters are generated in the calling mechanism.
//	DebugParameters - Structure - It is intended for redefining the properties of the structure of the calculation parameters of the same name.
//		For more information, see explanations in the calculation code of the highest values of the individual algorithms.initializeparameterscountparties to the parameterreferences.
//
Procedure CalculatePreliminaryCost(Period = Undefined, CalculationParameters = Undefined, DebugParameters = Undefined) Export
	
	Common.OnStartExecuteScheduledJob(Metadata.ScheduledJobs.CalculationOfCost); // checking whether the task can be started
	
	SetPrivilegedMode(True);
	
	If CalculationOfCostLocalization.PreliminaryCostCalculation(Period) Then
		Return; // A localized calculation was performed
	EndIf;
	
	CalculationID = New UUID;
	
	If Not ValueIsFilled(Period) Then
		Date = CurrentSessionDate();
	Else
		Date = Period;
	EndIf;
	BeginOfPeriod = BegOfMonth(Date);
	EndOfPeriod  = EndOfMonth(Date);
	
	// Initializing Startup parameters
	CompanyArray = CostCalculationAppliedAlgorithms.LinksOfOrganizationsUnderIntercampanyScheme(EndOfPeriod);
	
	InformationRegisters.SetUpLockFromChanges.CheckLocksBeforeStartingCalculation(CompanyArray, BeginOfPeriod);
	
	// Formation of cost allocation documents.
	// The code must comply with the server cost procedure.Perform_allocation of spending().
	
	DistributionOptions = New Array;
	DistributionOptions.Add(Enums.CostAllocationOptions.ToInventoryCost);

	ArticlesForDistribution = Documents.AllocationOfOtherCosts.ArticlesForDistribution(
		EndOfPeriod,
		CompanyArray,
		New Array,
		Enums.CostAllocationStates.DocumentGenerationIsRequired,
		DistributionOptions);
			
	If ArticlesForDistribution.Count() > 0 Then // there is no data for distribution

		ArticlesForDistribution.Columns.Add("Date", New TypeDescription("Date"));
		ArticlesForDistribution.Columns.Add("LineID", New TypeDescription("Number"));
		ArticlesForDistribution.FillValues(EndOfPeriod, "Date");
		
		DistributionParameters = New Structure("ExpenseParameters", ArticlesForDistribution);

		Try
			Documents.AllocationOfOtherCosts.GenerateDocuments(DistributionParameters, Undefined);
		Except
			ErrorText = StringFunctionsClientServer.SubstituteParametersToString(
			NStr("vi = 'Không thể tạo chứng từ phân bổ trong kỳ %1. Đã xảy ra lỗi:
				|%2';
				|ru = 'Не удалось создать документы распределения за период %1. Необходимость возникла из-за ошибки:
				|%2';
				|en = 'Cannot generate allocation document for the period %1. It is needed due to the error:
				|%2'; fa = 'Cannot generate allocation document for the period %1. It is needed due to the error:
				|%2';
				|it = 'Impossibile creare documenti di distribuzione per il periodo. %1. La necessità è causata da un errore:
				|%2';
				|pl = 'Nie można utworzyć dokumentów dystrybucyjnych za okres %1. Potrzeba powstała z powodu błędu:
				|%2';
				|tr = '%1 dönemi için dağıtım belgeleri oluşturulamadı. Gereklilik hata nedeniyle oluştu:
				|%2'", Common.DefaultLanguageCode()),
			CostCalculationProtocol.PresentationOfCalculationPeriod(CalculationParameters.RegistrationPeriod),
			DetailErrorDescription(ErrorInfo()));
			
			WriteLogEvent(
				NStr("vi = 'Tính giá vốn sơ bộ';
					|ru = 'Расчет предварительной себестоимости';
					|en = 'Calculate preliminary cost'; fa = 'محاسبه بهای تمام‌شده مقدماتی';
					|it = 'Il calcolo del costo preliminare';
					|pl = 'Rozliczenie wstępnych kosztów własnych';
					|tr = 'Ön maliyet hesaplaması'", Common.DefaultLanguageCode()),
				EventLogLevel.Warning,
				,
				,
				ErrorText);
		EndTry;
	EndIf;
	
	StartupParameters = New Structure();
	StartupParameters.Insert("Date", 						  			  BeginOfPeriod);
	StartupParameters.Insert("CompanyArray", 						  CompanyArray);
	StartupParameters.Insert("OnlyPreliminaryCostCalculation", True);
	StartupParameters.Insert("StartedByRoutineTask", 			  True);
	StartupParameters.Insert("PreliminaryCalculation",					  True);
	StartupParameters.Insert("PlaceOfCalculationCall", 					  "CalculationOfCost.CalculatePreliminaryCost");
	
	// Initialize the debugging parameters.
	CostCalculationAppliedAlgorithms.InitializeDebuggingOptions(DebugParameters, StartupParameters);
	
	// Initializing calculation parameters
	CostCalculationAppliedAlgorithms.InitializeBatchCalculationParameters(StartupParameters, CalculationParameters, DebugParameters);
	
	CalculationParameters.Insert("CalculationIDForClosingMonth", CalculationID);
	CalculationOfCostLocalization.DistributionOfLaborCosts(CalculationParameters);
	CostCalculationMaterialCosts.DistributionOfProductsForProduction(CalculationParameters);
	CostCalculationLaborCosts.DistributionOfLaborCostsForGraduation(CalculationParameters);
	CostCalculationMaterialCosts.DistributionOfProductsForRelease(CalculationParameters);
	CostCalculationFillingInformationAboutLots.PreparationOfDataForPreliminaryCostCalculation(CalculationParameters);
	
	CostCalculationCostAdjustment.AdjustmentOfCostOfRefundsOfCorrectionsOfPastPeriods(StartupParameters, CalculationParameters, DebugParameters);
	CostCalculationLESSolution.CostCalculation_ProvisionsForImpairmentOfInventories(CalculationParameters);
	CostCalculationLESSolution.CostCalculation_MaterialAndLaborCosts(CalculationParameters);
	
	CostCalculationItemizedCosts.InitializeHIATable(CalculationParameters);
	CostCalculationItemizedCosts.DistributionOfAdditionalCostsBetweenPartiesAndGoods(CalculationParameters);
	CostCalculationLESSolution.CostCalculation_AdditionalExpenses(CalculationParameters);
	CostCalculationLESSolution.CostCalculation_ItemByItemExpensesAndTaxAccounting(CalculationParameters);
	CostCalculationLESSolution.PreparingDataForCostOfGoods(CalculationParameters);
	
	// We record the generated movements and complete the calculation of the period
	CalculationParameters.BatchCalculationStarted = False;
	CalculationParameters.PreliminaryCalculation = True;
	CostCalculationAppliedAlgorithms.CostCalculationMechanismIsPerformed(CalculationParameters, True);
	CostCalculationAppliedAlgorithms.RecordGeneratedRegisteredRecords(
		CalculationParameters,
		DebugParameters.CalculationProtocols);
		
EndProcedure

// Wrapper for starting calculation-performs calculation in An attempt-Exception
// The parameters are similar to the calculate All () procedure.
//
// Returns:
//	Boolean - a sign of successful execution of the calculation.
//
Function CalculateEverythingInOneException(StartupParameters, CalculationParameters = Undefined, DebugParameters = Undefined) Export
	
	Cancel = False;
	
	If Not StartupParameters.Property("BeginOfPeriod") Then
		StartupParameters.Insert("BeginOfPeriod", BegOfMonth(StartupParameters.Date));
		StartupParameters.Insert("EndOfPeriod", EndOfMonth(StartupParameters.Date));
	EndIf;
	
	Try
		If StartupParameters.Property("ScheduledJob") 
		 And StartupParameters.ScheduledJob Then
			CalculatePreliminaryCost(StartupParameters.Date, CalculationParameters, DebugParameters);
		ElsIf StartupParameters.Property("CalculationOfPastPeriods") 
		 And StartupParameters.CalculationOfPastPeriods
		 And StartupParameters.Property("ClosingMonthIsInProgress")
		 And StartupParameters.ClosingMonthIsInProgress Then
		 	CalculateCostOfPastPeriods(StartupParameters.Date, CalculationParameters, DebugParameters);
		Else
			CalculateEverything(StartupParameters,	CalculationParameters, DebugParameters);
		EndIf;
	Except
		
		If Not ValueIsFilled(CalculationParameters) Then
			CalculationParameters = CostCalculationAppliedAlgorithms.InitializeBasicCalculationParameters(
				StartupParameters.BeginOfPeriod,
				StartupParameters.EndOfPeriod,
				StartupParameters.CompanyArray,
				True,
				True);
		EndIf;
		
		// If the calculation was completed in an emergency, then it is necessary to reset the calculation execution flag.
		If CalculationParameters.Property("CalculationIDForClosingMonth") Then
			InformationRegisters.PerformMonthEndClosingOperations.SetEndOfCalculationFlag(CalculationParameters.CalculationIDForClosingMonth);
		EndIf;
		
		ErrorInfo = ErrorInfo();
		
		CostCalculationAppliedAlgorithms.HandleCallExceptionCalculateAll(
			CalculationParameters,
			ErrorInfo,
			Cancel);
		
	EndTry;
	
	Return Not Cancel;
	
EndFunction

// Starts the calculation in the background task.
//
// Returns:
//	Boolean - indicates that the background task has been successfully started.
//
Function CalculateByBackgroundTask(Period, Organization = Undefined) Export
	
	SetPrivilegedMode(True);
	
	If ExchangePlans.MasterNode() <> Undefined
	 Or BackgroundTaskIsActive() Then
		Return False; // the calculation was not started
	EndIf;
	
	JobDescription = NStr("vi = 'Tính toán của các lô hàng và giá vốn';
							|ru = 'Расчет партий и себестоимости';
							|en = 'Lot and cost calculation'; fa = 'محاسبه بچ و بهای تمام‌شده';
							|it = 'Calcolo dei lotti e dei costi di produzione';
							|pl = 'Obliczenie partii i kosztów własnych';
							|tr = 'Lot ve maliyet hesaplama'", Common.DefaultLanguageCode());
	
	StartupParameters = New Structure;
	StartupParameters.Insert("Date", 					    Period);
	StartupParameters.Insert("CompanyArray",  	    Organization);
	
	ExportProcedureParameters = New Array;
	ExportProcedureParameters.Add(StartupParameters);
	
	JobParameters = New Array;
	JobParameters.Add("CalculationOfCost.CalculateEverythingInOneException");
	JobParameters.Add(ExportProcedureParameters);
	
	Var_Key = NameOfBackgroundJob();
	
	BackgroundJobs.Execute("Common.ExecuteConfigurationMethod", JobParameters, Var_Key, JobDescription);
	
	Return True; // calculation started
	
EndFunction

// Returns the name of the background predefined batch calculation task.
//
// Returns:
//	String - name of the background task
//
Function NameOfBackgroundJob() Export
	Return "BatchAccounting";
EndFunction

// Checks for an active task of calculating the parties.
//
// Returns:
//	Boolean - indication of background task activity
//
Function BackgroundTaskIsActive() Export
	
	JobKey = NameOfBackgroundJob();
	
	Filter = New Structure();
	Filter.Insert("Key", JobKey);
	Filter.Insert("State", BackgroundJobState.Active);
	
	ActiveTasks = BackgroundJobs.GetBackgroundJobs(Filter);
	
	If ActiveTasks.Count() > 0 Then
		BackgroundTaskIsActive = True;
	Else
		BackgroundTaskIsActive = False;
	EndIf;
	
	Return BackgroundTaskIsActive;
	
EndFunction

// Determines the need to recalculate the cost of past periods.
// 
// Parameters:
//  CompanyArray - CatalogRef.Companies, Array of CatalogRef.Companies - Organizations To Check
// 
// Returns:
//  Date - date of the earliest period requiring recalculation
Function ItIsRequiredToRecalculateCostOfPastPeriods(CompanyArray) Export
	
	RecalculationPeriod = Date(1,1,1);
	
	Query = New Query;
	Query.TempTablesManager = New TempTablesManager;
	Query.SetParameter("CompanyArray", 	TMCommonUseClientServer.Array(CompanyArray));
	
	Query.Text =
	"SELECT ALLOWED
	|	T.ParentCompany AS ParentCompany,
	|	T.Ref AS Organization
	|INTO TTParentOrganizations
	|FROM
	|	Catalog.Companies AS T
	|WHERE
	|	T.Ref IN(&CompanyArray)
	|
	|INDEX BY
	|	ParentCompany
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	T.Organization AS Organization
	|INTO FilterCompanies
	|FROM
	|	TTParentOrganizations AS T
	|		INNER JOIN InformationRegister.FinancialAccountingPolicy.SliceLast() AS AccountingPolicy
	|		ON (AccountingPolicy.Organization = T.ParentCompany)
	|WHERE
	|	AccountingPolicy.AllocateVariancesInPreviousPeriods
	|	AND AccountingPolicy.InventoryValuationMethod <> VALUE(Enum.InventoryValuationMethods.MovingAverage)
	|
	|INDEX BY
	|	Organization
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	T.Organization AS Organization,
	|	MIN(BEGINOFPERIOD(T.Month, Month)) AS Period
	|INTO TTPeriods
	|FROM
	|	InformationRegister.JobsForCalculatingCost AS T
	|	INNER JOIN FilterCompanies AS Filter
	|		ON T.Organization = Filter.Organization
	|GROUP BY
	|	T.Organization
	|INDEX BY
	|	Organization
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	MIN(T.Period) AS Period
	|FROM
	|	TTPeriods AS T
	|";

	Selection = Query.Execute().Select();
	
	If Selection.Next() And ValueIsFilled(Selection.Period) Then
		Query.SetParameter("BeginOfPeriod", BegOfMonth(Selection.Period)); // for preliminary selection of processed data
	Else
		Return RecalculationPeriod;
	EndIf;
	
	Query.Text =
	"SELECT
	|	MIN(T.VariancePeriod) AS VariancePeriod
	|FROM
	// The request is similar to the calculation of the value of the solution to the node.Worshiping the prochier spending on Distribution()
	|(SELECT DISTINCT
	|	BEGINOFPERIOD(T.VariancePeriod, MONTH) AS VariancePeriod
	|FROM
	|	AccumulationRegister.OtherExpenses AS T
	|		INNER JOIN TTPeriods AS Filter
	|		ON T.Organization = Filter.Organization
	|		AND T.Period >= Filter.Period
	|WHERE
	|	T.Period >= &BeginOfPeriod
	|	AND T.VariancePeriod <> DATETIME(1, 1, 1)
	|	AND T.Active
	|
	|GROUP BY
	|	BEGINOFPERIOD(T.VariancePeriod, MONTH),
	|	T.Organization,
	|	T.Department,
	|	T.LineOfBusiness,
	|	T.ExpenseItem,
	|	T.DimensionOfExpenses
	|
	|HAVING
	|	(SUM(CASE
	|				WHEN T.RecordType = VALUE(AccumulationRecordType.Receipt)
	|					THEN T.Sum
	|				ELSE -T.Sum
	|			END) <> 0
	|		OR SUM(CASE
	|				WHEN T.RecordType = VALUE(AccumulationRecordType.Receipt)
	|					THEN T.AmountExcludingVAT
	|				ELSE -T.AmountExcludingVAT
	|			END) <> 0
	|		OR SUM(CASE
	|				WHEN T.RecordType = VALUE(AccumulationRecordType.Receipt)
	|					THEN T.SumCompl
	|				ELSE -T.SumCompl
	|			END) <> 0
	|		OR SUM(CASE
	|				WHEN T.RecordType = VALUE(AccumulationRecordType.Receipt)
	|					THEN T.SumMan
	|				ELSE -T.SumMan
	|			END) <> 0
	|		OR SUM(CASE
	|				WHEN T.RecordType = VALUE(AccumulationRecordType.Receipt)
	|					THEN T.PermanentDifference
	|				ELSE -T.PermanentDifference
	|			END) <> 0
	|		OR SUM(CASE
	|				WHEN T.RecordType = VALUE(AccumulationRecordType.Receipt)
	|					THEN T.CostTD
	|				ELSE -T.CostTD
	|			END) <> 0
	|		OR SUM(CASE
	|				WHEN T.RecordType = VALUE(AccumulationRecordType.Receipt)
	|					THEN T.SumCompl - T.PermanentDifference - T.CostTD
	|				ELSE -(T.SumCompl - T.PermanentDifference - T.CostTD)
	|			END) <> 0
	|		OR SUM(CASE
	|				WHEN T.RecordType = VALUE(AccumulationRecordType.Receipt)
	|					THEN T.AITAmount
	|				ELSE -T.AITAmount
	|			END) <> 0)
	|
	|UNION ALL
	|
	// The request is similar to the calculation of the value of the solution to the node.Worshiping the Distribution()
	|SELECT DISTINCT
	|	BEGINOFPERIOD(T.VariancePeriod, MONTH) AS VariancePeriod
	|FROM
	|	AccumulationRegister.InventoryCost AS T
	|		INNER JOIN TTPeriods AS Filter
	|		ON T.Organization = Filter.Organization
	|		AND T.Period >= Filter.Period
	|WHERE
	|	T.Period >= &BeginOfPeriod
	|	AND T.VariancePeriod <> DATETIME(1, 1, 1)
	|	AND T.Active
	|	AND (NOT T.CalculationOfCost
	|				AND NOT T.LotCalculation
	|			OR T.BusinessOperation = VALUE(Enum.BusinessTransactions.WriteOffVariancesToAllocate))
	|
	|GROUP BY
	|	BEGINOFPERIOD(T.VariancePeriod, MONTH),
	|	T.ItemsLocationAttributes,
	|	T.AccountingSection,
	|	T.Organization,
	|	T.InventoryOwnerAttribute,
	|	T.Lot,
	|	T.LotVendorAttributes,
	|	T.FinancialAccountingDimension,
	|	T.VATActivityType
	|
	|HAVING
	|	(SUM(CASE
	|				WHEN T.RecordType = VALUE(AccumulationRecordType.Receipt)
	|					THEN T.AddExpensesForGoods
	|				ELSE -T.AddExpensesForGoods
	|			END) <> 0
	|		OR SUM(CASE
	|				WHEN T.RecordType = VALUE(AccumulationRecordType.Receipt)
	|					THEN T.AdditionalExpensesExcludingVAT
	|				ELSE -T.AdditionalExpensesExcludingVAT
	|			END) <> 0
	|		OR SUM(CASE
	|				WHEN T.RecordType = VALUE(AccumulationRecordType.Receipt)
	|					THEN T.AddExpensesLocal
	|				ELSE -T.AddExpensesLocal
	|			END) <> 0
	|		OR SUM(CASE
	|				WHEN T.RecordType = VALUE(AccumulationRecordType.Receipt)
	|					THEN T.AddExpensesMan
	|				ELSE -T.AddExpensesMan
	|			END) <> 0
	|		OR SUM(CASE
	|				WHEN T.RecordType = VALUE(AccumulationRecordType.Receipt)
	|					THEN T.PermanentDifference
	|				ELSE -T.PermanentDifference
	|			END) <> 0
	|		OR SUM(CASE
	|				WHEN T.RecordType = VALUE(AccumulationRecordType.Receipt)
	|					THEN T.CostTD
	|				ELSE -T.CostTD
	|			END) <> 0
	|		OR SUM(CASE
	|				WHEN T.RecordType = VALUE(AccumulationRecordType.Receipt)
	|					THEN T.CostOfPersonalIncomeTax
	|				ELSE -T.CostOfPersonalIncomeTax
	|			END) <> 0)
	|) AS T";
	
	Selection = Query.Execute().Select();
	If Selection.Next() And ValueIsFilled(Selection.VariancePeriod) Then
		RecalculationPeriod = BegOfMonth(Selection.VariancePeriod);
	EndIf;
	
	Return RecalculationPeriod;
	
EndFunction

// Performs recalculation of the cost price for past periods.
// 
// Parameters:
//  Period - Date - the calculation period
//  CompanyArray - Array of CatalogRef.Companies - Array of organizations to recalculate
// 
Procedure CalculatePastPeriods(Period, CompanyArray) Export
	
	StartupParameters = New Structure;
	StartupParameters.Insert("Date", 					    BegOfMonth(Period));
	StartupParameters.Insert("CompanyArray",  	    CompanyArray);
	StartupParameters.Insert("OnlyOneOrganization",		False);
	StartupParameters.Insert("PlaceOfCalculationCall", 	    "CalculationOfCost.CalculatePastPeriods");
	StartupParameters.Insert("ClosingMonthIsInProgress",  False);
	StartupParameters.Insert("CalculationOfPastPeriods",  	True);
	StartupParameters.Insert("CalculationID", 		New UUID);
	
	CalculateEverythingInOneException(StartupParameters);
	
EndProcedure

// Performs recalculation of the cost price for past periods.
//
// Parameters:
//	Period - Date - the calculation period
//	CalculationParameters - Structure - the calculation parameters are generated in the calling mechanism.
//	DebugParameters - Structure - It is intended for redefining the properties of the structure of the calculation parameters of the same name.
//		For more information, see explanations in the calculation code of the highest values of the individual algorithms.initializeparameterscountparties to the parameterreferences.
//
Procedure CalculateCostOfPastPeriods(Period = Undefined, CalculationParameters = Undefined, DebugParameters = Undefined) Export
	
	SetPrivilegedMode(True);
	
	CalculationID = New UUID;
	
	If Not ValueIsFilled(Period) Then
		Date = CurrentSessionDate();
	Else
		Date = Period;
	EndIf;
	BeginOfPeriod = BegOfMonth(Date);
	EndOfPeriod  = EndOfMonth(Date);
	
	// Initializing Startup parameters
	CompanyArray = CostCalculationAppliedAlgorithms.LinksOfOrganizationsUnderIntercampanyScheme(EndOfPeriod);
	
	InformationRegisters.SetUpLockFromChanges.CheckLocksBeforeStartingCalculation(CompanyArray, BeginOfPeriod);
	
	StartupParameters = New Structure();
	StartupParameters.Insert("Date", 						  			  BeginOfPeriod);
	StartupParameters.Insert("CompanyArray", 						  CompanyArray);
	StartupParameters.Insert("PlaceOfCalculationCall", 					  "CalculationOfCost.CalculatePastPeriods");
	
	// Initialize the debugging parameters.
	CostCalculationAppliedAlgorithms.InitializeDebuggingOptions(DebugParameters, StartupParameters);
	
	// Initializing calculation parameters
	CostCalculationAppliedAlgorithms.InitializeBatchCalculationParameters(StartupParameters, CalculationParameters, DebugParameters);
	
	CalculationParameters.Insert("CalculationIDForClosingMonth", CalculationID);
	
	CostCalculationCostAdjustment.AdjustmentOfCostOfRefundsOfCorrectionsOfPastPeriods(StartupParameters, CalculationParameters, DebugParameters);
	
	CostCalculationLESSolution.CostCalculation_ProvisionsForImpairmentOfInventories(CalculationParameters);
	CostCalculationLESSolution.CostCalculation_MaterialAndLaborCosts(CalculationParameters);
	
	CostCalculationItemizedCosts.DistributionOfAdditionalCostsBetweenPartiesAndGoods(CalculationParameters);
	CostCalculationLESSolution.CostCalculation_AdditionalExpenses(CalculationParameters);
			
	CostCalculationAppliedAlgorithms.RecordGeneratedRegisteredRecords(
		CalculationParameters,
		DebugParameters.CalculationProtocols);
	
EndProcedure

#EndRegion

#Region Private

#Region Initialize

// Initializes parameters for starting the period calculation.
//
Function InitializeParametersForStartingPeriodCalculation(CalculationSchemeLine, BeginOfPeriod, EndOfPeriod)
	
	ParametersForStartingPeriodCalculation = New Structure;
	ParametersForStartingPeriodCalculation.Insert("Date", 			  CalculationSchemeLine.Date);
	If EndOfPeriod <= CalculationSchemeLine.Date Then
		ParametersForStartingPeriodCalculation.Insert("BeginOfPeriod",  BeginOfPeriod);
		ParametersForStartingPeriodCalculation.Insert("EndOfPeriod",   EndOfPeriod);
	Else
		ParametersForStartingPeriodCalculation.Insert("BeginOfPeriod",  BegOfMonth(CalculationSchemeLine.Date));
		ParametersForStartingPeriodCalculation.Insert("EndOfPeriod",   EndOfMonth(CalculationSchemeLine.Date));
	EndIf;
	ParametersForStartingPeriodCalculation.Insert("CompanyArray",  CalculationSchemeLine.Companies);
	ParametersForStartingPeriodCalculation.Insert("DocumentsChanged", CalculationSchemeLine.DocumentsChanged);
	
	Return ParametersForStartingPeriodCalculation;
	
EndFunction

#EndRegion

#Region UniversalProceduresForWorkingWithRegisteredRecords

// To call from the batch accounting mechanism version 2.2

// Adds a new row to the table of movements of the specified register and fills in the service fields.
// Made export for calling from the module of universal calculation mechanisms.
//
// Returns:
//	ValueTableRow - added a row to the table of movements.
//
Function AddEntryToMovementTable(CalculationParameters, DestinationTable, MotionData,
			CopiedFields = Undefined, ServiceFields = Undefined) Export
	
	If CalculationParameters.RegisterRecords.Property(DestinationTable) Then
		ReceiverDescription = CalculationParameters.RegisterRecords[DestinationTable];
		ThisIsCostRegister = (ReceiverDescription.RegisterName = Metadata.AccumulationRegisters.InventoryCost.Name);
	Else
		ReceiverDescription = CalculationParameters.AuxiliaryTemporaryTables[DestinationTable];
	EndIf;
	
	// Let's add a record by a universal procedure, and then fill in the fields related only to the calculation of batches.
	Record = CostCalculationAppliedAlgorithms.AddEntryToMovementTable(
		CalculationParameters,
		ReceiverDescription,
		MotionData,
		CopiedFields);
	
	If ReceiverDescription.ThisIsRegisterDescription And ReceiverDescription.ThereIsCalculationNotCompleted And ValueIsFilled(ServiceFields) Then
		
		// The calculation field is not completed, it is formed in the calculation of the highest and most appropriate rhythms.Cache Distributed parties().
		FillPropertyValues(Record, ServiceFields);
		
	EndIf;
	
	If ReceiverDescription.ThisIsRegisterDescription And ThisIsCostRegister And CalculationParameters.LotsAreFilledInAtCostPrice Then
		
		// Fill in the Parties calculation field to record the inventory cost register:
		// - at the stage of filling in the cost batches, the fields of the primary movements of documents
		//   are replenished. For such movements, the calculation of parties attribute remains equal to False
		// - at the same stage, new records are also generated, which are calculated (not primary);
		//	 the sign of the settlement batch is determined by the following conditions (by OR)
		// 		= the type of movement recording is not used in the Template of the cost register (i.e., the movement cannot exactly be primary)
		// 		= it is explicitly indicated for the record that it is calculated (the attribute is set to Current settlement movement).
		
		Record.LotCalculation =
			MotionData.ThisIsExactlyCalculatedMovement
			Or CalculationOfCostCached.ThisIsOnlyCalculatedRecordType(Record.EntryType);
		
	EndIf;
	
	// If the registrar is not filled in, then we will remember the error information
	If ReceiverDescription.ThisIsRegisterDescription And Not ValueIsFilled(Record.Recorder) Then
		
		If Not ValueIsFilled(MotionData.Recorder) Then
			// Error in requests - the required Registrar field is not filled in.
			ProtocolText_ = StringFunctionsClientServer.SubstituteParametersToString(
				NStr("vi = 'Chưa điền thuộc tính Nguồn ghi trong dữ liệu để tạo bản ghi kết chuyển theo biểu ghi ""%1""';
					|ru = 'Не заполнено свойство Регистратор в данных для формирования движений по регистру ""%1""';
					|en = 'Recorder property in data for generating records of the ""%1"" register is not filled in'; fa = 'Recorder property in data for generating records of the ""%1"" register is not filled in';
					|it = 'Non è compilata la proprietà Registrazione nei dati di creazione dei movimenti per il registro ""%1""';
					|pl = 'Nie wypełniono właściwość Rejestrаtor w danych do utworzenia ruchów w rejestrze ""%1""';
					|tr = '""%1"" kaydındaki hareketleri oluşturma verilerindeki Kayıt özelliği doldurulmadı'", Common.DefaultLanguageCode()),
				DestinationTable);
		Else
			// Error in metadata - the document is not a registrar for this register.
			ProtocolText_ = StringFunctionsClientServer.SubstituteParametersToString(
				NStr("vi = 'Chứng từ ""%1"" không thể có bản ghi kết chuyển theo biểu ghi ""%2""';
					|ru = 'Документ ""%1"" не может иметь движений по регистру ""%2""';
					|en = 'The ""%1"" document cannot have records in the ""%2"" register'; fa = 'The ""%1"" document cannot have records in the ""%2"" register';
					|it = 'Il documento ""%1"" non può avere movimenti per il registro ""%2""';
					|pl = 'Dokument ""%1"" nie może mieć ruchów w rejestrze ""%2""';
					|tr = '""%1"" belgesinin ""%2"" kaydı üzerinde hareketleri olamaz'", Common.DefaultLanguageCode()),
				TrimAll(MotionData.Recorder),
				DestinationTable);
		EndIf;
		
		CostCalculationProtocol.FixCalculationError(
			CalculationParameters,
			Enums.TypesOfLotAccountingAndCostErrors.AnErrorOccurredWhenGeneratingRecordsInRegisters,
			ProtocolText_);
		
		If ReceiverDescription.ThereIsACompany Then
			OrganizationWithProblem = MotionData.Organization;
		ElsIf ReceiverDescription.ThereAreAnalyticsPartners Then
			PartnerAnalyticsOrganization = CalculationParameters.PartnerAnalyticsOrganization; // Map
			OrganizationWithProblem = PartnerAnalyticsOrganization.Get(MotionData.AccountingDimensionByPartners);
		Else
			OrganizationWithProblem = Undefined;
		EndIf;
		
		CostCalculationAppliedAlgorithms.RegisterCalculationExecutionProblem(
			CalculationParameters,
			OrganizationWithProblem,
			NStr("vi = 'Khi tạo bản ghi kết chuyển, đã chuẩn đoán được lỗi';
				|ru = 'При формировании движений диагностированы ошибки';
				|en = 'Errors were found when generating the movements'; fa = 'Errors were found when generating the movements';
				|it = 'Durante la creazione dei movimenti sono stati diagnosticati degli errori';
				|pl = 'Podczas tworzenia ruchów zdiagnozowano błędy';
				|tr = 'Hareketlerin oluşumunda hatalar tespit edilmiştir'", Common.DefaultLanguageCode()),
			ProtocolText_,
			MotionData.Recorder);
		
	EndIf;
	
	Return Record;
	
EndFunction

Procedure AddDescriptionOfFieldsForGeneratingRegisteredRecords(CalculationParameters, FieldDescriptionTable, ReceiverDescription, CopiedFields) Export
	
	If ReceiverDescription.ThisIsRegisterDescription And ReceiverDescription.ThereIsCalculationNotCompleted
	 And StrFind(Lower(CopiedFields), Lower("CalculationIsNotCompleted")) > 0 Then
		CostCalculationAppliedAlgorithms.ChangeFieldInRequestFieldDescription(FieldDescriptionTable, "CalculationIsNotCompleted",
			"NOT CalculationIsCompleted");
	EndIf;
	
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
// Returns:
//	Map - The key is the Metadata object.
//
Function IncomingMechanismData(IncomingData = Undefined, OnlyRequiringRecalculation = False) Export
	
	If IncomingData = Undefined Then
		IncomingData = New Map;
	EndIf;
	
	If OnlyRequiringRecalculation Then
		Value = True; // so that you can check the occurrence of a metadata object in this correspondence
	Else
		Value = Undefined;
	EndIf;
	
	If Not OnlyRequiringRecalculation Then 
		
		IncomingData.Insert(Metadata.Documents.TransferOrder, Value);
		IncomingData.Insert(Metadata.Documents.ByAssemblyDisassemblyOrder, Value);
		IncomingData.Insert(Metadata.Documents.PurchaseOrder, Value);
		
		IncomingData.Insert(Metadata.Documents.InventoryConsumption, Value);
		IncomingData.Insert(Metadata.Documents.CustomerInvoiceIntercompany, Value);
		IncomingData.Insert(Metadata.Documents.VendorInvoice, Value);
		IncomingData.Insert(Metadata.Documents.OtherGoodsRecordingAsReceived, Value);
		IncomingData.Insert(Metadata.Documents.CCDImport, Value);
		
		IncomingData.Insert(Metadata.Documents.SubcontractOrder2_5, Value);
		IncomingData.Insert(Metadata.Documents.SubcontractorReport2_5, Value);
		IncomingData.Insert(Metadata.Documents.BackflushProduction, Value);
		IncomingData.Insert(Metadata.Documents.MaterialProviderOrder2_5, Value);
		IncomingData.Insert(Metadata.InformationRegisters.ItemsLocationAttributes, Value);
		IncomingData.Insert(Metadata.InformationRegisters.ItemsPrices, Value);
		IncomingData.Insert(Metadata.InformationRegisters.AllocationBaseForIndirectExpensesAllocation, Value);
		IncomingData.Insert(Metadata.InformationRegisters.IndicatorValuesToAllocateCosts, Value);
		IncomingData.Insert(Metadata.ChartsOfCharacteristicTypes.AssetLiabilityItems, Value);
		IncomingData.Insert(Metadata.ChartsOfCharacteristicTypes.ExpenseItems, Value);
		
		IncomingData.Insert(Metadata.Catalogs.InventoryKinds, Value);
		IncomingData.Insert(Metadata.Catalogs.InventoryLocationAttributeKeys, Value);
		IncomingData.Insert(Metadata.Catalogs.KeysForLotVendorAttributes, Value);
		IncomingData.Insert(Metadata.Catalogs.Assignments, Value);
		IncomingData.Insert(Metadata.Catalogs.Products, Value);
		IncomingData.Insert(Metadata.Catalogs.Warehouses, Value);
		IncomingData.Insert(Metadata.Catalogs.BusinessStructure, Value);
		IncomingData.Insert(Metadata.Catalogs.ProductionLots, Value);
		IncomingData.Insert(Metadata.Catalogs.CostAllocationRules, Value);
		IncomingData.Insert(Metadata.Catalogs.BillsOfMaterials, Value);
		IncomingData.Insert(Metadata.Catalogs.ProductionStages, Value);
	EndIf;
	
	IncomingData.Insert(Metadata.AccumulationRegisters.TransferOrders, Value);
	IncomingData.Insert(Metadata.AccumulationRegisters.AssemblyOrders, Value);
	IncomingData.Insert(Metadata.AccumulationRegisters.PurchaseOrders, Value);
	
	IncomingData.Insert(Metadata.AccumulationRegisters.ItemisedExpensesLots, Value);
	IncomingData.Insert(Metadata.AccumulationRegisters.OtherExpenses, Value);
	IncomingData.Insert(Metadata.AccumulationRegisters.InventoryCost, Value);
	IncomingData.Insert(Metadata.AccumulationRegisters.GoodsCostVariances, Value);
	IncomingData.Insert(Metadata.AccumulationRegisters.CompanyGoods, Value);
	IncomingData.Insert(Metadata.Documents.ProductionCostAllocation, Value);
	IncomingData.Insert(Metadata.Documents.AllocationOfOtherCosts, Value);
	
	IncomingData.Insert(Metadata.AccumulationRegisters.ProductsRelease, Value);
	IncomingData.Insert(Metadata.AccumulationRegisters.OtherWorkInProgressExpenses, Value);
	IncomingData.Insert(Metadata.Documents.ProductionStage2_2, Value);
	IncomingData.Insert(Metadata.Documents.ProductionOrder2_2, Value);
	CalculationOfCostLocalization.IncomingMechanismData(IncomingData, OnlyRequiringRecalculation);
	
	Return IncomingData;
	
EndFunction

// Returns a list of registers served by the batch calculation engine.
//
// Returns:
//	Map - The key is the Metadata object.
//
Function OutgoingMechanismData(OutgoingData = Undefined) Export
	
	// A list of metadata registers, according to which movements are formed by parties.
	If OutgoingData = Undefined Then
		OutgoingData = New Map;
	EndIf;
	
	OutgoingData.Insert(Metadata.AccumulationRegisters.RegisterRecordsProductsIncomeExpenses,		True);
	OutgoingData.Insert(Metadata.AccumulationRegisters.RecordsProductsProducts,		True);
	OutgoingData.Insert(Metadata.AccumulationRegisters.MaterialsAndWorksInProduction, 			True);
	OutgoingData.Insert(Metadata.AccumulationRegisters.ItemisedExpensesLots, 					True);
	OutgoingData.Insert(Metadata.AccumulationRegisters.InventoryCost, 					True);
	OutgoingData.Insert(Metadata.AccumulationRegisters.GoodsCostVariances, 			True);
	OutgoingData.Insert(Metadata.AccumulationRegisters.RevenueAndCOGS, 			True);
	OutgoingData.Insert(Metadata.AccumulationRegisters.OtherExpenses, 							True);
	OutgoingData.Insert(Metadata.AccumulationRegisters.OtherIncome, 							True);
	OutgoingData.Insert(Metadata.AccumulationRegisters.RevenueServicesAndAssets, 							True);
	OutgoingData.Insert(Metadata.AccumulationRegisters.OtherAssetsLiabilities,						True);
	OutgoingData.Insert(Metadata.AccumulationRegisters.OtherWorkInProgressExpenses, True);
	OutgoingData.Insert(Metadata.AccumulationRegisters.WIPLaborCosts,  True);
	OutgoingData.Insert(Metadata.AccumulationRegisters.CompanyGoods,                       True);
	CalculationOfCostLocalization.OutgoingMechanismData(OutgoingData);
	
	Return OutgoingData;
	
EndFunction

// Returns the name of this mechanism and its version number.
//
// Returns:
//	String - mechanism version
//
Function CurVersionOfMechanism() Export
	Return NStr("vi = 'Kế toán theo lô, phiên bản 2.2';
				|ru = 'Партионный учет, версия 2.2';
				|en = 'Lot accounting, version 2.2'; fa = 'Lot accounting, version 2.2';
				|it = 'Contabilità a lotti, versione 2.2';
				|pl = 'Ewidencja partii, wersja 2.2';
				|tr = 'Lot muhasebesi, sürüm 2.2'", Common.DefaultLanguageCode());
EndFunction

#EndRegion

#Region Testing

Function StagesWithBatchDistribution() Export
	
	StageList = New ValueList;
	
	CostCalculationFillingInformationAboutLots.SupplementStagesWithDistributionOfBatches(StageList);
	CostCalculationItemizedCosts.SupplementStagesWithDistributionOfBatches(StageList);
	CostCalculationMaterialCosts.SupplementStagesWithDistributionOfBatches(StageList);
	CostCalculationLaborCosts.SupplementStagesWithDistributionOfBatches(StageList);
	CalculationOfCostLocalization.SupplementStagesWithDistributionOfBatches(StageList);
	
	Return StageList;
	
EndFunction

Function StagesWithBatchTranslation() Export
	
	StageList = New ValueList;
	
	CostCalculationFillingInformationAboutLots.AddStagesWithBatchTranslation(StageList);
	CostCalculationItemizedCosts.AddStagesWithBatchTranslation(StageList);
	CalculationOfCostLocalization.AddStagesWithBatchTranslation(StageList);
	CostCalculationLESSolution.AddStagesWithBatchTranslation(StageList);
	
	Return StageList;
	
EndFunction

Function StepsWithDataPreparationForFollowingSteps() Export
	
	StageList = New ValueList;
	
	CostCalculationFillingInformationAboutLots.ComplementStepsWithDataPreparationForFollowingSteps(StageList);
	VATCostCalculation.ComplementStepsWithDataPreparationForFollowingSteps(StageList);
	CostCalculationLESSolution.ComplementStepsWithDataPreparationForFollowingSteps(StageList);
	CostCalculationCostAdjustment.ComplementStepsWithDataPreparationForFollowingSteps(StageList);
	CalculationOfCostLocalization.ComplementStepsWithDataPreparationForFollowingSteps(StageList);
	
	Return StageList;
	
EndFunction

Function RequestTextForStageCalculation(StageName_, CalculationParameters = Undefined) Export
	
	QueryText = "";
	CostCalculationFillingInformationAboutLots.RequestTextForStageCalculation(StageName_, CalculationParameters, QueryText);
	CostCalculationItemizedCosts.RequestTextForStageCalculation(StageName_, CalculationParameters, QueryText);
	CostCalculationMaterialCosts.RequestTextForStageCalculation(StageName_, CalculationParameters, QueryText);
	CostCalculationLaborCosts.RequestTextForStageCalculation(StageName_, CalculationParameters, QueryText);
	CostCalculationLESSolution.RequestTextForStageCalculation(StageName_, CalculationParameters, QueryText);
	CostCalculationCostAdjustment.RequestTextForStageCalculation(StageName_, CalculationParameters, QueryText);
	CalculationOfCostLocalization.RequestTextForStageCalculation(StageName_, CalculationParameters, QueryText);
	
	Return QueryText;
	
EndFunction

#EndRegion

#EndRegion
