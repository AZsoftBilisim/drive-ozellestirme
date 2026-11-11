#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then
	
#Region Public

// The procedure performs background execution
//
// Parameters:
//	CalculationParameters - Structure - a set of parameters for background conducting:
//		*StandardCostEstimate - DocumentRef.StandardCosting2_2 - link to the document.
//	CalculationsForVerification - Array, Undefined - links to planned calculations to check the calculation. 
//
Procedure PerformSurvey(CalculationParameters, CalculationsForVerification = Undefined) Export
	
	DefineCalculationParameters(CalculationParameters);
	
	If Not CalculationParameters.ThisIsHolding Then
		CancelDocument(CalculationParameters.StandardCostEstimate, CalculationParameters);
		Return;
	EndIf;
	
	Measurement = PerformanceMonitor.StartTimeConsumingOperationMeasurement("InformationRegister.MultiplesOfLotsAndSemiFinishedProducts.UnravelProducts_");
	CalculationParameters.Insert("Measurement", Measurement);
		
	If CalculationParameters.PCDetails.Date = Undefined Then
		RecordStateOfCalculation(CalculationParameters.StandardCostEstimate, 
			Enums.StatesOfStandardCostEstimateCalculation.CalculationError);
		InformationRegisters.CalculationQueueOfStandardCostEstimates.ClearQueue(CalculationParameters.StandardCostEstimate);
		LogCalculationError(CalculationParameters.StandardCostEstimate, 
			NStr("vi = 'Nhiệm vụ tính toán trên nền được khởi động từ trước ghi nhận thao tác ghi lại chứng từ. Cần kết chuyển lại chứng từ.';
				|ru = 'Фоновое задания расчета запустилось раньше фиксации транзакции записи документа. Требуется перепровести документ.';
				|en = 'Background job for calculation started before the document posting. Repost the document.'; fa = 'Background job for calculation started before the document posting. Repost the document.';
				|it = 'Фоновое задания расчета запустилось раньше фиксации транзакции записи документа. Требуется перепровести документ.';
				|pl = 'Background job for calculation started before the document posting. Repost the document.';
				|tr = 'Arka plan hesaplama işi, belge kaydı işlemi işlenmeden önce başladı. Belgenin yeniden gözden geçirilmesi gerekmektedir.'"));
		Return;
	EndIf;
	
	PostDocument(CalculationParameters);
	PerformanceMonitor.FixTimeConsumingOperationMeasure(Measurement, CalculationParameters.DataVolume, "PostDocument");
	CalculationParameters.DataVolume = 0;
	
	CalculateNeeds(CalculationParameters);
	PerformanceMonitor.FixTimeConsumingOperationMeasure(Measurement, CalculationParameters.DataVolume, "CalculateNeeds");
	CalculationParameters.DataVolume = 0;
	
	If ThereWasCancellationOfEvent(CalculationParameters.StandardCostEstimate) Then
		CancelDocument(CalculationParameters.StandardCostEstimate, CalculationParameters);
		Return;
	EndIf;
		
	FillInCosts(CalculationParameters);
	PerformanceMonitor.FixTimeConsumingOperationMeasure(Measurement, CalculationParameters.DataVolume, "FillInCosts");
	CalculationParameters.DataVolume = 0;
	
	AddCalculationToValidation(CalculationParameters.StandardCostEstimate, CalculationsForVerification);
	
	If ThereWasCancellationOfEvent(CalculationParameters.StandardCostEstimate) Then
		CancelDocument(CalculationParameters.StandardCostEstimate, CalculationParameters);
		Return;
	EndIf;
	
	PerformanceMonitor.EndTimeConsumingOperationMeasurement(Measurement, CalculationParameters.DataVolume);
	
	DocumentForCarryingOut = DocumentQueued(CalculationParameters.StandardCostEstimate);
	If Not DocumentForCarryingOut = Undefined Then
		PerformSurvey(New Structure("StandardCostEstimate", DocumentForCarryingOut), CalculationsForVerification);
	Else
		
		Measurement = PerformanceMonitor.StartTimeConsumingOperationMeasurement("InformationRegister.MultiplesOfLotsAndSemiFinishedProducts.CheckCost");
		CheckCost(CalculationsForVerification);
		
		If CalculationsForVerification = Undefined Then
			PerformanceMonitor.EndTimeConsumingOperationMeasurement(Measurement, 1);
		Else
			PerformanceMonitor.EndTimeConsumingOperationMeasurement(Measurement, CalculationsForVerification.Count());
		EndIf;
		
	EndIf;
	
	If ThereWasCancellationOfEvent(CalculationParameters.StandardCostEstimate) Then
		CancelDocument(CalculationParameters.StandardCostEstimate, CalculationParameters);
		Return;
	EndIf;
		
EndProcedure

// Record the State of the calculation.
// 
// Parameters:
//  StandardCostEstimate - Arbitrary, Undefined, DocumentRef.StandardCosting2_2 - StandardCostEstimate
//  State - EnumRef.StatesOfStandardCostEstimateCalculation - State
Procedure RecordStateOfCalculation(StandardCostEstimate, State) Export
	
	InformationRegisters.StatesOfStandardCostEstimates.SetState(StandardCostEstimate, State);
	
EndProcedure

// The procedure collapses the table of values multipliers
//
// Parameters:
//	Multipliers - ValueTable - The multipliers table that needs to be collapsed
//	CalculationParameters - Structure - Contains keys:
//		* Multipliers_GroupingColumns - String - Columns by which the table of values should be grouped
//		* Multipliers_SummationColumns - String - Columns for which you need to sum up the values within the grouped columns.
Procedure CollapseMultipliersWithinVT(Multipliers, CalculationParameters) Export
	
	If Multipliers.Columns.Find("Priority") = Undefined Then
		GroupingColumns = CalculationParameters.Multipliers_GroupingColumnsWithoutPriority;
	Else
		GroupingColumns = CalculationParameters.Multipliers_GroupingColumns;
	EndIf;
	
	Multipliers.GroupBy(GroupingColumns,
		CalculationParameters.Multipliers_SummationColumns);
		
EndProcedure

// The procedure clears the PC of the multipliers of the parties of the semi-finished products according to the transferred product standard cost
//
// Parameters:
//		StandardCostEstimate - DocumentRef.StandardCosting2_2 - The product standard cost for which it is necessary to remove Registered Records.
Procedure ClearMultipliers(StandardCostEstimate) Export
	
	RecordSet = InformationRegisters.MultiplesOfLotsAndSemiFinishedProducts.CreateRecordSet();
	RecordSet.Filter.StandardCostEstimate.Set(StandardCostEstimate);
	
	SetPrivilegedMode(True);
	RecordSet.Write();	
	SetPrivilegedMode(False);
	
EndProcedure

// The function checks the cancellation of the event, in case of cancellation of the event during the calculation, the calculation must be completed.
//
// Parameters:
//		StandardCostEstimate - DocumentRef.StandardCosting2_2 - The product standard cost for which it is necessary to check the cancellation of the event.
//
// Returns:
//		Boolean - according to the document, the event was canceled.
Function ThereWasCancellationOfEvent(StandardCostEstimate) Export
	
	Query = New Query;
	
	Query.Text = 
		"SELECT TOP 1
		|	Queue.StandardCostEstimate AS StandardCostEstimate
		|FROM
		|	InformationRegister.CalculationQueueOfStandardCostEstimates AS Queue
		|WHERE
		|	Queue.UndoPosting
		|	AND Queue.StandardCostEstimate = &StandardCostEstimate";
	
	Query.SetParameter("StandardCostEstimate", StandardCostEstimate);
	
	SetPrivilegedMode(True);
	Return Not Query.Execute().IsEmpty();
	
EndFunction

// Clears a document flows through the registers.
// Parameters:
//	DocumentObject - DocumentObject.StandardCosting2_2 - calculation for which you need to clear the movement.
//	CalculationParameters - See DefineCalculationParameters
//
Procedure ClearRegisteredRecords(DocumentObject, CalculationParameters) Export
	
	DocumentRef = DocumentObject.Ref;
	
	Query = New Query;
	Query.Text = 
		"SELECT
		|	SUM(NestedQuery.Count) AS Count
		|FROM
		|	(SELECT
		|		COUNT(*) AS Count
		|	FROM
		|		AccumulationRegister.PlannedMaterialCosts AS PlannedMaterialCosts
		|	WHERE
		|		PlannedMaterialCosts.Recorder = &Recorder
		|	
		|	UNION ALL
		|	
		|	SELECT
		|		COUNT(*)
		|	FROM
		|		AccumulationRegister.PlannedLaborCosts AS PlannedLaborCosts
		|	WHERE
		|		PlannedLaborCosts.Recorder = &Recorder
		|	
		|	UNION ALL
		|	
		|	SELECT
		|		COUNT(*)
		|	FROM
		|		AccumulationRegister.PlannedOtherCosts AS PlannedOtherCosts
		|	WHERE
		|		PlannedOtherCosts.Recorder = &Recorder) AS NestedQuery";
	
	Query.SetParameter("Recorder", DocumentRef);
	
	SetPrivilegedMode(True);
	Result = Query.Execute();	
	Selection = Result.Select();
	
	If Selection.Next() Then
		CalculationParameters.DataVolume = CalculationParameters.DataVolume + Selection.Count;
	EndIf;
	
	For Each RecordSet In DocumentObject.RegisterRecords Do
		
		RecordSet1 = RecordSet; // AccumulationRegisterRecordSet
		RecordSet1.Write();
		
	EndDo;
	SetPrivilegedMode(False);
	
	ClearMultipliers(DocumentRef);
	
EndProcedure

// The function returns a table of specifications for the passed item
//
// Parameters:
//	MethodsOfObtainingMaterials - ValueTable - a table with the nomenclature and characteristics for which it is necessary 
//	to obtain specifications.
//
// Returns:
//	ValueTable - containing specifications for the required nomenclature.
Function GetProductSpecifications(MethodsOfObtainingMaterials) Export
	
	BOMSelectionParameters = ProductDataManagementClientServer.ParametersForSelectingSpecificationsForManufacturingAssembly();
	
	QueryOptions = ProductDataManagement.ParametersOfRequestTextForManufacturedProductSpecifications();
	QueryOptions.PriorityOnly = True;
	
	QueryText =
		"SELECT
		|	T.TheIndexOfTheData                                            AS TheIndexOfTheData,
		|	T.Department                                           AS ProductionDispatcherBusinessUnit,
		|	T.Products                                            AS Products,
		|	T.Characteristic                                          AS Characteristic,
		|	T.ProductionStart                                      AS ProductionStart
		|INTO UsedMaterials
		|FROM
		|	&UsedMaterials AS T
		|;
		|
		|SELECT
		|	T.*,
		|	T.Products.ProductKind                            AS ProductKind,
		|	VALUE(Catalog.LinesOfBusiness.EmptyRef) AS LineOfBusiness
		|INTO TTListOfProducts
		|FROM
		|	UsedMaterials AS T
		|;
		|";
	
	QueryText = QueryText + ProductDataManagement.RequestTextForProductItemsSpecifications(
																	QueryOptions,
																	BOMSelectionParameters);
	
	Query = New Query;
	Query.Text = QueryText;
	Query.SetParameter("UsedMaterials", MethodsOfObtainingMaterials);
	
	ProductDataManagement.SetParametersForRequestManufacturedProductSpecifications(Query, BOMSelectionParameters);
	
	Result = Query.Execute().Unload();
	
	Result.Indexes.Add("TheIndexOfTheData");
	
	Return Result;
	
EndFunction

#EndRegion

#Region Private

#Region CalculationOfNeeds

Procedure CalculateNeeds(CalculationParameters)
	
	StandardCostEstimate = CalculationParameters.StandardCostEstimate;
	If ThereWasCancellationOfEvent(StandardCostEstimate) Then
		Return;
	EndIf;
	
	ThereAreErrorsInCalculation = False;
	BeginTransaction();
	
	Try
		
		BlockData_(StandardCostEstimate);
		
		TempTablesManager = New TempTablesManager;
		
		ThereAreEntriesInQueue = CalculationQueue(StandardCostEstimate, TempTablesManager);
				
		If ThereAreEntriesInQueue Then
						
			ProcessCalculationQueue(TempTablesManager, CalculationParameters);
		
			ClearCalculationQueue(StandardCostEstimate, TempTablesManager);
			
		EndIf;
		
		If ValueIsFilled(CalculationParameters.ExplosionError) Then
			
			ThereAreErrorsInCalculation = True;
			RecordStateOfCalculation(StandardCostEstimate,
				Enums.StatesOfStandardCostEstimateCalculation.CalculationError);
			LogCalculationError(StandardCostEstimate, CalculationParameters.ExplosionError);
			
		EndIf;	
		
		CommitTransaction();
		
	Except
		
		RollbackTransaction();
		
		ErrorInfo = ErrorInfo();
		ThereAreErrorsInCalculation = True;
		RecordStateOfCalculation(StandardCostEstimate, 
			Enums.StatesOfStandardCostEstimateCalculation.CalculationError);
		InformationRegisters.CalculationQueueOfStandardCostEstimates.ClearQueue(StandardCostEstimate);
		LogCalculationError(StandardCostEstimate, ErrorProcessing.DetailErrorDescription(ErrorInfo));
		
	EndTry;
	
	If ThereWasCancellationOfEvent(CalculationParameters.StandardCostEstimate) Then
		Return;
	EndIf;
	
	If Not ThereAreErrorsInCalculation And ThereAreTasksInQueue(StandardCostEstimate) Then
		CalculateNeeds(CalculationParameters);
	EndIf;
	
EndProcedure

Procedure ProcessCalculationQueue(TempTablesManager, CalculationParameters)
	
	RegisterRecords = InitializeMovementTables();
	
	UnravelProducts_(CalculationParameters.StandardCostEstimate, TempTablesManager, RegisterRecords, CalculationParameters);
	
	RecordRegisteredRecords(RegisterRecords, TempTablesManager, CalculationParameters);
		
EndProcedure

// Creates record sets for generating movements.
// Returns:
//	Structure - contains sets of register entries for the formation of movements:
//		* PlannedMaterialCosts - ValueTable - a set of register columns planned material costs.
//		* PlannedLaborCosts - ValueTable - a set of columns of the register of planned labor costs.
//		* PlannedOtherCosts - ValueTable - a set of columns of the register of planned expenses.
//		* MultiplesOfLotsAndSemiFinishedProducts - ValueTable - a set of columns of the register of multiplicationpartiyipolufabrikat.
//
Function InitializeMovementTables() Export
	
	Registers = New Array;
	Registers.Add("PlannedMaterialCosts");
	Registers.Add("PlannedLaborCosts");
	Registers.Add("PlannedOtherCosts");
	Registers.Add("MultiplesOfLotsAndSemiFinishedProducts");
	
	Result = New Structure;
	
	For Each Register In Registers Do
		
		If Register = "MultiplesOfLotsAndSemiFinishedProducts" Then
			Set = InformationRegisters[Register].CreateRecordSet();
		Else	
			Set = AccumulationRegisters[Register].CreateRecordSet();
		EndIf;
		
		Table = Set.UnloadColumns();
		Result.Insert(Register, Table);
		
	EndDo;
	
	Return Result;
	
EndFunction

#EndRegion

#Region Posting

Procedure PostDocument(CalculationParameters)
	
	StandardCostEstimate = CalculationParameters.StandardCostEstimate;
	If ThereWasCancellationOfEvent(StandardCostEstimate) Then
		Return;
	EndIf;
	
	BeginTransaction();
	
	Try
		
		BlockData_(StandardCostEstimate);
		
		Queue = HoldingQueue(StandardCostEstimate);
		
		If Queue.ThereAreEntriesInQueue Then
			
			DocumentObject = StandardCostEstimate.GetObject();
			
			ClearRegisteredRecords(DocumentObject, CalculationParameters);
			
			FormRegisteredRecords(DocumentObject);
			
			InformationRegisters.CalculationQueueOfStandardCostEstimates.ClearQueue(StandardCostEstimate, Queue.Records);
			
		EndIf;
		
		CommitTransaction();
		
	Except
		
		RollbackTransaction();
		
		ErrorInfo = ErrorInfo();
		RecordStateOfCalculation(StandardCostEstimate, 
			Enums.StatesOfStandardCostEstimateCalculation.CalculationError);
		InformationRegisters.CalculationQueueOfStandardCostEstimates.ClearQueue(StandardCostEstimate);
		LogCalculationError(StandardCostEstimate, ErrorProcessing.DetailErrorDescription(ErrorInfo));
		
	EndTry;
	
EndProcedure

Function HoldingQueue(StandardCostEstimate)
	
	Query = New Query;
	Query.Text =
		"SELECT DISTINCT
		|	CalculationQueueOfStandardCostEstimates.StandardCostEstimate AS StandardCostEstimate,
		|	CalculationQueueOfStandardCostEstimates.Separator AS Separator
		|FROM
		|	InformationRegister.CalculationQueueOfStandardCostEstimates AS CalculationQueueOfStandardCostEstimates
		|WHERE
		|	CalculationQueueOfStandardCostEstimates.StandardCostEstimate = &StandardCostEstimate";
	
	Query.SetParameter("StandardCostEstimate", StandardCostEstimate);
	
	SetPrivilegedMode(True);
	QueryResult = Query.Execute();
	SetPrivilegedMode(False);
	
	Result = New Structure("ThereAreEntriesInQueue, Records");
	
	If Not QueryResult.IsEmpty() Then
		
		Result.ThereAreEntriesInQueue = True;
		Result.Records = QueryResult.Unload();
		
	Else
		Result.ThereAreEntriesInQueue = False;
	EndIf;
	
	Return Result;
	
EndFunction

Procedure CancelDocument(StandardCostEstimate, CalculationParameters)
	
	DocumentObject = StandardCostEstimate.GetObject();
	ClearRegisteredRecords(DocumentObject, CalculationParameters);
	InformationRegisters.CalculationQueueOfStandardCostEstimates.ClearQueue(StandardCostEstimate);
	RecordStateOfCalculation(StandardCostEstimate, 
		Enums.StatesOfStandardCostEstimateCalculation.NotCalculated);
	
EndProcedure

#EndRegion

#Region Nodulation

// Managing product de-linking.
// Parameters:
//	StandardCostEstimate - DocumentRef.StandardCosting2_2 - link to the document to be unzipped.
//	TempTablesManager - TempTablesManager - Manager with service tables.
//	RegisterRecords - See InformationRegisters.MultiplesOfLotsAndSemiFinishedProducts.InitializeMovementTables
//	CalculationParameters - See DefineCalculationParameters
//
Procedure UnravelProducts_(StandardCostEstimate, TempTablesManager, RegisterRecords, CalculationParameters)
	
	Query = New Query(RequestTextProductDiscoveryQueue());
	Query.TempTablesManager = TempTablesManager;
	SetPrivilegedMode(True);
	Multipliers = Query.Execute().Unload();
	SetPrivilegedMode(False);
	
	StructureOfData = New Structure();
	StructureOfData.Insert("Multipliers", Multipliers);
	StructureOfData.Insert("TempTablesManager", TempTablesManager);
	StructureOfData.Insert("RegisterRecords", RegisterRecords);
	CalculationParameters.Insert("StructureOfData", StructureOfData);	
	
	UnravelingDinStructure = ItIsRequiredToFindOutOrderOfDinStructure(StructureOfData.TempTablesManager,
		CalculationParameters);
	UnravelingStatStructure = ItIsRequiredToUnravelOrder(StructureOfData.TempTablesManager);
	If UnravelingDinStructure Or UnravelingStatStructure Then
		ProductStandardCostOfOrderStructure.ProcessProductsByOrder(CalculationParameters);
	EndIf;
		
	If StructureOfData.Multipliers.Count() = 0 Then
		Return;
	EndIf;
	
	If ThereWasCancellationOfEvent(CalculationParameters.StandardCostEstimate) Then
		Return;
	EndIf;
		
	#Region UnravelingThroughBillOfMaterials
	StructureOfData.Multipliers.Indexes.Add("LotProductBOM, ManufacturedProduct, ItemVariant, SemiFinishedProduct, CalculationIsCompleted");
	StructureOfData.Multipliers.Indexes.Add("LotSemiFinishedProductBOM, SemiFinishedProduct, ItemVariantsOfIntermediateProduct, CalculationIsCompleted");

	CheckingCycle = 0;
	ThereWasDeIdentificationAccordingToSpecifications = False;
	While True Do
		// During the uncoupling of PF according to specifications, additional PF requiring uncoupling may be added.
		RequirementsForUncoupling = RequirementsForObtainingTheseSpecifications(StructureOfData.Multipliers, CalculationParameters);
		If RequirementsForUncoupling.Count() = 0 Then
			StructureOfData.Multipliers.Indexes.Clear();
			Break;
		EndIf;
		ThereWasDeIdentificationAccordingToSpecifications = True;
		UnravelSpecificationOfProducts(CalculationParameters, RequirementsForUncoupling);
		StructureOfData.Multipliers.Columns.Delete("TheIndexOfTheData");
		
		CheckingCycle = CheckingCycle + 1;
		If CheckingCycle > 10000 Then
			Break; // It's looped.
		EndIf;
	EndDo;
	
	If ThereWasDeIdentificationAccordingToSpecifications Then
		RecalculateDenominatorsAccordingToResourceSpecifications(CalculationParameters, StructureOfData);
		ReducePlannedMaterialCosts(CalculationParameters, CalculationParameters.StructureOfData.RegisterRecords.PlannedMaterialCosts);
		CurtailPlannedLaborCosts(CalculationParameters, CalculationParameters.StructureOfData.RegisterRecords.PlannedLaborCosts);
	EndIf;
	
	BringMultipliersToCommonDenominator(StructureOfData.Multipliers);
	
	RegisterRecords.MultiplesOfLotsAndSemiFinishedProducts = StructureOfData.Multipliers;
	
	#EndRegion
	
EndProcedure

Function RequestTextProductDiscoveryQueue()
	
	Return
		"SELECT
		|	CalculationQueue.StandardCostEstimate AS StandardCostEstimate,
		|	CalculationQueue.LotProductBOM AS LotProductBOM,
		|	CalculationQueue.ManufacturedProduct AS ManufacturedProduct,
		|	CalculationQueue.ItemVariant AS ItemVariant,
		|	CalculationQueue.Purpose AS Purpose,
		|	CalculationQueue.LotSemiFinishedProductBOM AS LotSemiFinishedProductBOM,
		|	CalculationQueue.KeyLot AS KeyLot,
		|	CalculationQueue.SemiFinishedProduct AS SemiFinishedProduct,
		|	CalculationQueue.ItemVariantsOfIntermediateProduct AS ItemVariantsOfIntermediateProduct,
		|	CalculationQueue.Separator AS Separator,
		|	CalculationQueue.DemandDate AS Period,
		|	CalculationQueue.Order AS Order,
		|	ISNULL(MultiplesOfLotsAndSemiFinishedProducts.LotIsReleased, FALSE) AS LotIsReleased,
		|	ISNULL(MultiplesOfLotsAndSemiFinishedProducts.CalculationIsCompleted, FALSE) AS CalculationIsCompleted, 
		|	ISNULL(MultiplesOfLotsAndSemiFinishedProducts.StandardCostEstimate.ProductionDispatcherBusinessUnit, VALUE(Catalog.BusinessStructure.EmptyRef)) AS Department, 
		// If the denominator matches, then it is necessary to sum up the resource columns and the numerator
		// when using DIFFERENT ONES and the numerator and denominator match, only 1 numerator will remain. 
		|	ISNULL(MultiplesOfLotsAndSemiFinishedProducts.Denominator, 0) AS Denominator,	
		|	CASE
		|		WHEN MultiplesOfLotsAndSemiFinishedProducts.SemiFinishedProduct = VALUE(Catalog.Products.EmptyRef)
		|			THEN 0
		|		ELSE 1
		|	END AS Priority,
		|   SUM(ISNULL(MultiplesOfLotsAndSemiFinishedProducts.Numerator, 0)) AS Numerator,
		|	SUM(ISNULL(MultiplesOfLotsAndSemiFinishedProducts.QuantityOfSemiFinishedProduct, 0)) AS QuantityOfSemiFinishedProduct,
		|	SUM(ISNULL(MultiplesOfLotsAndSemiFinishedProducts.Cost, 0)) AS Cost,
		|	SUM(ISNULL(MultiplesOfLotsAndSemiFinishedProducts.CostExcludingVAT, 0)) AS CostExcludingVAT,
		|	SUM(ISNULL(MultiplesOfLotsAndSemiFinishedProducts.LocalCost, 0)) AS LocalCost,
		|	SUM(ISNULL(MultiplesOfLotsAndSemiFinishedProducts.LaborCosts, 0)) AS LaborCosts,
		|	SUM(ISNULL(MultiplesOfLotsAndSemiFinishedProducts.LaborCostsLocal, 0)) AS LaborCostsLocal,
		|	SUM(ISNULL(MultiplesOfLotsAndSemiFinishedProducts.ItemizedFixed, 0)) AS ItemizedFixed,
		|	SUM(ISNULL(MultiplesOfLotsAndSemiFinishedProducts.ItemizedFixedCostsExcludingVAT, 0)) AS ItemizedFixedCostsExcludingVAT,
		|	SUM(ISNULL(MultiplesOfLotsAndSemiFinishedProducts.ItemizedFixedCostsCompl, 0)) AS ItemizedFixedCostsCompl,
		|	SUM(ISNULL(MultiplesOfLotsAndSemiFinishedProducts.ItemizedVariable, 0)) AS ItemizedVariable,
		|	SUM(ISNULL(MultiplesOfLotsAndSemiFinishedProducts.ItemizedVariableCostsExcludingVAT, 0)) AS ItemizedVariableCostsExcludingVAT,
		|	SUM(ISNULL(MultiplesOfLotsAndSemiFinishedProducts.ItemizedVariableCostsCompl, 0)) AS ItemizedVariableCostsCompl,
		|	SUM(ISNULL(MultiplesOfLotsAndSemiFinishedProducts.OffBalanceCost, 0)) AS OffBalanceCost,
		|	SUM(ISNULL(MultiplesOfLotsAndSemiFinishedProducts.OffBalanceCostLocal, 0)) AS OffBalanceCostLocal
		|FROM
		|	CalculationQueue AS CalculationQueue
		|		INNER JOIN InformationRegister.MultiplesOfLotsAndSemiFinishedProducts AS MultiplesOfLotsAndSemiFinishedProducts
		// Selection of data requiring calculation.
		// The connection conditions must match the conditions in the first request of the procedure to record the multipliers
		|		ON CalculationQueue.StandardCostEstimate = MultiplesOfLotsAndSemiFinishedProducts.StandardCostEstimate
		|			AND CalculationQueue.LotProductBOM = MultiplesOfLotsAndSemiFinishedProducts.LotProductBOM
		|			AND CalculationQueue.ManufacturedProduct = MultiplesOfLotsAndSemiFinishedProducts.ManufacturedProduct
		|			AND CalculationQueue.ItemVariant = MultiplesOfLotsAndSemiFinishedProducts.ItemVariant
		|			AND CalculationQueue.Purpose = MultiplesOfLotsAndSemiFinishedProducts.Purpose
		|			AND CalculationQueue.LotSemiFinishedProductBOM = MultiplesOfLotsAndSemiFinishedProducts.LotSemiFinishedProductBOM
		|			AND CalculationQueue.KeyLot = MultiplesOfLotsAndSemiFinishedProducts.KeyLot
		|			AND CalculationQueue.SemiFinishedProduct = MultiplesOfLotsAndSemiFinishedProducts.SemiFinishedProduct
		|			AND CalculationQueue.ItemVariantsOfIntermediateProduct = MultiplesOfLotsAndSemiFinishedProducts.ItemVariantsOfIntermediateProduct
		|			AND (CalculationQueue.DemandDate = BEGINOFPERIOD(MultiplesOfLotsAndSemiFinishedProducts.Period, DAY))
		|			AND CalculationQueue.Order = MultiplesOfLotsAndSemiFinishedProducts.Order
		|
		|GROUP BY
		|	CalculationQueue.StandardCostEstimate,
		|	CalculationQueue.LotProductBOM,
		|	CalculationQueue.ManufacturedProduct,
		|	CalculationQueue.ItemVariant,
		|	CalculationQueue.Purpose,
		|	CalculationQueue.LotSemiFinishedProductBOM,
		|	CalculationQueue.KeyLot,
		|	CalculationQueue.SemiFinishedProduct,
		|	CalculationQueue.ItemVariantsOfIntermediateProduct,
		|	CalculationQueue.Separator,
		|	CalculationQueue.DemandDate,
		|	CalculationQueue.Order,
		|	ISNULL(MultiplesOfLotsAndSemiFinishedProducts.LotIsReleased, FALSE),
		|	ISNULL(MultiplesOfLotsAndSemiFinishedProducts.CalculationIsCompleted, FALSE), 
		|	ISNULL(MultiplesOfLotsAndSemiFinishedProducts.StandardCostEstimate.ProductionDispatcherBusinessUnit, VALUE(Catalog.BusinessStructure.EmptyRef)), 
		|	ISNULL(MultiplesOfLotsAndSemiFinishedProducts.Denominator, 0),
		|	CASE
		|		WHEN MultiplesOfLotsAndSemiFinishedProducts.SemiFinishedProduct = VALUE(Catalog.Products.EmptyRef)
		|			THEN 0
		|		ELSE 1
		|	END	
		|
		|ORDER BY
		|	Priority";
	
EndFunction

Procedure UnravelSpecificationOfProducts(CalculationParameters, RequirementsForUncoupling)
	
	StructureOfData = CalculationParameters.StructureOfData;
	ThereIsPriority = StructureOfData.Multipliers.Columns.Find("Priority") <> Undefined;
	
	// Unifying specifications.
	DataSamplingParameters = Catalogs.BillsOfMaterials.DataSamplingParameters();
	DataSamplingParameters.OverridingReleasePartySetting.Use = True;
	DataSamplingParameters.RoundUpNumberOfUnitItems_ = False;
	DataSamplingParameters.CalculateShareOfCostOfOutputProducts = True;
	DataSamplingParameters.CombineMaterialsAndWorksPerformed = True;
	
	// For the separation of PF, which have a method of obtaining in the specification = Provide
	// In the register of information "Options for the provision of goods" there should be an entry for this PF with a way to meet the needs = "Own production"
	// In the function below, see the formation request in the #Materials Services area
	// The uncoupling will work if in this table, for PF, the column Schedule = True
	Demands = Catalogs.BillsOfMaterials.SpecificationDataByProductsList(
		RequirementsForUncoupling,
		DataSamplingParameters);
	
	// Filling in production dates depending on the duration of the stages.
	// Simultaneous execution of stages is not supported.
	CalculationPeriod_ = CalculationParameters.PCDetails.Date;
	FillInProductionDates(Demands, CalculationPeriod_);

	UnearthedObjects = New ValueTable;
	UnearthedObjects.Columns.Add("BillOfMaterials", New TypeDescription("CatalogRef.BillsOfMaterials"));
	UnearthedObjects.Columns.Add("KeyLot", New TypeDescription("String", New StringQualifiers(36)));
	
	NumberOfSemiFinishedProducts = Demands.Count();
	IndexOf = 0;
	
	// Processing of the result of the splitting.
	// Calculation of multipliers of semi-finished products.
	While IndexOf < NumberOfSemiFinishedProducts Do
		
		SpecificationData = Demands[IndexOf];
		IndexOfProduct = RequirementsForUncoupling[IndexOf].IndexOfProduct;
		Multiplier = StructureOfData.Multipliers[IndexOfProduct];
		
		// The main finishedproduct is the structure
		UIDCharacteristics = String(SpecificationData.MainProduct.Characteristic.UUID());
		
		CalculationOfProductionPlan.ForwardMovements(SpecificationData.MaterialsAndServices);
		
		CostShares = SpecificationData.ManufacturedProducts.Total("CostShare");
		
		If CostShares = 0 Then
			CostShares = 1;
		EndIf;
		Numerator = 1;
		Denominator = 1;
		
		For Each FinishedProduct In SpecificationData.ManufacturedProducts Do
			
			#Region ConditionOfOutputProduct
			// There can be many output products in the specification,
			// we only need a detectable output product.
			If Multiplier.SemiFinishedProduct = Catalogs.Products.EmptyRef() Then
				If Multiplier.ManufacturedProduct <> FinishedProduct.Products Then
					Continue;
				EndIf;
				If ValueIsFilled(Multiplier.ItemVariant)
					And ValueIsFilled(FinishedProduct.Characteristic)
					And Multiplier.ItemVariant <> FinishedProduct.Characteristic Then
					Continue;
				EndIf;
				
				Multiplier.Period = SpecificationData.Ending;
			Else
				If Multiplier.LotSemiFinishedProductBOM <> SpecificationData.BillOfMaterials Then
					Continue;
				EndIf;
				If Multiplier.SemiFinishedProduct <> FinishedProduct.Products Then
					Continue;
				EndIf;
				If ValueIsFilled(Multiplier.ItemVariantsOfIntermediateProduct)
					And ValueIsFilled(FinishedProduct.Characteristic)
					And Multiplier.ItemVariantsOfIntermediateProduct <> FinishedProduct.Characteristic Then
					Continue;
				EndIf;
			EndIf;
			#EndRegion
				
			CostShare = ?(FinishedProduct.CostShare = 0, 1, FinishedProduct.CostShare);
				
			// Comment 750.
			// Change the numerator and denominator, for data from the resource specification.
			// The share of the cost and the minimum number of launches must be taken into account.
			Numerator = Multiplier.QuantityOfSemiFinishedProduct * CostShare;
			Denominator = FinishedProduct.Count; // Multiplier.Quantities of the factory;
			
			Multiplier.Numerator = Multiplier.QuantityOfSemiFinishedProduct;
			Multiplier.Denominator = Multiplier.QuantityOfSemiFinishedProduct;
				
			// We can get here after Dean's calculation. structures,
			// so the key party may differ from the UID characteristics, update the value.
			Multiplier.KeyLot = ?(ValueIsFilled(Multiplier.SemiFinishedProduct), String(
				Multiplier.ItemVariantsOfIntermediateProduct.UUID()), String(
				Multiplier.ItemVariant.UUID()));
			Multiplier.CalculationIsCompleted = True;

			For Each MaterialString In SpecificationData.MaterialsAndServices Do

				If Not (MaterialString.ToPlan Or MaterialString.Produced) Then
					Continue;
				EndIf;

				NewMultiplier = StructureOfData.Multipliers.Add();
				FillPropertyValues(NewMultiplier, Multiplier,
					"LotProductBOM, ManufacturedProduct, ItemVariant, Purpose, StandardCostEstimate");

				If MaterialString.MethodOfReceivingMaterial
					= Enums.MethodsOfReceivingBOMMaterials.ProduceByBillsOfMaterials Then
					NewMultiplier.LotSemiFinishedProductBOM = MaterialString.BillOfMaterials;
				Else
					NewMultiplier.LotSemiFinishedProductBOM = Undefined;
				EndIf;
				NewMultiplier.Department = CalculationParameters.PCDetails.ProductionDispatcherBusinessUnit;

				NewMultiplier.Period = SpecificationData.Begin;
				NewMultiplier.SemiFinishedProduct = MaterialString.Products;
				NewMultiplier.ItemVariantsOfIntermediateProduct = MaterialString.Characteristic;
				NewMultiplier.KeyLot = String(MaterialString.Characteristic.UUID());
				NewMultiplier.Order = Multiplier.Order + 1;

				FilterPositions_2 = New Structure("Period, LotProductBOM, ManufacturedProduct, ItemVariant, Purpose, LotSemiFinishedProductBOM, SemiFinishedProduct, ItemVariantsOfIntermediateProduct, Order");
				FillPropertyValues(FilterPositions_2, NewMultiplier);
				FilterPositions_2.Insert("KeyLot", NewMultiplier.KeyLot);
				FilterPositions_2.Insert("CalculationIsCompleted", True);
				CalculatedPositions = StructureOfData.Multipliers.FindRows(FilterPositions_2);
				For Each CalculatedPosition In CalculatedPositions Do

					If NewMultiplier.Order > CalculatedPosition.Order Then
						Continue;
					EndIf;

					NewMultiplier.Order = CalculatedPosition.Order + 1;

				EndDo;

				NewMultiplier.QuantityOfSemiFinishedProduct = Round(MaterialString.Count * Numerator / Denominator, 7);
					
				// Anything other than 1 is useless here, since when the semi-finished product is uncoupled, the values will change,
				// see comment 750.
				NewMultiplier.Numerator = 1;
				NewMultiplier.Denominator = 1;

				NewMultiplier.Cost = 0;
				NewMultiplier.CostExcludingVAT = 0;
				NewMultiplier.LocalCost = 0;
				NewMultiplier.LaborCosts = 0;
				NewMultiplier.LaborCostsLocal = 0;
				NewMultiplier.ItemizedFixed = 0;
				NewMultiplier.ItemizedFixedCostsExcludingVAT = 0;
				NewMultiplier.ItemizedFixedCostsCompl = 0;
				NewMultiplier.ItemizedVariable = 0;
				NewMultiplier.ItemizedVariableCostsExcludingVAT = 0;
				NewMultiplier.ItemizedVariableCostsCompl = 0;
				NewMultiplier.OffBalanceCost = 0;
				NewMultiplier.OffBalanceCostLocal = 0;
				If ThereIsPriority Then
					NewMultiplier.Priority = ?(ValueIsFilled(NewMultiplier.SemiFinishedProduct), 1, 0);
				EndIf;

				NewMultiplier.CalculationIsCompleted = False;
				NewMultiplier.LotIsReleased = False;

			EndDo;
			
		EndDo;
					
		BillOfMaterialsWithCharacteristic = New Structure("BillOfMaterials, KeyLot",
			SpecificationData.BillOfMaterials, UIDCharacteristics);
		
		PeriodCalculationParameters = PeriodCalculationParameters();
		PeriodCalculationParameters.Period = BegOfDay(SpecificationData.Begin);
		PeriodCalculationParameters.Stages = SpecificationData.Stages;
		PeriodCalculationParameters.DurationOfStages = SpecificationData.Stages.UnloadColumn("StageDuration");
		
		StagesOnSide = SpecificationData.Stages.FindRows(New Structure("ProductionByThirdParty", True));
		For Each StageOnSide In StagesOnSide Do
			
			PlannedMaterialCosts = StructureOfData.RegisterRecords.PlannedMaterialCosts; // ValueTable
			
			PeriodCalculationParameters.CurrentStep = StageOnSide.Stage;
			StageCostPeriod = GetCostPeriod(PeriodCalculationParameters);
			
			For Each CurService In StageOnSide.SubcontractorServices Do
				
				NewService = PlannedMaterialCosts.Add();
				NewService.Period 				= CalculationPeriod_;
				NewService.LotBOM 	= SpecificationData.BillOfMaterials;
				NewService.Department 		= StageOnSide.Department;
				NewService.ProductCostElement 	= CurService.ProductCostElement;
				NewService.Products 		= CurService.Products;
				NewService.Characteristic 		= CurService.Characteristic;
				NewService.Count 			= CurService.Count * Numerator / Denominator;
				NewService.CostPeriod 		= StageCostPeriod;
				NewService.KeyLot 			= UIDCharacteristics;
				
			EndDo;
			
		EndDo;
		
		ManufacturedSemiFinishedProducts = SpecificationData.MaterialsAndServices.CopyColumns("Products,Characteristic,ProductCostElement,Stage");
		For Each MaterialString In SpecificationData.MaterialsAndServices Do
			
			PlannedMaterialCosts = StructureOfData.RegisterRecords.PlannedMaterialCosts; // ValueTable
			NewMaterial = PlannedMaterialCosts.Add();
			NewMaterial.KeyLot = UIDCharacteristics;
			NewMaterial.Period = CalculationPeriod_;
			NewMaterial.LotBOM = SpecificationData.BillOfMaterials;
			NewMaterial.Department = MaterialString.StageSubdivision;
			NewMaterial.ProductCostElement = MaterialString.ProductCostElement;
			NewMaterial.Products = MaterialString.Products;
			NewMaterial.Characteristic = MaterialString.Characteristic;
			NewMaterial.Count = MaterialString.NumberOfPackages * Numerator / Denominator
											* MaterialString.PackageData.Numerator / MaterialString.PackageData.Denominator;
			
			PeriodCalculationParameters.CurrentStep = MaterialString.Stage;
			NewMaterial.CostPeriod = GetCostPeriod(PeriodCalculationParameters);
			
			If MaterialString.ToPlan Or MaterialString.Produced Then
				NewMaterial.ThisIsASemiFinishedProduct = True;
				If MaterialString.MethodOfReceivingMaterial = Enums.MethodsOfReceivingBOMMaterials.ProducedOnStage Then
					NewSemiFinishedProduct = ManufacturedSemiFinishedProducts.Add();
					NewSemiFinishedProduct.Products = MaterialString.Products;
					NewSemiFinishedProduct.Characteristic = MaterialString.Characteristic;
					NewSemiFinishedProduct.ProductCostElement = MaterialString.ProductCostElement;
					NewSemiFinishedProduct.Stage = MaterialString.SourceOfSemiFinishedProduct;
				EndIf;
			EndIf;
			
		EndDo;
		ManufacturedSemiFinishedProducts.Indexes.Add("Products,Characteristic,ProductCostElement,Stage");
		
		For Each LaborCostString In SpecificationData.LaborCosts Do
			
			PlannedLaborCosts = StructureOfData.RegisterRecords.PlannedLaborCosts; // ValueTable
			NewLaborCosts = PlannedLaborCosts.Add();
			FillPropertyValues(NewLaborCosts, LaborCostString);
			NewLaborCosts.KeyLot = UIDCharacteristics;
			NewLaborCosts.Period = CalculationPeriod_;
			NewLaborCosts.LotBOM = SpecificationData.BillOfMaterials;
			NewLaborCosts.Department = LaborCostString.StageSubdivision;
			NewLaborCosts.Count = LaborCostString.Count * Numerator / Denominator;
			
			PeriodCalculationParameters.CurrentStep = LaborCostString.Stage;
			NewLaborCosts.CostPeriod = GetCostPeriod(PeriodCalculationParameters);
			
		EndDo;
		
		For Each MaterialString In SpecificationData.RecyclableWaste Do
			
			PlannedMaterialCosts = StructureOfData.RegisterRecords.PlannedMaterialCosts; // ValueTable
			NewRow = PlannedMaterialCosts.Add();
			NewRow.KeyLot = UIDCharacteristics;
			NewRow.Period = CalculationPeriod_;
			NewRow.LotBOM = SpecificationData.BillOfMaterials;
			NewRow.Department = MaterialString.StageSubdivision;
			NewRow.ProductCostElement = MaterialString.ProductCostElement;
			NewRow.Products = MaterialString.Products;
			NewRow.Characteristic = MaterialString.Characteristic;
			NewRow.Count = -MaterialString.NumberOfPackages * Numerator / Denominator
											* MaterialString.PackageData.Numerator / MaterialString.PackageData.Denominator;
			
			PeriodCalculationParameters.CurrentStep = MaterialString.Stage;
			NewRow.CostPeriod = GetCostPeriod(PeriodCalculationParameters);
			
			SearchTerms = New Structure("Products,Characteristic,ProductCostElement,Stage", 
				MaterialString.Products, MaterialString.Characteristic, MaterialString.ProductCostElement, MaterialString.Stage);
			If ManufacturedSemiFinishedProducts.FindRows(SearchTerms).Count() > 0 Then
				NewRow.ThisIsASemiFinishedProduct = True;
			EndIf;
			
		EndDo;		
		
		NewRow = UnearthedObjects.Add();
		NewRow.BillOfMaterials = BillOfMaterialsWithCharacteristic.BillOfMaterials; 
		NewRow.KeyLot = UIDCharacteristics;
		
		IndexOf = IndexOf + 1;
		
	EndDo;
	
EndProcedure

// Defines the needs for the semi-finished products ' unzipping.
// Parameters:
//	Products - Assignment tables - a table of semi-finished products for unraveling.
//	CalculationParameters - See DefineCalculationParameters
Function RequirementsForObtainingTheseSpecifications(Multipliers, CalculationParameters)
	
	Result = Catalogs.BillsOfMaterials.ItemList();
	Result.Columns.Add("IndexOfProduct", New TypeDescription("Number"));
	
	Multipliers.Columns.Add("TheIndexOfTheData", New TypeDescription("Number"));
	TMCommonUse.NumberValueTable(Multipliers, "TheIndexOfTheData");
	
	SemiFinishedProducts = Multipliers.Copy(
		New Structure("LotSemiFinishedProductBOM", Undefined), 
		"TheIndexOfTheData, SemiFinishedProduct, ItemVariantsOfIntermediateProduct, Department");
	SemiFinishedColumn = SemiFinishedProducts.Columns.SemiFinishedProduct; // ValueTableColumn
	SemiFinishedColumn.Name = "Products";
	
	ColumnCharacteristicsOfSemiFinishedProduct = SemiFinishedProducts.Columns.ItemVariantsOfIntermediateProduct; // ValueTableColumn
	ColumnCharacteristicsOfSemiFinishedProduct.Name = "Characteristic";
	
	SemiFinishedProducts.Columns.Add("ProductionStart", New TypeDescription("Date"));
	SemiFinishedProducts.FillValues(CalculationParameters.PCDetails.Date, "ProductionStart");
	
	IndexOf = SemiFinishedProducts.Count() - 1;
	While IndexOf > 0 Do
		
		If Not ValueIsFilled(SemiFinishedProducts[IndexOf].Products) Then
			SemiFinishedProducts.Delete(IndexOf);
		EndIf;
		
		IndexOf = IndexOf - 1;
		
	EndDo;
	
	ProductsBOM = GetProductSpecifications(SemiFinishedProducts);
	FilterOfSpecifications = New Structure("TheIndexOfTheData");
	
	Multipliers.Indexes.Add("ManufacturedProduct, ItemVariant");
	CurrentProductIndex = -1;
	For Each Product In Multipliers Do
		
		CurrentProductIndex = CurrentProductIndex + 1;
		
		If Product.CalculationIsCompleted Then
			Continue;
		EndIf;
		
		NewNeed = Result.Add();
		NewNeed.IndexOfProduct = CurrentProductIndex;
		
		If ValueIsFilled(Product.SemiFinishedProduct) Then
			
			NewNeed.Products = Product.SemiFinishedProduct;
			NewNeed.Characteristic = Product.ItemVariantsOfIntermediateProduct;
			NewNeed.BillOfMaterials = Product.LotSemiFinishedProductBOM;
			
			If Not ValueIsFilled(NewNeed.BillOfMaterials) Then
				
				PfvSourceData = Multipliers.FindRows(New Structure("ManufacturedProduct, ItemVariant", Product.SemiFinishedProduct, Product.ItemVariantsOfIntermediateProduct));
				
				If PfvSourceData.Count() > 0 Then
					NewNeed.BillOfMaterials = PfvSourceData[0].LotProductBOM;
				Else
					
					FilterOfSpecifications.TheIndexOfTheData = Product.TheIndexOfTheData;
					
					BillsOfMaterial = ProductsBOM.FindRows(FilterOfSpecifications);
					
					If BillsOfMaterial.Count() > 0 Then
						NewNeed.BillOfMaterials = BillsOfMaterial[0].BillOfMaterials;
					EndIf;
					
				EndIf;
					
			EndIf;
			
			If Not ValueIsFilled(NewNeed.BillOfMaterials) Then
				
				Product.CalculationIsCompleted = True;
				Result.Delete(NewNeed);
				Continue;
				
			Else
				Product.LotSemiFinishedProductBOM = NewNeed.BillOfMaterials;
			EndIf;
			
		Else
			
			NewNeed.Products = Product.ManufacturedProduct;
			NewNeed.Characteristic = Product.ItemVariant;
			NewNeed.BillOfMaterials = Product.LotProductBOM;
			
		EndIf;
		
		NewNeed.ProductionStart     = Product.Period;
		NewNeed.ProductionDispatcherBusinessUnit = Product.Department;
		
		MainProductData = Catalogs.BillsOfMaterials.MainProductSpecificationData(NewNeed.BillOfMaterials,
			NewNeed.Products,
			NewNeed.Characteristic);
			
		NewNeed.Count = Product.QuantityOfSemiFinishedProduct;

	EndDo;
	
	Return Result;
	
EndFunction

Procedure FillInProductionDates(Demands, CalculationPeriod_)
	
	IndexOf = Demands.Count() - 1;
	
	TotalDuration = 0;
	While IndexOf >= 0 Do
		
		SpecificationData = Demands[IndexOf]; // Structure
		SpecificationData.Insert("DateOfProduction", CalculationPeriod_);
		SpecificationData.Insert("Begin");
		SpecificationData.Insert("Ending");
		SpecificationData.Insert("ProductionScheduling", Enums.WayOfLinkingProductionOperations.EmptyRef());
		
		CurDuration = 0;
		For Each Stage In SpecificationData.Stages Do
			CurDuration = CurDuration + Stage.StageDurationInDays;
		EndDo;
		
		If SpecificationData.ProductionScheduling = Enums.WayOfLinkingProductionOperations.Backward Then
			
			SpecificationData.Begin = SpecificationData.DateOfProduction + TotalDuration;
			SpecificationData.Ending = SpecificationData.Begin + CurDuration * 86400;
			
		Else
			
			SpecificationData.Ending = CalculationPeriod_;
			SpecificationData.Begin = CalculationPeriod_;
			
		EndIf;
		
		TotalDuration = TotalDuration + CurDuration * 86400;
		
		IndexOf = IndexOf - 1;
		
	EndDo;
	
EndProcedure

#EndRegion

#Region RecalculationOfDenominators

// We bring the multipliers to a common denominator.
//
// Parameters:
//	CalculationParameters - Structure - a set of parameters for background conducting.
//	StructureOfData - Structure - Calculated data.
//
Procedure RecalculateDenominatorsAccordingToResourceSpecifications(CalculationParameters, StructureOfData)
	
	Query = New Query();
	Query.TempTablesManager = New TempTablesManager();
	CostCalculationAppliedAlgorithms.PutTableOfValuesInTemporaryTable(Query.TempTablesManager,
		"Multipliers", StructureOfData.Multipliers,
		CalculationParameters.Multipliers_GroupingColumnsWithoutPriority + ", "
			+ CalculationParameters.Multipliers_SummationColumns,
		"LotSemiFinishedProductBOM,KeyLot"
	);
	
	// When recalculating the denominator by PF, it should be borne in mind that within the framework of 1 resource specification,
	// 1 PF can be used for different products calculated within the framework of 1 planned calculation.
	Query.Text = "
	|SELECT
	|	VZ.LotSemiFinishedProductBOM AS LotSemiFinishedProductBOM,
	|	VZ.SemiFinishedProduct AS SemiFinishedProduct, 
		// We recalculate the value of the denominator, for identical analysts, as the sum of the denominators,
		// since the expenses are calculated relative to the denominator.
	|	SUM(VZ.Denominator) AS Denominator,
	|	MAX(VZ.Order) AS Order,
	|	VZ.KeyLot AS KeyLot
	|INTO CommonDenominators
	|FROM
	|	(SELECT
	|		DD.LotSemiFinishedProductBOM AS LotSemiFinishedProductBOM,
	|		DD.SemiFinishedProduct AS SemiFinishedProduct,
	|		DD.Denominator AS Denominator,
	|		DD.Order AS Order,
	|		DD.KeyLot AS KeyLot
	|	FROM
	|		Multipliers AS DD
	|	WHERE
			// It does not make sense to calculate common denominators for products, since within the framework of one planned calculation,
			// based on resource specifications, there cannot be a duplicate of products,
			// except when the PF within the framework of one planned calculation is a product and the PF is part of a product,
			// the exception is processed in the request below, see comment 1149.
			// Based on the condition above, we take only lines with semi-finished products.
	|		VALUETYPE(DD.LotSemiFinishedProductBOM) = TYPE(Catalog.BillsOfMaterials)
	|		AND DD.SemiFinishedProduct <> VALUE(Catalog.Products.EmptyRef)
	|	
	|	UNION ALL
	|	
		// Comment 1149.
		// In one planned calculation, PF can be both a product and PF as part of a product.
		// Therefore, for the correct calculation of the common denominator in such cases, we add the output to the summation of the common denominator.
	|	SELECT
	|		DD.LotProductBOM,
	|		DD.ManufacturedProduct,
	|		DD.Denominator,
	|		DD.Order,
	|		DD.KeyLot
	|	FROM
	|		Multipliers AS DD
	|	WHERE
	|		DD.LotSemiFinishedProductBOM = UNDEFINED
	|		AND DD.SemiFinishedProduct = VALUE(Catalog.Products.EmptyRef)
	|		AND VALUETYPE(DD.LotProductBOM) = TYPE(Catalog.BillsOfMaterials)) AS VZ
	|
	|GROUP BY
	|	VZ.LotSemiFinishedProductBOM,
	|	VZ.SemiFinishedProduct,
	|	VZ.KeyLot
	|
	|INDEX BY
	|	SemiFinishedProduct,
	|	LotSemiFinishedProductBOM,
	|	KeyLot
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	Multipliers.Period AS Period,
	|	Multipliers.StandardCostEstimate AS StandardCostEstimate,
	|	Multipliers.LotProductBOM AS LotProductBOM,
	|	Multipliers.ManufacturedProduct AS ManufacturedProduct,
	|	Multipliers.ItemVariant AS ItemVariant,
	|	Multipliers.Purpose AS Purpose,
	|	Multipliers.LotSemiFinishedProductBOM AS LotSemiFinishedProductBOM,
	|	Multipliers.KeyLot AS KeyLot,
	|	Multipliers.SemiFinishedProduct AS SemiFinishedProduct,
	|	Multipliers.ItemVariantsOfIntermediateProduct AS ItemVariantsOfIntermediateProduct,
	|	ISNULL(CommonDenominators.Order, Multipliers.Order) AS Order,
	|	ISNULL(CommonDenominators.Denominator, Multipliers.Denominator) AS Denominator,
	|	Multipliers.CalculationIsCompleted AS CalculationIsCompleted,
	|	Multipliers.LotIsReleased AS LotIsReleased,
	|	Multipliers.Numerator AS Numerator,
	|	Multipliers.QuantityOfSemiFinishedProduct AS QuantityOfSemiFinishedProduct,
	|	Multipliers.Cost AS Cost,
	|	Multipliers.CostExcludingVAT AS CostExcludingVAT,
	|	Multipliers.LocalCost AS LocalCost,
	|	Multipliers.LaborCosts AS LaborCosts,
	|	Multipliers.LaborCostsLocal AS LaborCostsLocal,
	|	Multipliers.ItemizedFixed AS ItemizedFixed,
	|	Multipliers.ItemizedFixedCostsExcludingVAT AS ItemizedFixedCostsExcludingVAT,
	|	Multipliers.ItemizedFixedCostsCompl AS ItemizedFixedCostsCompl,
	|	Multipliers.ItemizedVariable AS ItemizedVariable,
	|	Multipliers.ItemizedVariableCostsExcludingVAT AS ItemizedVariableCostsExcludingVAT,
	|	Multipliers.ItemizedVariableCostsCompl AS ItemizedVariableCostsCompl,
	|	Multipliers.OffBalanceCost AS OffBalanceCost,
	|	Multipliers.OffBalanceCostLocal AS OffBalanceCostLocal
	|FROM
	|	Multipliers AS Multipliers
	|		LEFT JOIN CommonDenominators AS CommonDenominators
	|		ON Multipliers.KeyLot = CommonDenominators.KeyLot
	|			AND (Multipliers.LotSemiFinishedProductBOM = CommonDenominators.LotSemiFinishedProductBOM
	|					AND Multipliers.SemiFinishedProduct = CommonDenominators.SemiFinishedProduct
					// See comment 1149.
	|				OR Multipliers.LotSemiFinishedProductBOM = UNDEFINED
	|					AND Multipliers.SemiFinishedProduct = VALUE(Catalog.Products.EmptyRef)
	|					AND Multipliers.LotProductBOM = CommonDenominators.LotSemiFinishedProductBOM
	|					AND Multipliers.ManufacturedProduct = CommonDenominators.SemiFinishedProduct)
	|";
	
	StructureOfData.Multipliers = Query.Execute().Unload();

EndProcedure

Procedure RecalculateDenominators(CalculationParameters, StructureOfData)
	
	Query = New Query();
	Query.TempTablesManager = New TempTablesManager();
	CostCalculationAppliedAlgorithms.PutTableOfValuesInTemporaryTable(Query.TempTablesManager,
		"Multipliers", StructureOfData.MultiplesOfLotsAndSemiFinishedProducts,
		CalculationParameters.Multipliers_GroupingColumnsWithoutPriority + ", "
			+ CalculationParameters.Multipliers_SummationColumns,
		"LotSemiFinishedProductBOM,KeyLot"
	);
	
	Query.Text = "
	|SELECT
	|	CASE WHEN DD.LotSemiFinishedProductBOM = UNDEFINED
	//		Comment 5205
	//		If we recalculate the denominator according to the main GP of the order, then we connect according to the Lot reference bill of Materials of the main GP
	|		THEN DD.LotProductBOM
	//		If we recalculate the denominator by PF, it must be borne in mind that within the framework of 1 order for production,
	//		1 PF can be used for different GP.
	//		1 PF can be produced in one stage for the entire order, based on this, the denominator must be recalculated as part of the consumption of the entire order.
	|		ELSE UNDEFINED
	|	END AS LotProductBOM,
	|	DD.LotSemiFinishedProductBOM AS LotSemiFinishedProductBOM,
	// Recalculate the value of the denominator as the sum of the numerators
	|	SUM(DD.Numerator) AS Denominator,
	|	MAX(DD.Order) AS Order,
	|	DD.KeyLot
	|INTO CommonDenominators
	|FROM
	|	Multipliers AS DD
	|WHERE
	|	CASE
	|		WHEN DD.LotSemiFinishedProductBOM = UNDEFINED
	|			THEN VALUETYPE(DD.LotProductBOM) <> TYPE(Catalog.BillsOfMaterials)
	|		ELSE
	|			VALUETYPE(DD.LotSemiFinishedProductBOM) <> TYPE(Catalog.BillsOfMaterials)
	|		END
	|
	|GROUP BY
	|	CASE WHEN DD.LotSemiFinishedProductBOM = UNDEFINED
	|		THEN DD.LotProductBOM
	|		ELSE UNDEFINED
	|	END,
	|	DD.LotSemiFinishedProductBOM,
	|	DD.KeyLot
	|
	|INDEX BY
	|	LotProductBOM,
	|	LotSemiFinishedProductBOM,
	|	KeyLot
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	Multipliers.Period AS Period,
	|	Multipliers.StandardCostEstimate AS StandardCostEstimate,
	|	Multipliers.LotProductBOM AS LotProductBOM,
	|	Multipliers.ManufacturedProduct AS ManufacturedProduct,
	|	Multipliers.ItemVariant AS ItemVariant,
	|	Multipliers.Purpose AS Purpose,
	|	Multipliers.LotSemiFinishedProductBOM AS LotSemiFinishedProductBOM,
	|	Multipliers.KeyLot AS KeyLot,
	|	Multipliers.SemiFinishedProduct AS SemiFinishedProduct,
	|	Multipliers.ItemVariantsOfIntermediateProduct AS ItemVariantsOfIntermediateProduct,
	|	ISNULL(CommonDenominators.Order, Multipliers.Order) AS Order,
	|	ISNULL(CommonDenominators.Denominator, Multipliers.Denominator) AS Denominator,
	|	Multipliers.CalculationIsCompleted AS CalculationIsCompleted,
	// This is the final request for the identification of GP and PF
	// Further, this flag affects only the old functionality - whether the first level will be uncoupled in PC reports.
	// The Lot reference in this case has been released, but in this case the uncoupling takes place according to the cost tree and the uncoupling is no longer needed in the report.
	// It is supported in report requests only for backward compatibility with older calculated PCs.
	|	FALSE AS LotIsReleased,
	|	Multipliers.Numerator AS Numerator,
	|	Multipliers.QuantityOfSemiFinishedProduct AS QuantityOfSemiFinishedProduct,
	|	Multipliers.Cost AS Cost,
	|	Multipliers.CostExcludingVAT AS CostExcludingVAT,
	|	Multipliers.LocalCost AS LocalCost,
	|	Multipliers.LaborCosts AS LaborCosts,
	|	Multipliers.LaborCostsLocal AS LaborCostsLocal,
	|	Multipliers.ItemizedFixed AS ItemizedFixed,
	|	Multipliers.ItemizedFixedCostsExcludingVAT AS ItemizedFixedCostsExcludingVAT,
	|	Multipliers.ItemizedFixedCostsCompl AS ItemizedFixedCostsCompl,
	|	Multipliers.ItemizedVariable AS ItemizedVariable,
	|	Multipliers.ItemizedVariableCostsExcludingVAT AS ItemizedVariableCostsExcludingVAT,
	|	Multipliers.ItemizedVariableCostsCompl AS ItemizedVariableCostsCompl,
	|	Multipliers.OffBalanceCost AS OffBalanceCost,
	|	Multipliers.OffBalanceCostLocal AS OffBalanceCostLocal
	|FROM
	|	Multipliers AS Multipliers
	|		LEFT JOIN CommonDenominators AS CommonDenominators
	|		ON Multipliers.LotSemiFinishedProductBOM = CommonDenominators.LotSemiFinishedProductBOM
	|			AND Multipliers.KeyLot = CommonDenominators.KeyLot
	// see comment 5205
	|			AND (CommonDenominators.LotProductBOM = UNDEFINED
	|				OR Multipliers.LotProductBOM = CommonDenominators.LotProductBOM)";
	
	StructureOfData.MultiplesOfLotsAndSemiFinishedProducts = Query.Execute().Unload();

EndProcedure

#EndRegion

#Region WorkingWithRegisteredRecords

Procedure FormRegisteredRecords(DocumentObject)
	
	AddlParameters = DocumentsPosting.AdditionalParametersDocumentDataForPosting();
	AddlParameters.AdditionalProperties = DocumentObject.AdditionalProperties;
	
	TablesForRegisteredRecords = DocumentsPosting.DocumentDataForPosting(DocumentObject.Ref, ,
		AddlParameters);
	
	WriteDocumentMultipliers(DocumentObject.Ref, TablesForRegisteredRecords);
	
EndProcedure

Procedure WriteDownMultipliers(AdditionalProperties, CalculationParameters, TempTablesManager)
	
	Multipliers = Undefined;
	
	If Not AdditionalProperties.Property("MultiplesOfLotsAndSemiFinishedProducts", Multipliers)
		And Not AdditionalProperties.TablesForRegisteredRecords.Property("Table" + "MultiplesOfLotsAndSemiFinishedProducts", Multipliers) Then
		Return;
	EndIf;
	
	Query = New Query;
	Query.TempTablesManager = TempTablesManager;
	Query.Text = 
		"SELECT
		|	MultiplesOfLotsAndSemiFinishedProducts.Period AS Period,
		|	MultiplesOfLotsAndSemiFinishedProducts.StandardCostEstimate AS StandardCostEstimate,
		|	MultiplesOfLotsAndSemiFinishedProducts.LotProductBOM AS LotProductBOM,
		|	MultiplesOfLotsAndSemiFinishedProducts.ManufacturedProduct AS ManufacturedProduct,
		|	MultiplesOfLotsAndSemiFinishedProducts.ItemVariant AS ItemVariant,
		|	MultiplesOfLotsAndSemiFinishedProducts.Purpose AS Purpose,
		|	MultiplesOfLotsAndSemiFinishedProducts.LotSemiFinishedProductBOM AS LotSemiFinishedProductBOM,
		|	MultiplesOfLotsAndSemiFinishedProducts.KeyLot AS KeyLot,
		|	MultiplesOfLotsAndSemiFinishedProducts.SemiFinishedProduct AS SemiFinishedProduct,
		|	MultiplesOfLotsAndSemiFinishedProducts.ItemVariantsOfIntermediateProduct AS ItemVariantsOfIntermediateProduct,
		|	MultiplesOfLotsAndSemiFinishedProducts.Order AS Order,
		|	MultiplesOfLotsAndSemiFinishedProducts.Numerator AS Numerator,
		|	MultiplesOfLotsAndSemiFinishedProducts.Denominator AS Denominator,
		|	MultiplesOfLotsAndSemiFinishedProducts.QuantityOfSemiFinishedProduct AS QuantityOfSemiFinishedProduct,
		|	MultiplesOfLotsAndSemiFinishedProducts.Cost AS Cost,
		|	MultiplesOfLotsAndSemiFinishedProducts.CostExcludingVAT AS CostExcludingVAT,
		|	MultiplesOfLotsAndSemiFinishedProducts.LocalCost AS LocalCost,
		|	MultiplesOfLotsAndSemiFinishedProducts.LaborCosts AS LaborCosts,
		|	MultiplesOfLotsAndSemiFinishedProducts.LaborCostsLocal AS LaborCostsLocal,
		|	MultiplesOfLotsAndSemiFinishedProducts.ItemizedFixed AS ItemizedFixed,
		|	MultiplesOfLotsAndSemiFinishedProducts.ItemizedFixedCostsExcludingVAT AS ItemizedFixedCostsExcludingVAT,
		|	MultiplesOfLotsAndSemiFinishedProducts.ItemizedFixedCostsCompl AS ItemizedFixedCostsCompl,
		|	MultiplesOfLotsAndSemiFinishedProducts.ItemizedVariable AS ItemizedVariable,
		|	MultiplesOfLotsAndSemiFinishedProducts.ItemizedVariableCostsExcludingVAT AS ItemizedVariableCostsExcludingVAT,
		|	MultiplesOfLotsAndSemiFinishedProducts.ItemizedVariableCostsCompl AS ItemizedVariableCostsCompl,
		|	MultiplesOfLotsAndSemiFinishedProducts.OffBalanceCost AS OffBalanceCost,
		|	MultiplesOfLotsAndSemiFinishedProducts.OffBalanceCostLocal AS OffBalanceCostLocal,
		|	MultiplesOfLotsAndSemiFinishedProducts.CalculationIsCompleted AS CalculationIsCompleted,
		|	MultiplesOfLotsAndSemiFinishedProducts.LotIsReleased AS LotIsReleased
		|	FROM
		|		InformationRegister.MultiplesOfLotsAndSemiFinishedProducts AS MultiplesOfLotsAndSemiFinishedProducts
		|		LEFT JOIN CalculationQueue AS CalculationQueue
		// Selection of previously calculated data, Multipliers for VT replenishment.
		// The connection conditions must match the request in the function textquestion_question_production_question_question_question_question_question_question_question_question
		|		ON CalculationQueue.StandardCostEstimate = MultiplesOfLotsAndSemiFinishedProducts.StandardCostEstimate
		|			AND CalculationQueue.LotProductBOM = MultiplesOfLotsAndSemiFinishedProducts.LotProductBOM
		|			AND CalculationQueue.ManufacturedProduct = MultiplesOfLotsAndSemiFinishedProducts.ManufacturedProduct
		|			AND CalculationQueue.ItemVariant = MultiplesOfLotsAndSemiFinishedProducts.ItemVariant
		|			AND CalculationQueue.Purpose = MultiplesOfLotsAndSemiFinishedProducts.Purpose
		|			AND CalculationQueue.LotSemiFinishedProductBOM = MultiplesOfLotsAndSemiFinishedProducts.LotSemiFinishedProductBOM
		|			AND CalculationQueue.KeyLot = MultiplesOfLotsAndSemiFinishedProducts.KeyLot
		|			AND CalculationQueue.SemiFinishedProduct = MultiplesOfLotsAndSemiFinishedProducts.SemiFinishedProduct
		|			AND CalculationQueue.ItemVariantsOfIntermediateProduct = MultiplesOfLotsAndSemiFinishedProducts.ItemVariantsOfIntermediateProduct
		|			AND (CalculationQueue.DemandDate = BEGINOFPERIOD(MultiplesOfLotsAndSemiFinishedProducts.Period, DAY))
		|			AND CalculationQueue.Order = MultiplesOfLotsAndSemiFinishedProducts.Order
		|	WHERE
		|		MultiplesOfLotsAndSemiFinishedProducts.StandardCostEstimate = &StandardCostEstimate
		|		AND MultiplesOfLotsAndSemiFinishedProducts.CalculationIsCompleted
		|		AND CalculationQueue.StandardCostEstimate IS NULL";
	
	Query.SetParameter("StandardCostEstimate", CalculationParameters.StandardCostEstimate);
	
	SetPrivilegedMode(True);
	Result = Query.Execute();
	SetPrivilegedMode(False);
	
	Selection = Result.Select();
	
	Multipliers.Indexes.Clear();
	
	While Selection.Next() Do
		FillPropertyValues(Multipliers.Add(), Selection);
	EndDo;
	
	CollapseMultipliers(Multipliers);
	
	BringMultipliersToCommonDenominator(Multipliers);
	
	RecordSet = InformationRegisters.MultiplesOfLotsAndSemiFinishedProducts.CreateRecordSet();
	RecordSet.Filter.StandardCostEstimate.Set(CalculationParameters.StandardCostEstimate);
	
	CollapseMultipliersWithinVT(Multipliers, CalculationParameters);
	RecordSet.Load(Multipliers);
	
	SetPrivilegedMode(True);
	RecordSet.Write();
	SetPrivilegedMode(False);
	
	CalculationParameters.DataVolume = CalculationParameters.DataVolume + Multipliers.Count();
	
EndProcedure

Procedure CollapseMultipliers(Multipliers)
	Query = New Query();
	Query.SetParameter("Multipliers", Multipliers);
	Query.Text = "SELECT
	|	Multipliers.Period AS Period,
	|	Multipliers.StandardCostEstimate AS StandardCostEstimate,
	|	Multipliers.LotProductBOM AS LotProductBOM,
	|	Multipliers.ManufacturedProduct AS ManufacturedProduct,
	|	Multipliers.ItemVariant AS ItemVariant,
	|	Multipliers.Purpose AS Purpose,
	|	Multipliers.LotSemiFinishedProductBOM AS LotSemiFinishedProductBOM,
	|	Multipliers.KeyLot AS KeyLot,
	|	Multipliers.SemiFinishedProduct AS SemiFinishedProduct,
	|	Multipliers.ItemVariantsOfIntermediateProduct AS ItemVariantsOfIntermediateProduct,
	|	Multipliers.Order AS Order,
	|	Multipliers.Denominator AS Denominator,
	|	Multipliers.CalculationIsCompleted AS CalculationIsCompleted,
	|	Multipliers.LotIsReleased AS LotIsReleased,
	|	Multipliers.Numerator AS Numerator,
	|	Multipliers.QuantityOfSemiFinishedProduct AS QuantityOfSemiFinishedProduct,
	|	Multipliers.Cost AS Cost,
	|	Multipliers.CostExcludingVAT AS CostExcludingVAT,
	|	Multipliers.LocalCost AS LocalCost,
	|	Multipliers.LaborCosts AS LaborCosts,
	|	Multipliers.LaborCostsLocal AS LaborCostsLocal,
	|	Multipliers.ItemizedFixed AS ItemizedFixed,
	|	Multipliers.ItemizedFixedCostsExcludingVAT AS ItemizedFixedCostsExcludingVAT,
	|	Multipliers.ItemizedFixedCostsCompl AS ItemizedFixedCostsCompl,
	|	Multipliers.ItemizedVariable AS ItemizedVariable,
	|	Multipliers.ItemizedVariableCostsExcludingVAT AS ItemizedVariableCostsExcludingVAT,
	|	Multipliers.ItemizedVariableCostsCompl AS ItemizedVariableCostsCompl,
	|	Multipliers.OffBalanceCost AS OffBalanceCost,
	|	Multipliers.OffBalanceCostLocal AS OffBalanceCostLocal
	|INTO Multipliers
	|FROM
	|	&Multipliers AS Multipliers
	|
	|INDEX BY
	|	StandardCostEstimate,
	|	LotProductBOM,
	|	ManufacturedProduct,
	|	ItemVariant,
	|	Purpose,
	|	LotSemiFinishedProductBOM,
	|	SemiFinishedProduct,
	|	ItemVariantsOfIntermediateProduct
	|;
	|
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	MAX(Multipliers.Period) AS Period,
	|	Multipliers.StandardCostEstimate AS StandardCostEstimate,
	|	Multipliers.LotProductBOM AS LotProductBOM,
	|	Multipliers.ManufacturedProduct AS ManufacturedProduct,
	|	Multipliers.ItemVariant AS ItemVariant,
	|	Multipliers.Purpose AS Purpose,
	|	Multipliers.LotSemiFinishedProductBOM AS LotSemiFinishedProductBOM,
	|	Multipliers.KeyLot AS KeyLot,
	|	Multipliers.SemiFinishedProduct AS SemiFinishedProduct,
	|	Multipliers.ItemVariantsOfIntermediateProduct AS ItemVariantsOfIntermediateProduct,
	|	MAX(Multipliers.Order) AS Order,
	|	Multipliers.LotIsReleased AS LotIsReleased,  
	|	Multipliers.Denominator AS Denominator,
	|	MAX(Multipliers.CalculationIsCompleted) AS CalculationIsCompleted,
	|	SUM(Multipliers.Numerator) AS Numerator,
	|	SUM(Multipliers.QuantityOfSemiFinishedProduct) AS QuantityOfSemiFinishedProduct,
	|	SUM(Multipliers.Cost) AS Cost,
	|	SUM(Multipliers.CostExcludingVAT) AS CostExcludingVAT,
	|	SUM(Multipliers.LocalCost) AS LocalCost,
	|	SUM(Multipliers.LaborCosts) AS LaborCosts,
	|	SUM(Multipliers.LaborCostsLocal) AS LaborCostsLocal,
	|	SUM(Multipliers.ItemizedFixed) AS ItemizedFixed,
	|	SUM(Multipliers.ItemizedFixedCostsExcludingVAT) AS ItemizedFixedCostsExcludingVAT,
	|	SUM(Multipliers.ItemizedFixedCostsCompl) AS ItemizedFixedCostsCompl,
	|	SUM(Multipliers.ItemizedVariable) AS ItemizedVariable,
	|	SUM(Multipliers.ItemizedVariableCostsExcludingVAT) AS ItemizedVariableCostsExcludingVAT,
	|	SUM(Multipliers.ItemizedVariableCostsCompl) AS ItemizedVariableCostsCompl,
	|	SUM(Multipliers.OffBalanceCost) AS OffBalanceCost,
	|	SUM(Multipliers.OffBalanceCostLocal) AS OffBalanceCostLocal
	|	
	|FROM
	|	Multipliers AS Multipliers
	|
	|GROUP BY
	|	Multipliers.StandardCostEstimate,
	|	Multipliers.LotProductBOM,
	|	Multipliers.ManufacturedProduct,
	|	Multipliers.ItemVariant,
	|	Multipliers.Purpose,
	|	Multipliers.LotSemiFinishedProductBOM,
	|	Multipliers.SemiFinishedProduct,
	|	Multipliers.ItemVariantsOfIntermediateProduct,
	|	Multipliers.KeyLot,
	|	Multipliers.Denominator,
	|	Multipliers.LotIsReleased";
	
	Multipliers = Query.Execute().Unload();
EndProcedure

Procedure WriteDocumentMultipliers(StandardCostEstimate, TablesForRegisteredRecords)
	
	Multipliers = Undefined;
	
	If Not TablesForRegisteredRecords.Property("Table" + "MultiplesOfLotsAndSemiFinishedProducts", Multipliers) Then
		Return;
	EndIf;
	
	RecordSet = InformationRegisters.MultiplesOfLotsAndSemiFinishedProducts.CreateRecordSet();
	RecordSet.Filter.StandardCostEstimate.Set(StandardCostEstimate);
	
	RecordSet.Load(Multipliers);
	
	SetPrivilegedMode(True);
	RecordSet.Write();
	SetPrivilegedMode(False);
	
EndProcedure

Procedure RecordRegisteredRecords(RegisterRecords, TempTablesManager, CalculationParameters)
	
	CurrentRegisteredRecords = CurrentQueueRegisteredRecords(CalculationParameters.StandardCostEstimate, TempTablesManager);
	
	DocumentObject = CalculationParameters.StandardCostEstimate.GetObject();
	
	For Each KeyAndValue In RegisterRecords Do
			
		RegisterName = KeyAndValue.Key;
		
		If RegisterName = "MultiplesOfLotsAndSemiFinishedProducts" Then
			Continue;
		EndIf;
		
		RegisterRegisteredRecords = DocumentObject.RegisterRecords[RegisterName];
		
		RegisterRecordTable = CurrentRegisteredRecords[RegisterName];
		RegisterRegisteredRecords.Load(RegisterRecordTable);
		
		RegisterRecordTable.GroupBy("LotBOM");
		BatchSpecifications = RegisterRecordTable.UnloadColumn("LotBOM");
		
		For Each String In KeyAndValue.Value Do
			
			If Not BatchSpecifications.Find(String.LotBOM) = Undefined Then
				Continue;
			EndIf;
			
			Record = RegisterRegisteredRecords.Add();
			FillPropertyValues(Record, String);
			Record.Active = True;
			Record.StandardCostEstimate = CalculationParameters.StandardCostEstimate;
			
		EndDo;
		
		RegisterRegisteredRecords.Write = True;
		
	EndDo;
	
	WriteDownMultipliers(RegisterRecords, CalculationParameters, TempTablesManager);
	
	SetPrivilegedMode(True);
	DocumentObject.RegisterRecords.Write();
	SetPrivilegedMode(False);
	
EndProcedure

Function CurrentQueueRegisteredRecords(StandardCostEstimate, TempTablesManager)
	
	QueryText =
		"SELECT
		|	PlannedMaterialCosts.Period,
		|	PlannedMaterialCosts.Recorder,
		|	PlannedMaterialCosts.LineNumber,
		|	PlannedMaterialCosts.Active,
		|	PlannedMaterialCosts.StandardCostEstimate,
		|	PlannedMaterialCosts.LotBOM,
		|	PlannedMaterialCosts.KeyLot AS KeyLot,
		|	PlannedMaterialCosts.Department,
		|	PlannedMaterialCosts.ProductCostElement,
		|	PlannedMaterialCosts.Products,
		|	PlannedMaterialCosts.Characteristic,
		|	PlannedMaterialCosts.ThisIsASemiFinishedProduct,
		|	PlannedMaterialCosts.CostPeriod,
		|	PlannedMaterialCosts.Count,
		|	PlannedMaterialCosts.Cost,
		|	PlannedMaterialCosts.CostExcludingVAT,
		|	PlannedMaterialCosts.LocalCost		
		|FROM
		|	AccumulationRegister.PlannedMaterialCosts AS PlannedMaterialCosts
		|WHERE
		|	PlannedMaterialCosts.Recorder = &Recorder
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT
		|	PlannedLaborCosts.Period,
		|	PlannedLaborCosts.Recorder,
		|	PlannedLaborCosts.LineNumber,
		|	PlannedLaborCosts.Active,
		|	PlannedLaborCosts.StandardCostEstimate,
		|	PlannedLaborCosts.LotBOM,
		|	PlannedLaborCosts.KeyLot AS KeyLot,
		|	PlannedLaborCosts.Department,
		|	PlannedLaborCosts.ProductCostElement,
		|	PlannedLaborCosts.WorkKind,
		|	PlannedLaborCosts.CostPeriod,
		|	PlannedLaborCosts.Count,
		|	PlannedLaborCosts.Cost,
		|	PlannedLaborCosts.LocalCost
		|FROM
		|	AccumulationRegister.PlannedLaborCosts AS PlannedLaborCosts
		|WHERE
		|	PlannedLaborCosts.Recorder = &Recorder
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT
		|	PlannedOtherCosts.Period,
		|	PlannedOtherCosts.Recorder,
		|	PlannedOtherCosts.LineNumber,
		|	PlannedOtherCosts.Active,
		|	PlannedOtherCosts.StandardCostEstimate,
		|	PlannedOtherCosts.LotBOM,
		|	PlannedOtherCosts.KeyLot AS KeyLot,
		|	PlannedOtherCosts.Department,
		|	PlannedOtherCosts.ProductCostElement,
		|	PlannedOtherCosts.ExpenseItem,
		|	PlannedOtherCosts.DimensionOfExpenses,
		|	PlannedOtherCosts.Cost,
		|	PlannedOtherCosts.CostExcludingVAT,
		|	PlannedOtherCosts.LocalCost
		|FROM
		|	AccumulationRegister.PlannedOtherCosts AS PlannedOtherCosts
		|WHERE
		|	PlannedOtherCosts.Recorder = &Recorder";
	
	Query = New Query(QueryText);
	
	Query.TempTablesManager = TempTablesManager;
	
	Query.SetParameter("Recorder", StandardCostEstimate);
	
	ResultsArray = Query.ExecuteBatch();
	
	Result = New Structure;
	
	Result.Insert("PlannedMaterialCosts", ResultsArray[0].Unload());
		
	Result.Insert("PlannedLaborCosts", ResultsArray[1].Unload());
	
	Result.Insert("PlannedOtherCosts", ResultsArray[2].Unload());
		
	Return Result;
	
EndFunction

Procedure ClearCalculationQueue(StandardCostEstimate, TempTablesManager)
	
	Query = New Query;
	Query.Text = 
		"SELECT
		|	CalculationQueue.StandardCostEstimate,
		|	CalculationQueue.LotProductBOM AS LotProductBOM,
		|	CalculationQueue.ManufacturedProduct,
		|	CalculationQueue.ItemVariant,
		|	CalculationQueue.Purpose AS Purpose,
		|	CalculationQueue.LotSemiFinishedProductBOM AS LotSemiFinishedProductBOM,
		|	CalculationQueue.KeyLot AS KeyLot,
		|	CalculationQueue.SemiFinishedProduct,
		|	CalculationQueue.ItemVariantsOfIntermediateProduct,
		|	CalculationQueue.Separator,
		|	CalculationQueue.Order,
		|	CalculationQueue.DemandDate
		|FROM
		|	CalculationQueue AS CalculationQueue
		|		INNER JOIN InformationRegister.CalculationQueueOfStandardCostEstimates AS CalculationQueueOfStandardCostEstimates
		|		ON CalculationQueue.StandardCostEstimate = CalculationQueueOfStandardCostEstimates.StandardCostEstimate
		|			AND CalculationQueue.LotProductBOM = CalculationQueueOfStandardCostEstimates.LotProductBOM
		|			AND CalculationQueue.ManufacturedProduct = CalculationQueueOfStandardCostEstimates.ManufacturedProduct
		|			AND CalculationQueue.ItemVariant = CalculationQueueOfStandardCostEstimates.ItemVariant
		|			AND CalculationQueue.Purpose = CalculationQueueOfStandardCostEstimates.Purpose
		|			AND CalculationQueue.LotSemiFinishedProductBOM = CalculationQueueOfStandardCostEstimates.LotSemiFinishedProductBOM
		|			AND CalculationQueue.KeyLot = CalculationQueueOfStandardCostEstimates.KeyLot
		|			AND CalculationQueue.SemiFinishedProduct = CalculationQueueOfStandardCostEstimates.SemiFinishedProduct
		|			AND CalculationQueue.ItemVariantsOfIntermediateProduct = CalculationQueueOfStandardCostEstimates.ItemVariantsOfIntermediateProduct
		|			AND CalculationQueue.Separator = CalculationQueueOfStandardCostEstimates.Separator
		|			AND CalculationQueue.DemandDate = CalculationQueueOfStandardCostEstimates.DemandDate
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|DROP CalculationQueue";
	
	Query.TempTablesManager = TempTablesManager;
	
	SetPrivilegedMode(True);
	ResultsArray = Query.ExecuteBatch();
	SetPrivilegedMode(False);
	
	Queue = ResultsArray[0].Unload();
	
	InformationRegisters.CalculationQueueOfStandardCostEstimates.ClearQueue(StandardCostEstimate, Queue);
	
EndProcedure

#EndRegion

#Region Convolutions

Procedure ReducePlannedMaterialCosts(CalculationParameters, PlannedMaterialCosts)
	CollapsedTable = PlannedMaterialCosts.Copy();
	CollapsedTable.Columns.Add("NegativeQuantity", New TypeDescription("Boolean"));
	For Each String In CollapsedTable Do
		If String.Count < 0 Then
			// We will not sum the negative amount with the positive ones, otherwise the intermediate output will be lost.
			String.NegativeQuantity = True;
		EndIf;
	EndDo;
	CollapsedTable.GroupBy(CalculationParameters.PlannedMaterialCosts_GroupingColumns + ",NegativeQuantity",
		CalculationParameters.PlannedMaterialCosts_SummationColumns);
	PlannedMaterialCosts.Clear();
	For Each String In CollapsedTable Do
		FillPropertyValues(PlannedMaterialCosts.Add(),
			String);
	EndDo;
EndProcedure

Procedure CurtailPlannedLaborCosts(CalculationParameters, PlannedLaborCosts)
	CollapsedTable = PlannedLaborCosts.Copy();
	CollapsedTable.GroupBy(CalculationParameters.PlannedLaborCosts_GroupingColumns,
		CalculationParameters.PlannedLaborCosts_SummationColumns);
	PlannedLaborCosts.Clear();
	For Each String In CollapsedTable Do
		FillPropertyValues(PlannedLaborCosts.Add(),
			String);
	EndDo;
EndProcedure

Procedure CollapseRegistersOfExpensesWithinFrameworkOfVT(CalculationParameters, StructureOfData)
	ReducePlannedMaterialCosts(CalculationParameters, StructureOfData.PlannedMaterialCosts);

	StructureOfData.PlannedOtherCosts.GroupBy("Period,StandardCostEstimate,LotBOM,Department,ProductCostElement,
		|ExpenseItem,KeyLot",
		"Cost,CostExcludingVAT,LocalCost");

	CurtailPlannedLaborCosts(CalculationParameters, StructureOfData.PlannedLaborCosts);
EndProcedure

#EndRegion

#Region Other

Procedure BlockData_(StandardCostEstimate)
	
	Block = New DataLock();
	
	AddLockRegisterMultipliersOfBatchesAndSemiFinishedProducts(Block, StandardCostEstimate);
	AddLockRegisterPlannedMaterialCosts(Block, StandardCostEstimate);
	AddLockRegisterScheduledLaborCosts(Block, StandardCostEstimate);
	AddLockRegisterPlannedOtherCosts(Block, StandardCostEstimate);
	
	Block.Lock();
	
EndProcedure

Procedure AddLockRegisterMultipliersOfBatchesAndSemiFinishedProducts(Block, StandardCostEstimate)
	
	LockItem = Block.Add("InformationRegister.MultiplesOfLotsAndSemiFinishedProducts");
	LockItem.SetValue("StandardCostEstimate", StandardCostEstimate);
	LockItem.Mode = DataLockMode.Exclusive;
	
EndProcedure

Procedure AddLockRegisterPlannedMaterialCosts(Block, StandardCostEstimate)
	
	LockItem = Block.Add("AccumulationRegister.PlannedMaterialCosts");
	LockItem.SetValue("StandardCostEstimate", StandardCostEstimate);
	LockItem.Mode = DataLockMode.Exclusive;
	
EndProcedure

Procedure AddLockRegisterScheduledLaborCosts(Block, StandardCostEstimate)
	
	LockItem = Block.Add("AccumulationRegister.PlannedLaborCosts");
	LockItem.SetValue("StandardCostEstimate", StandardCostEstimate);
	LockItem.Mode = DataLockMode.Exclusive;
	
EndProcedure

Procedure AddLockRegisterPlannedOtherCosts(Block, StandardCostEstimate)
	
	LockItem = Block.Add("AccumulationRegister.PlannedOtherCosts");
	LockItem.SetValue("StandardCostEstimate", StandardCostEstimate);
	LockItem.Mode = DataLockMode.Exclusive;
	
EndProcedure

Function CalculationQueue(StandardCostEstimate, TempTablesManager)
	
	Query = New Query;
	Query.TempTablesManager = TempTablesManager;
	Query.SetParameter("StandardCostEstimate", StandardCostEstimate);
	Query.Text = 
		"SELECT
		|	PC_Queue.StandardCostEstimate AS StandardCostEstimate,
		|	PC_Queue.LotProductBOM AS LotProductBOM,
		|	PC_Queue.ManufacturedProduct AS ManufacturedProduct,
		|	PC_Queue.ItemVariant AS ItemVariant,
		|	PC_Queue.Purpose AS Purpose,
		|	PC_Queue.LotSemiFinishedProductBOM AS LotSemiFinishedProductBOM,
		|	PC_Queue.KeyLot AS KeyLot,
		|	PC_Queue.SemiFinishedProduct AS SemiFinishedProduct,
		|	PC_Queue.ItemVariantsOfIntermediateProduct AS ItemVariantsOfIntermediateProduct,
		|	PC_Queue.DemandDate AS DemandDate,
		|	PC_Queue.Order AS Order,
		|	MAX(PC_Queue.Separator) AS Separator
		|INTO CalculationQueue
		|FROM
		|	InformationRegister.CalculationQueueOfStandardCostEstimates AS PC_Queue
		|WHERE
		|	PC_Queue.StandardCostEstimate = &StandardCostEstimate
		|	AND NOT PC_Queue.UndoPosting
		|
		|GROUP BY
		|	PC_Queue.DemandDate,
		|	PC_Queue.ItemVariantsOfIntermediateProduct,
		|	PC_Queue.SemiFinishedProduct,
		|	PC_Queue.LotSemiFinishedProductBOM,
		|	PC_Queue.KeyLot,
		|	PC_Queue.Purpose,
		|	PC_Queue.ItemVariant,
		|	PC_Queue.ManufacturedProduct,
		|	PC_Queue.LotProductBOM,
		|	PC_Queue.Order,
		|	PC_Queue.StandardCostEstimate
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT TOP 1
		|	CalculationQueue.StandardCostEstimate AS StandardCostEstimate
		|FROM
		|	CalculationQueue AS CalculationQueue";
		
	SetPrivilegedMode(True);
	ResultsArray = Query.ExecuteBatch();
	SetPrivilegedMode(False);
	
	ThereAreEntriesInQueue = Not ResultsArray[1].IsEmpty();
	
	Return ThereAreEntriesInQueue;
	
EndFunction

Function DocumentQueued(StandardCostEstimate)
	
	Query = New Query;
	Query.Text = 
		"SELECT TOP 1
		|	Queue.StandardCostEstimate AS StandardCostEstimate,
		|	MAX(Queue.UndoPosting) AS UndoPosting
		|FROM
		|	InformationRegister.CalculationQueueOfStandardCostEstimates AS Queue
		|WHERE
		|	Queue.ManufacturedProduct = VALUE(Catalog.Products.EmptyRef)
		|	AND Queue.StandardCostEstimate = &StandardCostEstimate
		|
		|GROUP BY
		|	Queue.StandardCostEstimate
		|
		|HAVING
		|	MAX(Queue.UndoPosting) = FALSE";
	
	Query.SetParameter("StandardCostEstimate", StandardCostEstimate);
	
	SetPrivilegedMode(True);
	Result = Query.Execute();
	SetPrivilegedMode(False);
	
	Selection = Result.Select();
	
	If Selection.Next() Then
		Return Selection.StandardCostEstimate;
	EndIf;
	
	Return Undefined;
	
EndFunction

Function ThereAreTasksInQueue(StandardCostEstimate)
	
	Query = New Query(
		"SELECT
		|	Queue.Separator AS Separator
		|FROM
		|	InformationRegister.CalculationQueueOfStandardCostEstimates AS Queue
		|WHERE
		|	Queue.StandardCostEstimate = &StandardCostEstimate
		|	AND NOT Queue.UndoPosting");
	
	Query.SetParameter("StandardCostEstimate", StandardCostEstimate);
	
	SetPrivilegedMode(True);
	Return (Not Query.Execute().IsEmpty());
	
EndFunction

Function ItIsRequiredToFindOutOrderOfDinStructure(TempTablesManager, CalculationParameters)
	
	Query = New Query;
	Query.SetParameter("StandardCostEstimate", CalculationParameters.StandardCostEstimate);
	
	Query.Text =
	"SELECT TOP 1
	|	TRUE AS ThereAreOrdersWithDinStructure
	|FROM
	|	Document.StandardCosting2_2.CostObjects AS DD
	|WHERE
	|	DD.Ref = &StandardCostEstimate
	|	AND TRUE IN (SELECT TOP 1 TRUE 
	|					FROM Document.ProductionOrder2_2 AS ProductionOrderDetails
	|					WHERE ProductionOrderDetails.Ref = DD.Object
	|					AND ProductionOrderDetails.DynamicStructure)";
	
	SetPrivilegedMode(True);
	Return Not Query.Execute().IsEmpty();
	
EndFunction

Function ItIsRequiredToUnravelOrder(TempTablesManager)
	
	Query = New Query;
	Query.TempTablesManager = TempTablesManager;
	
	Query.Text =
		"SELECT TOP 1
		|	CalculationQueue.ManufacturedProduct
		|FROM
		|	CalculationQueue AS CalculationQueue
		|WHERE
		|	VALUETYPE(CalculationQueue.LotProductBOM) = TYPE(Document.ProductionStage2_2)
		|	AND CalculationQueue.SemiFinishedProduct = VALUE(Catalog.Products.EmptyRef)";
	
	SetPrivilegedMode(True);
	Return Not Query.Execute().IsEmpty();
	
EndFunction

Procedure UpdateStateOfCalculations(Calculations_)
	
	Query = New Query;
	Query.Text = 
		"SELECT
		|	StatesOfStandardCostEstimates.StandardCostEstimate AS StandardCostEstimate
		|FROM
		|	InformationRegister.StatesOfStandardCostEstimates AS StatesOfStandardCostEstimates
		|WHERE
		|	StatesOfStandardCostEstimates.StandardCostEstimate IN(&Calculations_)
		|	AND NOT StatesOfStandardCostEstimates.State = VALUE(Enum.StatesOfStandardCostEstimateCalculation.CalculationError)";
	
	Query.SetParameter("Calculations_", Calculations_);
	
	SetPrivilegedMode(True);
	Result = Query.Execute();
	SetPrivilegedMode(False);
	
	Selection = Result.Select();
	
	While Selection.Next() Do
		RecordStateOfCalculation(Selection.StandardCostEstimate, 
			Enums.StatesOfStandardCostEstimateCalculation.CalculateWithErrors);
	EndDo;
	
EndProcedure

Procedure LogCalculationError(StandardCostEstimate, Cause)
	
	MessageText = NStr("vi = 'Không thể kết chuyển chứng từ: %Ref% vì lý do: %Cause%';
						|ru = 'Не удалось выполнить проведение документа %Ref%  по причине: %Cause%';
						|en = 'Cannot post document %Ref%. Reason: %Cause%'; fa = 'Cannot post document %Ref%. Reason: %Cause%';
						|it = 'Non è stato possibile effettuare il movimento del documento %Ref%  a causa di: %Cause%';
						|pl = 'Nie można wykonać zaksięgowanie dokumentu %Ref% z powodu: %Cause%';
						|tr = '%Cause% nedeniyle %Ref% belge kaydı gerçekleştirilemedi'");
	
	MessageText = StrReplace(MessageText, "%Ref%", StandardCostEstimate);
	MessageText = StrReplace(MessageText, "%Cause%", Cause);
		
	WriteLogEvent(
		EventLogEntryCalculationError(),
		EventLogLevel.Error,
		StandardCostEstimate.Metadata(),
		StandardCostEstimate,
		MessageText);
	
EndProcedure

Function EventLogEntryCalculationError() Export
	
	Return NStr("vi = 'Kết chuyển tính giá thành bằng nhiệm vụ nền.';
				|ru = 'Фоновое проведение калькуляции продукции.';
				|en = 'Background posting of product costing.'; fa = 'Background posting of product costing.';
				|it = 'Pubblicazione del calcolo prodotti in background.';
				|pl = 'Prowadzenie kalkulacji produkcji w tle.';
				|tr = 'İmal edilen ürün hesaplamasının arka plan kaydı.'", Common.DefaultLanguageCode());
	
EndFunction

// Initializes the calculation parameters.
//
// Parameters:
//  CalculationParameters - Structure - primary structure with calculation parameters.
//  Measurement - Compliance - Description in the Performance estimator.Start a long-term operation.
//
// Returns:
//  Structure - contains calculation parameters:
//   * PCDetails - Map - compliance with the values of the Attributes of the Product standard cost.
//   * Measurement - See PerformanceMonitor.StartTimeConsumingOperationMeasurement.
//   * DataVolume - Number - an indicator of the amount of processed data for measurement.
//   * ExplosionError - String - description of the errors that occurred in the process of uncoupling.
//   * PeriodNotCalculatedForOrganization - Date - The date of the non-calculated period according to the company's planned calculation.
//
Function DefineCalculationParameters(CalculationParameters)
	
	ListOfPCDetails = "Date,ProductionDispatcherBusinessUnit,PriceKind,Organization";
	
	PCDetails = Common.ObjectAttributesValues(CalculationParameters.StandardCostEstimate, 
		ListOfPCDetails);
	
	// The start of the background calculation task may occur before the transaction of recording the planned calculation document is committed,
	// in order to avoid the error of receiving incorrect calculation data, a cyclic repetition of the data request
	// with a one-second pause between attempts and a limit on the number of attempts (60 times) has been implemented
	NumberOfReadingAttempts = 60;
	While NumberOfReadingAttempts > 0 And PCDetails.Date = Undefined Do
		CommonCTL.Pause(1);
		PCDetails = Common.ObjectAttributesValues(CalculationParameters.StandardCostEstimate,
			ListOfPCDetails);
		NumberOfReadingAttempts = NumberOfReadingAttempts - 1;
	EndDo;
	
	PCDetails.Insert("CalculationDate", EndOfDay(PCDetails.Date));
	PCDetails.Insert("BeginningOfMonthOfCalculationDate", BegOfMonth(PCDetails.Date));
	CalculationParameters.Insert("PCDetails", PCDetails);
	
	TypeOfPricePlannedCostOfInventory = Catalogs.TypesOfPrices.TypeOfPricePlannedCostOfInventory();
	CalculationParameters.Insert("TypeOfPricePlannedCostOfInventory", TypeOfPricePlannedCostOfInventory);
	CalculationParameters.Insert("CurrencyOfPriceOfPlannedCostOfInventory",
		Common.ObjectAttributeValue(TypeOfPricePlannedCostOfInventory, "PriceCurrency"));
		
	CalculationParameters.Insert("BaseCurrency", SettingsValueCached.DefaultBaseCurrency());
	CalculationParameters.Insert("KeepRecordsOfInventoryCostByAssignments",
		CalculationOfCostCached.CostOfGoodsForPurposes());
	
	CalculationParameters.Insert("DataVolume", 0);
	CalculationParameters.Insert("ExplosionError", "");
	CalculationParameters.Insert("EventLogEntryCalculationError", EventLogEntryCalculationError());
	CalculationParameters.Insert("ExplosionError", "");
	CalculationParameters.Insert("EmptyUID", CommonClientServer.BlankUUID());
	CalculationParameters.Insert("EmptyUIDString", String(CalculationParameters.EmptyUID));
	CalculationParameters.Insert("PeriodNotCalculatedForOrganization",
		InformationRegisters.JobsForCalculatingCost.GetUnCalculatedPeriodForOrganization(PCDetails.Organization));
	
	CalculationParameters.Insert("Multipliers_GroupingColumnsWithoutPriority",
		"Period,StandardCostEstimate,LotProductBOM,ManufacturedProduct,ItemVariant,
		|Purpose,LotSemiFinishedProductBOM,KeyLot,SemiFinishedProduct,ItemVariantsOfIntermediateProduct,
		|CalculationIsCompleted,LotIsReleased,Denominator,Order"); //@Query-part
	CalculationParameters.Insert("Multipliers_GroupingColumns",
		CalculationParameters.Multipliers_GroupingColumnsWithoutPriority + ",Priority"); //@Query-part
	CalculationParameters.Insert("Multipliers_SummationColumns",
		"Numerator,QuantityOfSemiFinishedProduct,Cost,CostExcludingVAT,LocalCost,LaborCosts,
		|LaborCostsLocal,ItemizedFixed,ItemizedFixedCostsExcludingVAT,ItemizedFixedCostsCompl,
		|ItemizedVariable,ItemizedVariableCostsExcludingVAT,ItemizedVariableCostsCompl,OffBalanceCost,
		|OffBalanceCostLocal"); //@Query-part
		
	CalculationParameters.Insert("PlannedMaterialCosts_GroupingColumns",
		"Period,StandardCostEstimate,LotBOM,Department,ProductCostElement,
		|Products,Characteristic,KeyLot,ThisIsASemiFinishedProduct,CostPeriod"); //@Query-part
	CalculationParameters.Insert("PlannedMaterialCosts_SummationColumns",
		"Count,Cost,CostExcludingVAT,LocalCost,OffBalanceCost,OffBalanceCostLocal"); //@Query-part
		
	CalculationParameters.Insert("PlannedLaborCosts_GroupingColumns", "Period,StandardCostEstimate,LotBOM,
		|Department,ProductCostElement,WorkKind,KeyLot,CostPeriod"); //@Query-part
	CalculationParameters.Insert("PlannedLaborCosts_SummationColumns",
		"Count,Cost,LocalCost"); //@Query-part
		
	Return CalculationParameters;
	
EndFunction

#EndRegion

#Region Costs_2

Procedure FillInCosts(CalculationParameters)
	
	If ThereWasCancellationOfEvent(CalculationParameters.StandardCostEstimate) Then
		Return;
	EndIf;
		
	BeginTransaction();
	
	Try
		
		BlockData_(CalculationParameters.StandardCostEstimate);
		
		TempTableManager = New TempTablesManager;
		
		PrepareServiceTemporaryTables(TempTableManager, CalculationParameters.StandardCostEstimate);
		// Calculation of the cost of materials.
		FillInCostOfMaterials(CalculationParameters.StandardCostEstimate, TempTableManager);
		
		// Calculation of labor costs.
		FillInCostOfLabor(CalculationParameters.StandardCostEstimate, TempTableManager);
		
		CalculatePreliminaryCost_(CalculationParameters, TempTableManager);
		
		// Calculation of item-by-item expenses.
		FillInCostOfArticleByArticle(CalculationParameters, TempTableManager);
		
		CalculatePreliminaryCost_(CalculationParameters, TempTableManager);

		Query = New Query;
		Query.TempTablesManager = TempTableManager;
		
		Query.Text = 
			"SELECT
			|	UsedMaterials.Period,
			|	UsedMaterials.CostPeriod,
			|	UsedMaterials.StandardCostEstimate,
			|	UsedMaterials.LotBOM,
			|	UsedMaterials.Department,
			|	UsedMaterials.ProductCostElement,
			|	UsedMaterials.KeyLot,
			|	UsedMaterials.Products,
			|	UsedMaterials.Characteristic,
			|	UsedMaterials.ThisIsASemiFinishedProduct,
			|	UsedMaterials.Count,
			|	UsedMaterials.Cost
			|		+ UsedMaterials.LaborCosts
			|		+ UsedMaterials.ItemizedFixed
			|		+ UsedMaterials.ItemizedVariable AS Cost,
			|	UsedMaterials.CostExcludingVAT
			|		+ UsedMaterials.LaborCosts
			|		+ UsedMaterials.ItemizedFixedCostsExcludingVAT
			|		+ UsedMaterials.ItemizedVariableCostsExcludingVAT AS CostExcludingVAT,
			|	UsedMaterials.LocalCost
			|		+ UsedMaterials.LaborCostsLocal
			|		+ UsedMaterials.ItemizedFixedCostsCompl
			|		+ UsedMaterials.ItemizedVariableCostsCompl AS LocalCost,
			|	UsedMaterials.OffBalanceCost,
			|	UsedMaterials.OffBalanceCostLocal
			|FROM
			|	MaterialCostsIncludingSemiFinishedProducts AS UsedMaterials
			|;
			|
			|////////////////////////////////////////////////////////////////////////////////
			|SELECT
			|	PlannedLaborCosts.Period,
			|	PlannedLaborCosts.CostPeriod,
			|	PlannedLaborCosts.StandardCostEstimate,
			|	PlannedLaborCosts.LotBOM,
			|	PlannedLaborCosts.KeyLot,
			|	PlannedLaborCosts.Department,
			|	PlannedLaborCosts.ProductCostElement,
			|	PlannedLaborCosts.WorkKind,
			|	PlannedLaborCosts.Count,
			|	PlannedLaborCosts.Cost,
			|	PlannedLaborCosts.LocalCost
			|FROM
			|	PlannedLaborCosts AS PlannedLaborCosts
			|;
			|
			|////////////////////////////////////////////////////////////////////////////////
			|SELECT
			|	PlannedOtherCosts.Period,
			|	PlannedOtherCosts.StandardCostEstimate,
			|	PlannedOtherCosts.LotBOM,
			|	PlannedOtherCosts.KeyLot,
			|	PlannedOtherCosts.Department,
			|	PlannedOtherCosts.ProductCostElement,
			|	PlannedOtherCosts.ExpenseItem,
			|	PlannedOtherCosts.Cost,
			|	PlannedOtherCosts.CostExcludingVAT,
			|	PlannedOtherCosts.LocalCost
			|FROM
			|	PlannedOtherCosts AS PlannedOtherCosts
			|WHERE
			|	PlannedOtherCosts.Cost <> 0
			|	OR PlannedOtherCosts.CostExcludingVAT <> 0 
			|	OR PlannedOtherCosts.LocalCost <> 0
			|;
			|
			|////////////////////////////////////////////////////////////////////////////////
			|SELECT
			|	Multipliers.Period,
			|	Multipliers.ManufacturedProduct,
			|	Multipliers.LotProductBOM,
			|	Multipliers.StandardCostEstimate,
			|	Multipliers.ItemVariant,
			|	Multipliers.Purpose,
			|	Multipliers.Cost,
			|	Multipliers.CostExcludingVAT,
			|	Multipliers.LocalCost,
			|	Multipliers.OffBalanceCost,
			|	Multipliers.OffBalanceCostLocal,
			|	Multipliers.LaborCosts,
			|	Multipliers.LaborCostsLocal,
			|	Multipliers.ItemizedVariable,
			|	Multipliers.ItemizedFixedCostsExcludingVAT,
			|	Multipliers.ItemizedFixedCostsCompl,
			|	Multipliers.ItemizedFixed,
			|	Multipliers.ItemizedVariableCostsExcludingVAT,
			|	Multipliers.ItemizedVariableCostsCompl,
			|	Multipliers.LotSemiFinishedProductBOM,
			|	Multipliers.KeyLot,
			|	Multipliers.SemiFinishedProduct,
			|	Multipliers.ItemVariantsOfIntermediateProduct,
			|	Multipliers.Order,
			|	Multipliers.Numerator,
			|	Multipliers.Denominator,
			|	Multipliers.QuantityOfSemiFinishedProduct,
			|	Multipliers.CalculationIsCompleted,
			|	Multipliers.LotIsReleased
			|FROM
			|	MultiplesOfLotsAndSemiFinishedProducts AS Multipliers";
		
		Query.SetParameter("StandardCostEstimate", CalculationParameters.StandardCostEstimate);
		
		ResultsArray = Query.ExecuteBatch();
		
		DocumentObject = CalculationParameters.StandardCostEstimate.GetObject();
		
		StructureOfData = New Structure();
		StructureOfData.Insert("MultiplesOfLotsAndSemiFinishedProducts", ResultsArray[3].Unload());
		StructureOfData.Insert("PlannedMaterialCosts", ResultsArray[0].Unload());
		StructureOfData.Insert("PlannedLaborCosts", ResultsArray[1].Unload());
		StructureOfData.Insert("PlannedOtherCosts", ResultsArray[2].Unload());
		CalculateMultipliersFromActualData(StructureOfData, CalculationParameters);
		
		DocumentObject.RegisterRecords.PlannedMaterialCosts.Load(StructureOfData.PlannedMaterialCosts);
		DocumentObject.RegisterRecords.PlannedLaborCosts.Load(StructureOfData.PlannedLaborCosts);
		DocumentObject.RegisterRecords.PlannedOtherCosts.Load(StructureOfData.PlannedOtherCosts);
		
		DocumentObject.RegisterRecords.PlannedMaterialCosts.Write = True;
		DocumentObject.RegisterRecords.PlannedLaborCosts.Write = True;
		DocumentObject.RegisterRecords.PlannedOtherCosts.Write = True;
		
		SetPrivilegedMode(True);
		DocumentObject.RegisterRecords.Write();
		SetPrivilegedMode(False);
		
		TablesForRegisteredRecords = New Structure("Table" + "MultiplesOfLotsAndSemiFinishedProducts",
			StructureOfData.MultiplesOfLotsAndSemiFinishedProducts);
		WriteDocumentMultipliers(CalculationParameters.StandardCostEstimate, TablesForRegisteredRecords);
		
		For Each RecordSet In DocumentObject.RegisterRecords Do
			CalculationParameters.DataVolume = CalculationParameters.DataVolume + RecordSet.Count();
		EndDo;
		
		CommitTransaction();
		
	Except
		
		RollbackTransaction();
		
		ErrorInfo = ErrorInfo();
		RecordStateOfCalculation(CalculationParameters.StandardCostEstimate, 
			Enums.StatesOfStandardCostEstimateCalculation.CalculationError);
		InformationRegisters.CalculationQueueOfStandardCostEstimates.ClearQueue(CalculationParameters.StandardCostEstimate);
		LogCalculationError(CalculationParameters.StandardCostEstimate,
			ErrorProcessing.DetailErrorDescription(ErrorInfo));
		
	EndTry;
	
EndProcedure

Procedure FillInCostOfMaterials(StandardCostEstimate, TempTableManager)
	
	GetProductPrices(StandardCostEstimate, TempTableManager);
	
	Query = New Query;
	Query.TempTablesManager = TempTableManager;
	
	AttributesValues = Common.ObjectAttributesValues(StandardCostEstimate, "PriceKind, Date, Organization");
		
	Query.SetParameter("StandardCostEstimate", StandardCostEstimate);
	Query.SetParameter("PriceKind", AttributesValues.PriceKind);
	Query.SetParameter("Period", AttributesValues.Date);
	Query.SetParameter("BaseCurrency", SettingsValueCached.CurrencyOfOrganizationSRegulatedAccounting(AttributesValues.Organization));
	Query.SetParameter("RegistrationCountry", SettingsValueClientServerCached.CountryOfOrganizationRegistration(AttributesValues.Organization));
	
	Query.Text =
		"SELECT DISTINCT
		|	ItemsPrices.Currency AS Currency
		|INTO CurrenciesOfProductRange
		|FROM
		|	ItemsPrices AS ItemsPrices
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT
		|	CurrenciesOfProductRange.Currency AS Currency,
		|	ISNULL(CurrencyRatesCut.CourseNumerator, 0) AS CourseNumerator,
		|	ISNULL(CurrencyRatesCut.CourseDenominator, 0) AS CourseDenominator
		|INTO ExchangeRatesOfProductRange
		|FROM
		|	CurrenciesOfProductRange AS CurrenciesOfProductRange
		|		LEFT JOIN InformationRegister.RelativeExchangeRates.SliceLast(
		|				&Period,
		|				Currency IN
		|					(SELECT
		|						Currencies.Currency AS Currency
		|					FROM
		|						CurrenciesOfProductRange AS Currencies)
		|					AND BaseCurrency = &BaseCurrency) AS CurrencyRatesCut
		|		ON CurrenciesOfProductRange.Currency = CurrencyRatesCut.Currency
		|
		|INDEX BY
		|	Currency
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT
		|	PlannedMaterialCosts.StandardCostEstimate AS StandardCostEstimate,
		|	PlannedMaterialCosts.LotBOM AS LotBOM,
		|	PlannedMaterialCosts.KeyLot AS KeyLot,
		|	PlannedMaterialCosts.Department AS Department,
		|	PlannedMaterialCosts.ProductCostElement AS ProductCostElement,
		|	PlannedMaterialCosts.Products AS Products,
		|	PlannedMaterialCosts.Characteristic AS Characteristic,
		|	PlannedMaterialCosts.Count AS Count,
		|	PlannedMaterialCosts.Period AS Period,
		|	CASE
		|		WHEN NOT PlannedMaterialCosts.Cost = 0
		|			AND NOT (PlannedMaterialCosts.Count > 0 AND PlannedMaterialCosts.Cost = -1)
		|			THEN PlannedMaterialCosts.Cost
		|		ELSE PlannedMaterialCosts.Count * ISNULL(ItemsPrices.Price, 0)
		|			* CASE
		|				WHEN ItemsPrices.Currency = MaExchangeRates.Currency
		|					THEN 1
		|				WHEN ExchangeRatesOfProductRange.CourseDenominator IS NULL OR MaExchangeRates.CourseNumerator IS NULL
		|					THEN 1
		|				ELSE ExchangeRatesOfProductRange.CourseNumerator * MaExchangeRates.CourseDenominator / (ExchangeRatesOfProductRange.CourseDenominator * MaExchangeRates.CourseNumerator)
		|			END
		|			* CASE
		|				WHEN Count > 0
		|					AND PlannedMaterialCosts.Cost = -1
		|					THEN 1
		|				WHEN PlannedMaterialCosts.Count < 0
		|					THEN 1
		|				WHEN TypesOfPrices.Ref IS NULL
		|					THEN 1
		|				WHEN TypesOfPrices.PriceIncludesVAT
		|					THEN 1
		|				WHEN (ISNULL(ProductsVATRates.VATRate, BasicVATRates.VATRate)) IS NULL
		|					THEN 1
		|				WHEN (ISNULL(ProductsVATRates.VATRate, BasicVATRates.VATRate)).Rate1 > 0
		|					THEN ((ISNULL(ProductsVATRates.VATRate, BasicVATRates.VATRate)).Rate1 + 100) / 100
		|				ELSE (ISNULL(ProductsVATRates.VATRate, BasicVATRates.VATRate)).Rate1
		|			END
		|	END AS Cost,
		|	PlannedMaterialCosts.ThisIsASemiFinishedProduct AS ThisIsASemiFinishedProduct,
		|	PlannedMaterialCosts.CostPeriod AS CostPeriod,
		|	CASE
		|		WHEN NOT PlannedMaterialCosts.LocalCost = 0
		|			AND NOT (PlannedMaterialCosts.Count > 0 AND PlannedMaterialCosts.LocalCost = -1)
		|			THEN PlannedMaterialCosts.LocalCost
		|		ELSE PlannedMaterialCosts.Count * ISNULL(ItemsPrices.Price, 0)
		|	END * CASE
		|		WHEN ItemsPrices.Currency = ACExchangeRates.Currency
		|			THEN 1
		|		WHEN ISNULL(ExchangeRatesOfProductRange.CourseDenominator, 0) * ACExchangeRates.CourseNumerator = 0
		|			THEN 1
		|		ELSE ExchangeRatesOfProductRange.CourseNumerator * ACExchangeRates.CourseDenominator / (ExchangeRatesOfProductRange.CourseDenominator * ACExchangeRates.CourseNumerator)
		|	END / CASE
		|		WHEN Count > 0
		|			AND PlannedMaterialCosts.LocalCost = -1
		|			THEN 1
		|		WHEN PlannedMaterialCosts.Count < 0
		|			THEN 1
		|		WHEN TypesOfPrices.Ref IS NULL
		|			THEN 1
		|		WHEN NOT TypesOfPrices.PriceIncludesVAT
		|			THEN 1
		|		ELSE ((ISNULL(ProductsVATRates.VATRate, ISNULL(BasicVATRates.VATRate, VALUE(Catalog.VATRates.EmptyRef)))).Rate1 + 100) / 100
		|	END AS LocalCost,
		|	CASE
		|		WHEN NOT PlannedMaterialCosts.CostExcludingVAT = 0
		|			AND NOT (PlannedMaterialCosts.Count > 0 AND PlannedMaterialCosts.CostExcludingVAT = -1)
		|			THEN PlannedMaterialCosts.CostExcludingVAT
		|		ELSE PlannedMaterialCosts.Count * ISNULL(ItemsPrices.Price, 0)
		|	END * CASE
		|		WHEN ItemsPrices.Currency = MaExchangeRates.Currency
		|			THEN 1
		|		WHEN ISNULL(ExchangeRatesOfProductRange.CourseDenominator, 0) * MaExchangeRates.CourseNumerator = 0
		|			THEN 1
		|		ELSE ExchangeRatesOfProductRange.CourseNumerator * MaExchangeRates.CourseDenominator / (ExchangeRatesOfProductRange.CourseDenominator * MaExchangeRates.CourseNumerator)
		|	END / CASE
		|		WHEN Count > 0
		|			AND PlannedMaterialCosts.CostExcludingVAT = -1
		|			THEN 1
		|		WHEN PlannedMaterialCosts.Count < 0
		|			THEN 1
		|		WHEN TypesOfPrices.Ref IS NULL
		|			THEN 1
		|		WHEN NOT TypesOfPrices.PriceIncludesVAT
		|			THEN 1
		|		ELSE ((ISNULL(ProductsVATRates.VATRate, ISNULL(BasicVATRates.VATRate, VALUE(Catalog.VATRates.EmptyRef)))).Rate1 + 100) / 100
		|	END AS CostExcludingVAT,
		|	PlannedMaterialCosts.OffBalanceCost AS OffBalanceCost,
		|	PlannedMaterialCosts.OffBalanceCostLocal AS OffBalanceCostLocal
		|INTO MaterialCosts
		|FROM
		|	AccumulationRegister.PlannedMaterialCosts AS PlannedMaterialCosts
		|		LEFT JOIN ItemsPrices AS ItemsPrices
		|		ON PlannedMaterialCosts.Products = ItemsPrices.Products
		|			AND PlannedMaterialCosts.Characteristic = ItemsPrices.Characteristic
		|			AND PlannedMaterialCosts.Period = ItemsPrices.Period
		|		LEFT JOIN ExchangeRatesOfProductRange AS ExchangeRatesOfProductRange
		|		ON (ItemsPrices.Currency = ExchangeRatesOfProductRange.Currency)
		|		LEFT JOIN ExchangeRates AS MaExchangeRates
		|		ON (MaExchangeRates.TypeOfCurrency = ""CurrencyOfManAccounting"")
		|		LEFT JOIN ExchangeRates AS ACExchangeRates
		|		ON (ACExchangeRates.TypeOfCurrency = ""CurrencyOfComplianceAccounting"")
		|		LEFT JOIN Catalog.TypesOfPrices AS TypesOfPrices
		|		ON (TypesOfPrices.Ref = &PriceKind)
		|		LEFT JOIN InformationRegister.ProductsVATRates.SliceLast(&Period,
		|			Country = &RegistrationCountry OR Country = VALUE(Catalog.WorldCountries.EmptyRef)) AS ProductsVATRates
		|		ON PlannedMaterialCosts.Products = ProductsVATRates.Products
		|		LEFT JOIN InformationRegister.BasicVATRates.SliceLast(&Period, Country = &RegistrationCountry) AS BasicVATRates
		|		ON (TRUE)
		|WHERE
		|	PlannedMaterialCosts.StandardCostEstimate = &StandardCostEstimate
		|
		|INDEX BY
		|	StandardCostEstimate,
		|	LotBOM
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|DROP ItemsPrices
		|;
		|
		|
		|////////////////////////////////////////////////////////////////////////////////
		|DROP CurrenciesOfProductRange";
	
	SetPrivilegedMode(True);
	Query.Execute();
	SetPrivilegedMode(False);
		
EndProcedure

Procedure GetProductPrices(Calculations_, TempTableManager) Export
	
	ListOfCalculations = New Array;
	If Not TypeOf(Calculations_) = Type("Array") Then
		ListOfCalculations = TMCommonUseClientServer.Array(Calculations_);
	Else
		ListOfCalculations = Calculations_;
	EndIf;
	
	Query = New Query;
	Query.TempTablesManager = TempTableManager;
	Query.SetParameter("ListOfCalculations", ListOfCalculations);
	Query.SetParameter("BaseCurrency", SettingsValueCached.DefaultBaseCurrency());
	
	Query.Text = 
		"SELECT
		|	RECORDAUTONUMBER() AS LineNumber,
		|	Costs.StandardCostEstimate AS StandardCostEstimate,
		|	Costs.StandardCostEstimate.PriceKind AS PriceKind,
		|	Costs.Products AS Products,
		|	Costs.Characteristic AS Characteristic,
		|	Costs.Period AS Period
		|INTO ProductsForPrices
		|FROM
		|	AccumulationRegister.PlannedMaterialCosts AS Costs
		|WHERE
		|	Costs.StandardCostEstimate IN (&ListOfCalculations)
		|
		|GROUP BY
		|	Costs.StandardCostEstimate,
		|	Costs.Products,
		|	Costs.Characteristic,
		|	Costs.Period
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT
		|	MAX(ProductsForPrices.LineNumber) AS LineNumber,
		|	ProductsForPrices.Period,
		|	ProductsForPrices.PriceKind AS PriceKind,
		|	ProductsForPrices.Products AS Products,
		|	ProductsForPrices.Characteristic AS Characteristic,
		|	VALUE(Catalog.PackagesAndUnitsOfMeasure.EmptyRef) AS Package,
		|	0 AS Price
		|FROM
		|	ProductsForPrices AS ProductsForPrices
		|
		|GROUP BY
		|	ProductsForPrices.Products,
		|	ProductsForPrices.Characteristic,
		|	ProductsForPrices.PriceKind,
		|	ProductsForPrices.Period
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT DISTINCT
		|	T.Period,
		|	T.PriceKind AS PriceKind,
		|	&BaseCurrency AS CurrencyOfComplianceAccounting
		|FROM
		|	ProductsForPrices AS T";
	
	
	SetPrivilegedMode(True);
	Result = Query.ExecuteBatch();
	UsedMaterials = Result[Result.Count() - 2].Unload();
	Selection = Result[Result.Count() - 1].Select();
	
	MaterialsWithPrices = UsedMaterials.CopyColumns("Products, Characteristic, PriceKind");
	MaterialsWithPrices.Columns.Add("Period", New TypeDescription("Date"));
	MaterialsWithPrices.Columns.Add("Currency", New TypeDescription("CatalogRef.Currencies"));
	MaterialsWithPrices.Columns.Add("Price", Metadata.DefinedTypes.MonetaryAmountNonNegative.Type);
	
	While Selection.Next() Do
		
		PriceFillingParameters = EnterprisePricesFillingServer.NewFillOptionsFillPrices();
		PriceFillingParameters.Date = Selection.Period;
		PriceFillingParameters.Currency = Selection.CurrencyOfComplianceAccounting;
		PriceFillingParameters.PriceKind = Selection.PriceKind;
		
		MaterialsToGetPrice = UsedMaterials.Copy(New Structure("Period, PriceKind", Selection.Period, Selection.PriceKind));
	    EnterprisePricesFillingServer.FillInPrices(MaterialsToGetPrice,, PriceFillingParameters);
		
		For Each ProcessedMaterial In MaterialsToGetPrice Do
			
			NewEntryWithPrice = MaterialsWithPrices.Add();
			FillPropertyValues(NewEntryWithPrice, ProcessedMaterial);
			
			NewEntryWithPrice.Period = Selection.Period;
			NewEntryWithPrice.PriceKind = Selection.PriceKind;
			NewEntryWithPrice.Currency = Selection.CurrencyOfComplianceAccounting;
			
		EndDo;
		
	EndDo;
	
	Query.SetParameter("MaterialsWithPrices", MaterialsWithPrices);
	Query.Text =
		"SELECT
		|	T.Period AS Period,
		|	T.Products AS Products,
		|	T.Characteristic AS Characteristic,
		|	T.PriceKind AS PriceKind,
		|	T.Currency AS Currency,
		|	T.Price AS Price
		|INTO PreliminaryProductPricing
		|FROM
		|	&MaterialsWithPrices AS T
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT DISTINCT
		|	Costs.StandardCostEstimate AS StandardCostEstimate,
		|	Costs.Period AS Period,
		|	Costs.Products AS Products,
		|	Costs.Characteristic AS Characteristic,
		|	Costs.Recorder.PriceKind AS PriceKind
		|INTO Costs
		|FROM
		|	AccumulationRegister.PlannedMaterialCosts AS Costs
		|WHERE
		|	Costs.StandardCostEstimate IN(&ListOfCalculations)
		|INDEX BY
		|	Products,
		|	Characteristic,
		|	PriceKind
		|;
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT
		|	Costs.StandardCostEstimate AS StandardCostEstimate,
		|	VALUE(Catalog.PackagesAndUnitsOfMeasure.EmptyRef) AS Package,
		|	Prices.Period AS Period,
		|	Prices.Products AS Products,
		|	Prices.Characteristic AS Characteristic,
		|	Prices.PriceKind AS PriceKind,
		|	Prices.Currency AS Currency,
		|	Prices.Price AS Price
		|INTO ItemsPrices
		|FROM
		|	Costs AS Costs
		|		LEFT JOIN PreliminaryProductPricing AS Prices
		|		ON Costs.Products = Prices.Products
		|			AND Costs.Characteristic = Prices.Characteristic
		|			AND Costs.Period = Prices.Period
		|			AND Costs.PriceKind = Prices.PriceKind
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|DROP ProductsForPrices
		|;
		|DROP Costs
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|DROP PreliminaryProductPricing";
	
	Query.Execute();
	
EndProcedure

Procedure FillInCostOfLabor(StandardCostEstimate, TempTableManager)
	
	Query = New Query;
	Query.TempTablesManager = TempTableManager;
	
	ArrayOfRequestTexts = New Array();
	
	Query.SetParameter("UseLaborGradesOfEmployeeActivityRates",
		GetFunctionalOption("UseLaborGradesOfEmployeeActivityRates"));
	ArrayOfRequestTexts.Add(AccumulationRegisters.PlannedLaborCosts.QueryTextOfLaborCostsPricing(True));
	
	QueryText = "SELECT
		|	Rates.Organization AS Organization,
		|	PlannedLaborCosts.StandardCostEstimate AS StandardCostEstimate,
		|	PlannedLaborCosts.LotBOM AS LotBOM,
		|	PlannedLaborCosts.KeyLot AS KeyLot,
		|	PlannedLaborCosts.Department AS Department,
		|	PlannedLaborCosts.ProductCostElement AS ProductCostElement,
		|	PlannedLaborCosts.WorkKind AS WorkKind,
		|	PlannedLaborCosts.Period AS Period,
		|	PlannedLaborCosts.Count AS Count,
		|	PlannedLaborCosts.Count * ISNULL(Rates.Rate_, 0)
		|		* CASE
		|			WHEN ExchangeRatesRates.Currency = MaExchangeRates.Currency
		|				THEN 1
		|			ELSE CASE
		|					WHEN ExchangeRatesRates.CourseDenominator * MaExchangeRates.CourseNumerator = 0
		|						THEN 1
		|					ELSE ExchangeRatesRates.CourseNumerator * MaExchangeRates.CourseDenominator / (ExchangeRatesRates.CourseDenominator * MaExchangeRates.CourseNumerator)
		|		END
		|	END AS Cost,
		|	PlannedLaborCosts.CostPeriod AS CostPeriod,
		|	PlannedLaborCosts.Count * ISNULL(Rates.Rate_, 0) * CASE
		|		WHEN ExchangeRatesRates.Currency = ACExchangeRates.Currency
		|			THEN 1
		|		ELSE CASE
		|				WHEN ExchangeRatesRates.CourseDenominator * ACExchangeRates.CourseNumerator = 0
		|					THEN 1
		|				ELSE ExchangeRatesRates.CourseNumerator * ACExchangeRates.CourseDenominator / (ExchangeRatesRates.CourseDenominator * ACExchangeRates.CourseNumerator)
		|			END
		|	END AS LocalCost
		|INTO PlannedLaborCostsWithoutInsurancePremiums
		|FROM
		|	AccumulationRegister.PlannedLaborCosts AS PlannedLaborCosts
		|		LEFT JOIN Rates AS Rates
		|		ON (Rates.WorkKind = PlannedLaborCosts.WorkKind)
		|			AND (Rates.Period = PlannedLaborCosts.Period)
		|			AND Rates.Department = PlannedLaborCosts.Department
		|		LEFT JOIN ExchangeRates AS ExchangeRatesRates
		|		ON (ExchangeRatesRates.TypeOfCurrency = ""CurrencyOfActivityKindRates"")
		|		LEFT JOIN ExchangeRates AS MaExchangeRates
		|		ON (MaExchangeRates.TypeOfCurrency = ""CurrencyOfManAccounting"")
		|		LEFT JOIN ExchangeRates AS ACExchangeRates
		|		ON (ACExchangeRates.TypeOfCurrency = ""CurrencyOfComplianceAccounting"")
		|WHERE
		|	PlannedLaborCosts.StandardCostEstimate = &StandardCostEstimate
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT
		|	NestedQuery.CostYear AS CostYear,
		|	NestedQuery.Organization AS Organization
		|INTO OrganizationCostPeriods
		|FROM
		|	(SELECT
		|		BEGINOFPERIOD(PlannedLaborCosts.CostPeriod, YEAR) AS CostYear,
		|		PlannedLaborCosts.Organization AS Organization
		|	FROM
		|		PlannedLaborCostsWithoutInsurancePremiums AS PlannedLaborCosts
		|	
		|	GROUP BY
		|		BEGINOFPERIOD(PlannedLaborCosts.CostPeriod, YEAR),
		|		PlannedLaborCosts.Organization) AS NestedQuery
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT
		|	CalculationOfInsurancePremiums.StandardCostEstimate AS StandardCostEstimate,
		|	CalculationOfInsurancePremiums.LotBOM AS LotBOM,
		|	CalculationOfInsurancePremiums.KeyLot AS KeyLot,
		|	CalculationOfInsurancePremiums.Department AS Department,
		|	CalculationOfInsurancePremiums.ProductCostElement AS ProductCostElement,
		|	CalculationOfInsurancePremiums.WorkKind AS WorkKind,
		|	CalculationOfInsurancePremiums.Period AS Period,
		|	SUM(CalculationOfInsurancePremiums.Cost) AS Cost,
		|	CalculationOfInsurancePremiums.CostPeriod AS CostPeriod,
		|	SUM(CalculationOfInsurancePremiums.Count) AS Count,
		|	SUM(CalculationOfInsurancePremiums.LocalCost) AS LocalCost
		|INTO PlannedLaborCosts
		|FROM (
		|	
		|	SELECT
		|		PlannedLaborCostsWithoutInsurancePremiums.StandardCostEstimate,
		|		PlannedLaborCostsWithoutInsurancePremiums.LotBOM,
		|		PlannedLaborCostsWithoutInsurancePremiums.KeyLot AS KeyLot,
		|		PlannedLaborCostsWithoutInsurancePremiums.Department,
		|		PlannedLaborCostsWithoutInsurancePremiums.ProductCostElement,
		|		PlannedLaborCostsWithoutInsurancePremiums.WorkKind,
		|		PlannedLaborCostsWithoutInsurancePremiums.Period,
		|		PlannedLaborCostsWithoutInsurancePremiums.Cost,
		|		PlannedLaborCostsWithoutInsurancePremiums.CostPeriod,
		|		PlannedLaborCostsWithoutInsurancePremiums.Count,
		|		PlannedLaborCostsWithoutInsurancePremiums.LocalCost
		|	FROM
		|		PlannedLaborCostsWithoutInsurancePremiums AS PlannedLaborCostsWithoutInsurancePremiums) AS CalculationOfInsurancePremiums
		|
		|GROUP BY
		|	CalculationOfInsurancePremiums.Period,
		|	CalculationOfInsurancePremiums.Department,
		|	CalculationOfInsurancePremiums.StandardCostEstimate,
		|	CalculationOfInsurancePremiums.WorkKind,
		|	CalculationOfInsurancePremiums.ProductCostElement,
		|	CalculationOfInsurancePremiums.CostPeriod,
		|	CalculationOfInsurancePremiums.LotBOM,
		|	CalculationOfInsurancePremiums.KeyLot
		|
		|HAVING
		|	SUM(CalculationOfInsurancePremiums.Count) > 0
		|
		|INDEX BY
		|	StandardCostEstimate,
		|	LotBOM
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|DROP ActivityKinds
		|;
		|
		|
		|////////////////////////////////////////////////////////////////////////////////
		|DROP Rates
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|DROP PlannedLaborCostsWithoutInsurancePremiums
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|DROP OrganizationCostPeriods";
	
	ArrayOfRequestTexts.Add(QueryText);
	Query.Text = StrConcat(ArrayOfRequestTexts, Common.QueryBatchSeparator());
	
	Query.SetParameter("StandardCostEstimate", StandardCostEstimate);

	
	SetPrivilegedMode(True);
	Query.Execute();
	SetPrivilegedMode(False);
		
EndProcedure

Procedure FillInCostOfArticleByArticle(CalculationParameters, TempTableManager)
	
	Query = New Query;
	Query.TempTablesManager = TempTableManager;
	
	Query.SetParameter("PriceKind", CalculationParameters.PCDetails.PriceKind);
	Query.SetParameter("Organization", CalculationParameters.PCDetails.Organization);
	Query.SetParameter("StandardCostEstimate", CalculationParameters.StandardCostEstimate);
	Query.SetParameter("UsePriceManagementSystem25",
		PriceManagementSystemServerCall.UsePriceManagementSystem25());
	Query.SetParameter("DateOfTransitionToPricingVersion25",
		PriceManagementSystemServerCall.DateOfTransitionToPricingVersion25());
	
		QueryText =
		"SELECT
		|	MAX(T.Period),
		|	T.Lot,
		|	T.KeyLot AS KeyLot,
		|	T.ManufacturedProduct,
		|	T.Characteristic,
		|	SUM(T.QuantityOfSemiFinishedProduct) AS QuantityOfSemiFinishedProduct
		|INTO ProductionParties
		|FROM
		|(
		|	SELECT
		|		BEGINOFPERIOD(MultiplesOfLotsAndSemiFinishedProducts.Period, MONTH) AS Period,
		|		MultiplesOfLotsAndSemiFinishedProducts.LotProductBOM AS Lot,
		|		MultiplesOfLotsAndSemiFinishedProducts.KeyLot,
		|		MultiplesOfLotsAndSemiFinishedProducts.ManufacturedProduct AS ManufacturedProduct,
		|		MultiplesOfLotsAndSemiFinishedProducts.ItemVariant AS Characteristic,
		|		MultiplesOfLotsAndSemiFinishedProducts.QuantityOfSemiFinishedProduct AS QuantityOfSemiFinishedProduct
		|	FROM
		|		InformationRegister.MultiplesOfLotsAndSemiFinishedProducts AS MultiplesOfLotsAndSemiFinishedProducts
		|	WHERE
		|		MultiplesOfLotsAndSemiFinishedProducts.StandardCostEstimate = &StandardCostEstimate
		|		AND NOT MultiplesOfLotsAndSemiFinishedProducts.LotIsReleased
		|		AND MultiplesOfLotsAndSemiFinishedProducts.SemiFinishedProduct = VALUE(Catalog.Products.EmptyRef)
		|	
		|	UNION ALL
		|	
		|	SELECT
		|		BEGINOFPERIOD(MultiplesOfLotsAndSemiFinishedProducts.Period, MONTH),
		|		MultiplesOfLotsAndSemiFinishedProducts.LotSemiFinishedProductBOM,
		|		MultiplesOfLotsAndSemiFinishedProducts.KeyLot AS KeyLot,
		|		MultiplesOfLotsAndSemiFinishedProducts.SemiFinishedProduct,
		|		MultiplesOfLotsAndSemiFinishedProducts.ItemVariantsOfIntermediateProduct,
		|		MultiplesOfLotsAndSemiFinishedProducts.QuantityOfSemiFinishedProduct AS QuantityOfSemiFinishedProduct
		|	FROM
		|		InformationRegister.MultiplesOfLotsAndSemiFinishedProducts AS MultiplesOfLotsAndSemiFinishedProducts
		|	WHERE
		|		MultiplesOfLotsAndSemiFinishedProducts.StandardCostEstimate = &StandardCostEstimate
		|		AND NOT MultiplesOfLotsAndSemiFinishedProducts.LotIsReleased
		|		AND MultiplesOfLotsAndSemiFinishedProducts.SemiFinishedProduct <> VALUE(Catalog.Products.EmptyRef)
		|	) AS T
		|GROUP BY
		|	T.Lot,
		|	T.KeyLot,
		|	T.ManufacturedProduct,
		|	T.Characteristic
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT DISTINCT
		|	T.Lot AS Lot,
		|	T.KeyLot AS KeyLot,
		|	T.Period AS Period,
		|	T.QuantityOfSemiFinishedProduct AS QuantityOfSemiFinishedProduct
		|INTO BatchesOfProducts
		|FROM
		|	ProductionParties AS T
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT
		|	BEGINOFPERIOD(NestedQuery.Period, MONTH) AS Period,
		|	&Organization AS Organization,
		|	NestedQuery.Department AS Department,
		|	""ManufacturedProduct"" AS InfobaseType,
		|	NestedQuery.Products AS ManufacturedProduct,
		|	NestedQuery.Characteristic AS Characteristic,
		|	NestedQuery.Ref AS LotBOM,
		|	NestedQuery.KeyLot AS KeyLot,
		|	NestedQuery.Count AS Count
		|INTO ManufacturedProductPreliminary
		|FROM
		|	(SELECT
		|		BatchesOfProducts.Period AS Period,
		|		BatchesOfProducts.KeyLot AS KeyLot,
		|		Attributes.Ref AS Ref,
		|		TSManufacturedProducts.Department AS Department,
		|		TSManufacturedProducts.Products AS Products,
		|		TSManufacturedProducts.Characteristic AS Characteristic,
		|		TSManufacturedProducts.Count AS Count
		|	FROM
		|		BatchesOfProducts AS BatchesOfProducts
		|			INNER JOIN Document.ProductionStage2_2 AS Attributes
		|			ON BatchesOfProducts.Lot = Attributes.Ref
		|			INNER JOIN Document.ProductionStage2_2.ManufacturedProducts AS TSManufacturedProducts
		|			ON BatchesOfProducts.Lot = TSManufacturedProducts.Ref
		|	
		|	UNION ALL
		|	
		|	SELECT
		|		BatchesOfProducts.Period,
		|		ProductionParties.KeyLot AS KeyLot,
		|		OutputProductTable.Ref,
		|		OutputProductTable.Stage.Department,
		|		ProductionParties.ManufacturedProduct,
		|		ProductionParties.Characteristic,
		|		ProductionParties.QuantityOfSemiFinishedProduct
		|	FROM
		|		BatchesOfProducts AS BatchesOfProducts
		|			INNER JOIN ProductionParties AS ProductionParties
		|			ON BatchesOfProducts.Lot = ProductionParties.Lot
		|				AND BatchesOfProducts.KeyLot = ProductionParties.KeyLot
		|				AND BatchesOfProducts.Period = ProductionParties.Period
		|			INNER JOIN Catalog.BillsOfMaterials AS SpecificationDetails
		|			ON BatchesOfProducts.Lot = SpecificationDetails.Ref
		|				AND NOT SpecificationDetails.AssignmentOption = VALUE(Enum.BillOfMaterialsAssignmentOptions.ProductKind)
		|			INNER JOIN Catalog.BillsOfMaterials.ManufacturedProducts AS OutputProductTable
		|			ON BatchesOfProducts.Lot = OutputProductTable.Ref
		|				AND ProductionParties.ManufacturedProduct = OutputProductTable.Products
		|				AND (ProductionParties.Characteristic = OutputProductTable.Characteristic
		|					OR OutputProductTable.Characteristic = VALUE(Catalog.ItemsCharacteristics.EmptyRef))
		|	
		|	UNION ALL
		|	
		|	SELECT
		|		ProductionParties.Period,
		|		ProductionParties.KeyLot AS KeyLot,
		|		OutputProductTable.Ref,
		|		OutputProductTable.Stage.Department,
		|		ProductionParties.ManufacturedProduct,
		|		ProductionParties.Characteristic,
		|		ProductionParties.QuantityOfSemiFinishedProduct
		|	FROM
		|		ProductionParties AS ProductionParties
		|			INNER JOIN Catalog.BillsOfMaterials AS SpecificationDetails
		|			ON ProductionParties.Lot = SpecificationDetails.Ref
		|				AND SpecificationDetails.AssignmentOption = VALUE(Enum.BillOfMaterialsAssignmentOptions.ProductKind)
		|			INNER JOIN Catalog.BillsOfMaterials.ManufacturedProducts AS OutputProductTable
		|			ON ProductionParties.Lot = OutputProductTable.Ref
		|				AND ProductionParties.ManufacturedProduct = OutputProductTable.Products
		|				AND (ProductionParties.Characteristic = OutputProductTable.Characteristic
		|					OR OutputProductTable.Characteristic = VALUE(Catalog.ItemsCharacteristics.EmptyRef))
		|	) AS NestedQuery
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT
		|		ManufacturedProductPreliminary.ManufacturedProduct AS ManufacturedProduct,
		|		ManufacturedProductPreliminary.Characteristic AS Characteristic,
		|		ManufacturedProductPreliminary.Period AS Period,
		|		MAX(ItemsPrices25.Period) AS PricePeriod,
		|		&PriceKind AS PriceKind,
		|		ItemsPrices25.PricingVariant AS PricingVariant
		|INTO CurrentPricingPeriods25
		|FROM
		|	ManufacturedProductPreliminary AS ManufacturedProductPreliminary
		|		LEFT JOIN Catalog.ItemsCharacteristics AS CatItemsCharacteristics
		|		ON CatItemsCharacteristics.Ref = ManufacturedProductPreliminary.Characteristic
		|
		|		LEFT JOIN InformationRegister.ItemsPrices25 AS ItemsPrices25
		|		ON	ItemsPrices25.Period >= &DateOfTransitionToPricingVersion25
		|			AND ManufacturedProductPreliminary.Period >= ItemsPrices25.Period
		|			AND ManufacturedProductPreliminary.ManufacturedProduct = ItemsPrices25.Products
		|			AND ISNULL(CatItemsCharacteristics.ItemsCharacteristicForPricing, VALUE(Catalog.ItemsCharacteristicsForPricing.EmptyRef)) = ItemsPrices25.PricingVariant
		|			AND (ItemsPrices25.PriceKind = &PriceKind) 
		|WHERE
		|	&UsePriceManagementSystem25
		|	AND ItemsPrices25.Period IS NOT NULL
		|
		|GROUP BY
		|	ManufacturedProductPreliminary.ManufacturedProduct,
		|	ManufacturedProductPreliminary.Characteristic,
		|	ManufacturedProductPreliminary.Period,
		|	ItemsPrices25.PricingVariant
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT
		|	ManufacturedProductPreliminary.ManufacturedProduct AS ManufacturedProduct,
		|	ManufacturedProductPreliminary.Characteristic AS Characteristic,
		|	ManufacturedProductPreliminary.Period AS Period,
		|	MAX(ISNULL(ItemsPrices.Period, DATETIME(1, 1, 1))) AS PricePeriod,
		|	&PriceKind AS PriceKind
		|INTO CurrentPricingPeriods
		|FROM
		|	ManufacturedProductPreliminary AS ManufacturedProductPreliminary
		|		LEFT JOIN InformationRegister.ItemsPrices AS ItemsPrices
		|		ON ManufacturedProductPreliminary.Period >= ItemsPrices.Period
		|			AND ManufacturedProductPreliminary.ManufacturedProduct = ItemsPrices.Products
		|			AND ManufacturedProductPreliminary.Characteristic = ItemsPrices.Characteristic
		|			AND (ItemsPrices.PriceKind = &PriceKind)
		|
		|		LEFT JOIN CurrentPricingPeriods25 AS CurrentPricingPeriods25
		|		ON CurrentPricingPeriods25.ManufacturedProduct = ManufacturedProductPreliminary.ManufacturedProduct
		|			AND CurrentPricingPeriods25.Characteristic = ManufacturedProductPreliminary.Characteristic
		|			AND CurrentPricingPeriods25.Period = ManufacturedProductPreliminary.Period
		|
		|WHERE
		|	CurrentPricingPeriods25.PricePeriod IS NULL
		|		OR NOT &UsePriceManagementSystem25
		|		OR ISNULL(ItemsPrices.Period, DATETIME(1, 1, 1)) < &DateOfTransitionToPricingVersion25
		|
		|GROUP BY
		|	ManufacturedProductPreliminary.ManufacturedProduct,
		|	ManufacturedProductPreliminary.Characteristic,
		|	ManufacturedProductPreliminary.Period
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT
		|	CurrentPricingPeriods25.ManufacturedProduct AS Products,
		|	CurrentPricingPeriods25.Characteristic AS Characteristic,
		|	CurrentPricingPeriods25.Period AS Period,
		|	ItemsPrices.Package AS Package,
		|	ItemsPrices.Price AS Price,
		|	ItemsPrices.Currency AS Currency
		|FROM
		|	CurrentPricingPeriods25 AS CurrentPricingPeriods25
		|		LEFT JOIN InformationRegister.ItemsPrices25 AS ItemsPrices
		|		ON CurrentPricingPeriods25.PricePeriod = ItemsPrices.Period
		|			AND CurrentPricingPeriods25.ManufacturedProduct = ItemsPrices.Products
		|			AND CurrentPricingPeriods25.PricingVariant = ItemsPrices.PricingVariant
		|			AND CurrentPricingPeriods25.PriceKind = ItemsPrices.PriceKind
		|
		|UNION
		|
		|SELECT
		|	CurrentPricingPeriods25.ManufacturedProduct,
		|	CurrentPricingPeriods25.Characteristic,
		|	CurrentPricingPeriods25.Period,
		|	ItemsPrices.Package,
		|	ItemsPrices.Price,
		|	ItemsPrices.Currency
		|FROM
		|	CurrentPricingPeriods25 AS CurrentPricingPeriods25
		|		LEFT JOIN InformationRegister.ItemsPrices25 AS ItemsPrices
		|		ON CurrentPricingPeriods25.PricePeriod = ItemsPrices.Period
		|			AND CurrentPricingPeriods25.ManufacturedProduct = ItemsPrices.Products
		|			AND (VALUE(Catalog.ItemsCharacteristicsForPricing.EmptyRef) = ItemsPrices.PricingVariant)
		|			AND CurrentPricingPeriods25.PriceKind = ItemsPrices.PriceKind
		|
		|UNION
		|
		|SELECT
		|	CurrentPricingPeriods.ManufacturedProduct AS Products,
		|	CurrentPricingPeriods.Characteristic AS Characteristic,
		|	CurrentPricingPeriods.Period AS Period,
		|	ItemsPrices.Package AS Package,
		|	ItemsPrices.Price AS Price,
		|	ItemsPrices.Currency AS Currency
		|FROM
		|	CurrentPricingPeriods AS CurrentPricingPeriods
		|		LEFT JOIN InformationRegister.ItemsPrices AS ItemsPrices
		|		ON CurrentPricingPeriods.PricePeriod = ItemsPrices.Period
		|			AND CurrentPricingPeriods.ManufacturedProduct = ItemsPrices.Products
		|			AND CurrentPricingPeriods.Characteristic = ItemsPrices.Characteristic
		|			AND CurrentPricingPeriods.PriceKind = ItemsPrices.PriceKind
		|
		|UNION
		|
		|SELECT
		|	CurrentPricingPeriods.ManufacturedProduct,
		|	CurrentPricingPeriods.Characteristic,
		|	CurrentPricingPeriods.Period,
		|	ItemsPrices.Package,
		|	ItemsPrices.Price,
		|	ItemsPrices.Currency
		|FROM
		|	CurrentPricingPeriods AS CurrentPricingPeriods
		|		LEFT JOIN InformationRegister.ItemsPrices AS ItemsPrices
		|		ON CurrentPricingPeriods.PricePeriod = ItemsPrices.Period
		|			AND CurrentPricingPeriods.ManufacturedProduct = ItemsPrices.Products
		|			AND (VALUE(Catalog.ItemsCharacteristics.EmptyRef) = ItemsPrices.Characteristic)
		|			AND CurrentPricingPeriods.PriceKind = ItemsPrices.PriceKind
		|";
		
	Query.Text = QueryText;
		
	SetPrivilegedMode(True);
	UsedMaterials = Query.Execute().Unload();
	SetPrivilegedMode(False);
	
	PackingFactors = Catalogs.PackagesAndUnitsOfMeasure.PackingFactors(UsedMaterials);
	
	For Each Material In UsedMaterials Do
		
		PackingByMaterial = PackingFactors.Get(Material.Products);
		If PackingByMaterial = Undefined Then
			Continue;
		EndIf;
		
		PackagingFactor = PackingByMaterial.Get(Material.Package);
		If Not ValueIsFilled(PackagingFactor) Then
			Continue;
		EndIf;
		
		Material.Price = Material.Price / PackagingFactor;
		
	EndDo;
	
	Query.Text = 
		"SELECT
		|	T.Products AS Products,
		|	T.Characteristic AS Characteristic,
		|	T.Period AS Period,
		|	T.Package AS Package,
		|	T.Price AS Price,
		|	T.Currency AS Currency
		|INTO ItemsPricesPreliminary
		|FROM
		|	&UsedMaterials AS T
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT
		|	T.Products AS Products,
		|	T.Characteristic AS Characteristic,
		|	T.Period AS Period,
		|	T.Package AS Package,
		|	T.Price AS Price,
		|	T.Currency AS Currency
		|INTO ProductPrices_
		|FROM
		|	ItemsPricesPreliminary AS T
		|
		|INDEX BY
		|	Products,
		|	Characteristic,
		|	Period
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT
		|	BEGINOFPERIOD(PlannedMaterialCosts.CostPeriod, MONTH) AS Period,
		|	&Organization AS Organization,
		|	PlannedMaterialCosts.Department AS Department,
		|	PlannedMaterialCosts.Products AS Material,
		|	PlannedMaterialCosts.ProductCostElement AS ProductCostElement,
		|	FALSE AS ThisIsSemiFinishedProductOfItsOwn,
		|	FALSE AS ItIsSemiFinishedProcessor,
		|	CASE
		|		WHEN NOT &AnalyticalAccountingByProductsGroups 
		|			THEN VALUE(Catalog.AnalyticalInventoryGroups.EmptyRef)
		|		ELSE
		|			ISNULL(PartyDetails.ProductionLot.ProductsGroup, 
		|				ISNULL(ProductSpecifications.Products.AnalyticalGroup, 
		|					ISNULL(PlannedMaterialCosts.Products.AnalyticalGroup, VALUE(Catalog.AnalyticalInventoryGroups.EmptyRef))))
		|	END AS ProductsGroup,
		|	PlannedMaterialCosts.LotBOM AS LotBOM,
		|	PlannedMaterialCosts.KeyLot AS KeyLot,
		|	PlannedMaterialCosts.Count AS Count,
		|	PlannedMaterialCosts.CostExcludingVAT AS CostExcludingVAT,
		|	PlannedMaterialCosts.LocalCost AS LocalCost,
		|	PlannedMaterialCosts.Cost AS Cost,
		|	&VolumeM3 * PlannedMaterialCosts.Count AS VolumeM3,
		|	&Weight * PlannedMaterialCosts.Count AS Weight
		|INTO DataOnMaterialCosts_
		|FROM
		|	MaterialCostsIncludingSemiFinishedProducts AS PlannedMaterialCosts
		|		LEFT JOIN Catalog.Products AS SN
		|		ON PlannedMaterialCosts.Products = SN.Ref
		|		LEFT JOIN Catalog.BillsOfMaterials.ManufacturedProducts AS ProductSpecifications
		|		ON PlannedMaterialCosts.LotBOM = ProductSpecifications.Ref
		|			AND ProductSpecifications.LineNumber = 1
		|		LEFT JOIN Document.ProductionStage2_2 AS PartyDetails
		|		ON PlannedMaterialCosts.LotBOM = PartyDetails.Ref
		|WHERE
		|	NOT PlannedMaterialCosts.ThisIsASemiFinishedProduct
		|	AND PlannedMaterialCosts.Count > 0
		|
		|INDEX BY
		|	Period,
		|	Organization,
		|	Department,
		|	Material
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT
		|	BEGINOFPERIOD(PlannedLaborCosts.CostPeriod, MONTH) AS Period,
		|	&Organization AS Organization,
		|	PlannedLaborCosts.Department AS Department,
		|	PlannedLaborCosts.WorkKind AS WorkKind,
		|	PlannedLaborCosts.ProductCostElement AS ProductCostElement,
		|	FALSE AS ThisIsSemiFinishedProductOfItsOwn,
		|	FALSE AS ItIsSemiFinishedProcessor,
		|	CASE
		|		WHEN NOT &AnalyticalAccountingByProductsGroups 
		|			THEN VALUE(Catalog.AnalyticalInventoryGroups.EmptyRef)
		|		ELSE
		|			ISNULL(PartyDetails.ProductionLot.ProductsGroup, 
		|				ISNULL(ProductSpecifications.Products.AnalyticalGroup, 
		|					VALUE(Catalog.AnalyticalInventoryGroups.EmptyRef)))
		|	END AS ProductsGroup,
		|	PlannedLaborCosts.LotBOM,
		|	PlannedLaborCosts.KeyLot AS KeyLot,
		|	PlannedLaborCosts.Count,
		|	PlannedLaborCosts.Cost,
		|	PlannedLaborCosts.LocalCost,
		|	PlannedLaborCosts.Cost AS StandardCost
		|INTO DataOnLaborCosts
		|FROM
		|	PlannedLaborCosts AS PlannedLaborCosts
		|		LEFT JOIN Catalog.BillsOfMaterials.ManufacturedProducts AS ProductSpecifications
		|			ON PlannedLaborCosts.LotBOM = ProductSpecifications.Ref
		|			AND ProductSpecifications.LineNumber = 1
		|		LEFT JOIN Document.ProductionStage2_2 AS PartyDetails
		|			ON PlannedLaborCosts.LotBOM = PartyDetails.Ref
		|
		|INDEX BY
		|	Period,
		|	Organization,
		|	Department,
		|	WorkKind
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT
		|	BEGINOFPERIOD(Preliminary.Period, MONTH) AS Period,
		|	Preliminary.Organization AS Organization,
		|	Preliminary.Department AS Department,
		|	Preliminary.ManufacturedProduct AS ManufacturedProduct,
		|	CASE
		|		WHEN NOT &AnalyticalAccountingByProductsGroups 
		|			THEN VALUE(Catalog.AnalyticalInventoryGroups.EmptyRef)
		|		ELSE
		|			ISNULL(PartyDetails.ProductionLot.ProductsGroup, 
		|				ISNULL(ProductSpecifications.Products.AnalyticalGroup, 
		|					ISNULL(Preliminary.ManufacturedProduct.AnalyticalGroup, VALUE(Catalog.AnalyticalInventoryGroups.EmptyRef))))
		|	END AS ProductsGroup,
		|	Preliminary.LotBOM,
		|	Preliminary.KeyLot AS KeyLot,
		|	Preliminary.Count,
		|	Preliminary.Count * ISNULL(ProductPrices_.Price, 0) * CASE
		|				WHEN ProductPrices_.Currency = MaExchangeRates.Currency
		|					THEN 1
		|				ELSE CASE
		|						WHEN ISNULL(ExchangeRatesOfProductRange.CourseDenominator, 0) * MaExchangeRates.CourseNumerator = 0
		|							THEN 1
		|						ELSE ExchangeRatesOfProductRange.CourseNumerator * MaExchangeRates.CourseDenominator / (ExchangeRatesOfProductRange.CourseDenominator * MaExchangeRates.CourseNumerator)
		|					END
		|			END * CASE
		|				WHEN TypesOfPrices.Ref IS NULL
		|					THEN 1
		|				WHEN TypesOfPrices.PriceIncludesVAT
		|					THEN 1
		|				ELSE (Preliminary.ManufacturedProduct.VATRate.Rate1 + 100) / 100 END AS Cost,
		|	Preliminary.Count * ISNULL(ProductPrices_.Price, 0) 
		|		* CASE
		|			WHEN ProductPrices_.Currency = ACExchangeRates.Currency
		|				THEN 1
		|			WHEN ISNULL(ExchangeRatesOfProductRange.CourseDenominator, 0) * ACExchangeRates.CourseNumerator = 0
		|				THEN 1
		|			ELSE 
		|				ExchangeRatesOfProductRange.CourseNumerator * ACExchangeRates.CourseDenominator / (ExchangeRatesOfProductRange.CourseDenominator * ACExchangeRates.CourseNumerator)
		|		END / CASE
		|			WHEN Preliminary.Count < 0
		|				OR TypesOfPrices.Ref IS NULL
		|				OR NOT TypesOfPrices.PriceIncludesVAT
		|				THEN 1
		|			ELSE (Preliminary.ManufacturedProduct.VATRate.Rate1 + 100) / 100 END AS LocalCost,
		|	Preliminary.Count * ISNULL(ProductPrices_.Price, 0) 
		|		* CASE
		|			WHEN ProductPrices_.Currency = MaExchangeRates.Currency
		|				OR ISNULL(ExchangeRatesOfProductRange.CourseDenominator, 0) * MaExchangeRates.CourseNumerator = 0
		|				THEN 1
		|			ELSE ExchangeRatesOfProductRange.CourseNumerator * MaExchangeRates.CourseDenominator / (ExchangeRatesOfProductRange.CourseDenominator * MaExchangeRates.CourseNumerator)
		|		END 
		|			/ CASE
		|				WHEN Preliminary.Count < 0
		|					OR TypesOfPrices.Ref IS NULL
		|					OR NOT TypesOfPrices.PriceIncludesVAT
		|					THEN 1
		|				ELSE (Preliminary.ManufacturedProduct.VATRate.Rate1 + 100) / 100 END AS CostExcludingVAT,
		|	&VolumeM3 * Preliminary.Count AS VolumeM3,
		|	&Weight * Preliminary.Count AS Weight
		|INTO ProductData_6
		|FROM
		|	ManufacturedProductPreliminary AS Preliminary
		|		LEFT JOIN ProductPrices_ AS ProductPrices_
		|		ON Preliminary.Period = ProductPrices_.Period
		|			AND Preliminary.ManufacturedProduct = ProductPrices_.Products
		|			AND Preliminary.Characteristic = ProductPrices_.Characteristic
		|		LEFT JOIN Catalog.BillsOfMaterials.ManufacturedProducts AS ProductSpecifications
		|			ON Preliminary.LotBOM = ProductSpecifications.Ref
		|			AND ProductSpecifications.LineNumber = 1
		|		LEFT JOIN Document.ProductionStage2_2 AS PartyDetails
		|			ON Preliminary.LotBOM = PartyDetails.Ref
		|		LEFT JOIN Catalog.Products AS SN
		|		ON Preliminary.ManufacturedProduct = SN.Ref
		|		LEFT JOIN ExchangeRatesOfProductRange AS ExchangeRatesOfProductRange
		|		ON (ProductPrices_.Currency = ExchangeRatesOfProductRange.Currency)
		|		LEFT JOIN ExchangeRates AS MaExchangeRates
		|		ON (MaExchangeRates.TypeOfCurrency = ""CurrencyOfManAccounting"")
		|		LEFT JOIN ExchangeRates AS ACExchangeRates
		|		ON (ACExchangeRates.TypeOfCurrency = ""CurrencyOfComplianceAccounting"")
		|		LEFT JOIN Catalog.TypesOfPrices AS TypesOfPrices
		|		ON (TypesOfPrices.Ref = &PriceKind)
		|
		|INDEX BY
		|	Period,
		|	Organization,
		|	Department,
		|	ManufacturedProduct
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT DISTINCT
		|	T.Period AS Period
		|INTO PeriodsByMonth
		|FROM
		|	(SELECT
		|		AllocationBases.Period AS Period
		|	FROM
		|		DataOnMaterialCosts_ AS AllocationBases
		|
		|	UNION ALL
		|
		|	SELECT
		|		AllocationBases.Period AS Period
		|	FROM
		|		DataOnLaborCosts AS AllocationBases
		|
		|	UNION ALL
		|
		|	SELECT
		|		AllocationBases.Period AS Period
		|	FROM
		|		ProductData_6 AS AllocationBases) AS T
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT
		|	NestedQuery.Period AS Period,
		|	NestedQuery.Organization AS Organization,
		|	NestedQuery.Department AS Department,
		|	MAX(Standards.Ref) AS Ref
		|INTO CurrentDocumentsByPeriod
		|FROM
		|	(SELECT
		|		MAX(Standards.Date) AS Date,
		|		Standards.Organization AS Organization,
		|		Standards.Department AS Department,
		|		PeriodsByMonth.Period AS Period
		|	FROM
		|		PeriodsByMonth AS PeriodsByMonth
		|			LEFT JOIN Document.SetProductionExpenseStandards AS Standards
		|			ON PeriodsByMonth.Period >= Standards.ValidityStartDate
		|				AND (Standards.ValidityEndDate = DATETIME(1,1,1) OR PeriodsByMonth.Period <= Standards.ValidityEndDate)
		|				AND (NOT Standards.DeletionMark)
		|	
		|	GROUP BY
		|		PeriodsByMonth.Period,
		|		Standards.Organization,
		|		Standards.Department) AS NestedQuery
		|		INNER JOIN Document.SetProductionExpenseStandards AS Standards
		|		ON NestedQuery.Date = Standards.Date
		|			AND NestedQuery.Organization = Standards.Organization
		|			AND NestedQuery.Department = Standards.Department
		|			AND (NOT Standards.DeletionMark)
		|
		|GROUP BY
		|	NestedQuery.Period,
		|	NestedQuery.Organization,
		|	NestedQuery.Department
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|
		|SELECT
		|	CurrentDocumentsByPeriod.Period AS Period,
		|	CurrentDocumentsByPeriod.Organization AS Organization,
		|	CurrentDocumentsByPeriod.Department AS Department,
		|	FixedCostRates.ProductCostElement AS ProductCostElement,
		|	FixedCostRates.ExpenseItem AS ExpenseItem,
		|	CAST(FixedCostRates.NormativeStandard AS NUMBER(31, 2)) AS NormativeStandard,
		|	FixedCostRates.Repetition AS Repetition,
		|	ISNULL(SettingsByOrganizationAndDivision.SettingsLocal, 
		|		ISNULL(OrganizationSettings.SettingsLocal,
		|			ISNULL(SettingsByDepartment.SettingsLocal, 
		|				ArticleDetails_1.CostAllocationRuleLocal
		|	))) AS CostAllocationRuleLocal,
		|	ISNULL(SettingsByOrganizationAndDivision.SettingsManAccounting, 
		|		ISNULL(OrganizationSettings.SettingsManAccounting,
		|			ISNULL(SettingsByDepartment.SettingsManAccounting, 
		|				ArticleDetails_1.CostAllocationRuleManag
		|	))) AS CostAllocationRuleManag
		|INTO CurrentRatesOfFixedAndVariableExpensesByPeriod
		|FROM
		|	CurrentDocumentsByPeriod AS CurrentDocumentsByPeriod
		|		INNER JOIN Document.SetProductionExpenseStandards.FixedCostRates AS FixedCostRates
		|		ON CurrentDocumentsByPeriod.Ref = FixedCostRates.Ref
		|		INNER JOIN ChartOfCharacteristicTypes.ExpenseItems AS ArticleDetails_1
		|		ON FixedCostRates.ExpenseItem = ArticleDetails_1.Ref
		|		LEFT JOIN InformationRegister.SettingsOfItemizedExpensesAllocation AS OrganizationSettings
		|		ON FixedCostRates.ExpenseItem = OrganizationSettings.ExpenseItem
		|			AND CurrentDocumentsByPeriod.Organization = OrganizationSettings.Organization
		|			AND (CurrentDocumentsByPeriod.Department = VALUE(Catalog.BusinessStructure.EmptyRef))
		|		LEFT JOIN InformationRegister.SettingsOfItemizedExpensesAllocation AS SettingsByDepartment
		|		ON FixedCostRates.ExpenseItem = SettingsByDepartment.ExpenseItem
		|			AND CurrentDocumentsByPeriod.Department = SettingsByDepartment.Department
		|			AND (SettingsByDepartment.Organization = VALUE(Catalog.Companies.EmptyRef))
		|		LEFT JOIN InformationRegister.SettingsOfItemizedExpensesAllocation AS SettingsByOrganizationAndDivision
		|		ON FixedCostRates.ExpenseItem = SettingsByOrganizationAndDivision.ExpenseItem
		|			AND CurrentDocumentsByPeriod.Organization = SettingsByOrganizationAndDivision.Organization
		|			AND CurrentDocumentsByPeriod.Department = SettingsByOrganizationAndDivision.Department
		|
		|UNION ALL
		|
		|SELECT
		|	CurrentDocumentsByPeriod.Period,
		|	CurrentDocumentsByPeriod.Organization,
		|	CurrentDocumentsByPeriod.Department,
		|	VariableCostRates.ProductCostElement,
		|	VariableCostRates.ExpenseItem,
		|	CAST(VariableCostRates.NormativeStandard AS NUMBER(31, 2)),
		|	VariableCostRates.Repetition,
		|	ISNULL(SettingsByOrganizationAndDivision.SettingsLocal, 
		|		ISNULL(OrganizationSettings.SettingsLocal,
		|			ISNULL(SettingsByDepartment.SettingsLocal, 
		|				ArticleDetails_1.CostAllocationRuleLocal
		|	))) AS CostAllocationRuleLocal,
		|	ISNULL(SettingsByOrganizationAndDivision.SettingsManAccounting, 
		|		ISNULL(OrganizationSettings.SettingsManAccounting,
		|			ISNULL(SettingsByDepartment.SettingsManAccounting, 
		|				ArticleDetails_1.CostAllocationRuleManag
		|	))) AS CostAllocationRuleManag
		|FROM
		|	CurrentDocumentsByPeriod AS CurrentDocumentsByPeriod
		|		INNER JOIN Document.SetProductionExpenseStandards.VariableCostRates AS VariableCostRates
		|		ON CurrentDocumentsByPeriod.Ref = VariableCostRates.Ref
		|		INNER JOIN ChartOfCharacteristicTypes.ExpenseItems AS ArticleDetails_1
		|		ON VariableCostRates.ExpenseItem = ArticleDetails_1.Ref
		|		LEFT JOIN InformationRegister.SettingsOfItemizedExpensesAllocation AS OrganizationSettings
		|		ON VariableCostRates.ExpenseItem = OrganizationSettings.ExpenseItem
		|			AND CurrentDocumentsByPeriod.Organization = OrganizationSettings.Organization
		|			AND (CurrentDocumentsByPeriod.Department = VALUE(Catalog.BusinessStructure.EmptyRef))
		|		LEFT JOIN InformationRegister.SettingsOfItemizedExpensesAllocation AS SettingsByDepartment
		|		ON VariableCostRates.ExpenseItem = SettingsByDepartment.ExpenseItem
		|			AND CurrentDocumentsByPeriod.Department = SettingsByDepartment.Department
		|			AND (SettingsByDepartment.Organization = VALUE(Catalog.Companies.EmptyRef))
		|		LEFT JOIN InformationRegister.SettingsOfItemizedExpensesAllocation AS SettingsByOrganizationAndDivision
		|		ON VariableCostRates.ExpenseItem = SettingsByOrganizationAndDivision.ExpenseItem
		|			AND CurrentDocumentsByPeriod.Organization = SettingsByOrganizationAndDivision.Organization
		|			AND CurrentDocumentsByPeriod.Department = SettingsByOrganizationAndDivision.Department
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|
		|SELECT
		|	FALSE AS LocalAccnting,
		|	T.Period AS Period,
		|	T.Organization AS Organization,
		|	T.Department AS Department,
		|	T.ProductCostElement AS ProductCostElement,
		|	T.ExpenseItem AS ExpenseItem,
		|	T.NormativeStandard AS NormativeStandard,
		|	T.Repetition AS Repetition,
		|	T.CostAllocationRuleManag AS CostSharingRule,
		|	CostAllocationRules.BaseOfAllocationByLots AS BaseOfAllocationByLots
		|INTO CurrentStandardsForPeriods
		|FROM
		|	CurrentRatesOfFixedAndVariableExpensesByPeriod AS T
		|		INNER JOIN Catalog.CostAllocationRules AS CostAllocationRules
		|		ON T.CostAllocationRuleManag = CostAllocationRules.Ref
		|
		|UNION ALL
		|
		|SELECT
		|	FALSE AS LocalAccnting,
		|	T.Period AS Period,
		|	T.Organization AS Organization,
		|	T.Department AS Department,
		|	T.ProductCostElement AS ProductCostElement,
		|	T.ExpenseItem AS ExpenseItem,
		|	T.NormativeStandard AS NormativeStandard,
		|	T.Repetition AS Repetition,
		|	T.CostAllocationRuleManag AS CostSharingRule,
		|	AllocationOfOtherCosts.BaseOfAllocationByLots AS BaseOfAllocationByLots
		|FROM
		|	CurrentRatesOfFixedAndVariableExpensesByPeriod AS T
		|		INNER JOIN Document.AllocationOfOtherCosts AS AllocationOfOtherCosts
		|		ON T.CostAllocationRuleManag = AllocationOfOtherCosts.Ref
		|
		|UNION ALL
		|
		|SELECT
		|	TRUE AS LocalAccnting,
		|	T.Period AS Period,
		|	T.Organization AS Organization,
		|	T.Department AS Department,
		|	T.ProductCostElement AS ProductCostElement,
		|	T.ExpenseItem AS ExpenseItem,
		|	T.NormativeStandard AS NormativeStandard,
		|	T.Repetition AS Repetition,
		|	T.CostAllocationRuleLocal AS CostSharingRule,
		|	CostAllocationRules.BaseOfAllocationByLots AS BaseOfAllocationByLots
		|FROM
		|	CurrentRatesOfFixedAndVariableExpensesByPeriod AS T
		|		INNER JOIN Catalog.CostAllocationRules AS CostAllocationRules
		|		ON T.CostAllocationRuleLocal = CostAllocationRules.Ref
		|
		|UNION ALL
		|
		|SELECT
		|	TRUE AS LocalAccnting,
		|	T.Period AS Period,
		|	T.Organization AS Organization,
		|	T.Department AS Department,
		|	T.ProductCostElement AS ProductCostElement,
		|	T.ExpenseItem AS ExpenseItem,
		|	T.NormativeStandard AS NormativeStandard,
		|	T.Repetition AS Repetition,
		|	T.CostAllocationRuleLocal AS CostSharingRule,
		|	AllocationOfOtherCosts.BaseOfAllocationByLots AS BaseOfAllocationByLots
		|FROM
		|	CurrentRatesOfFixedAndVariableExpensesByPeriod AS T
		|		INNER JOIN Document.AllocationOfOtherCosts AS AllocationOfOtherCosts
		|		ON T.CostAllocationRuleLocal = AllocationOfOtherCosts.Ref
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|
		|SELECT DISTINCT
		|	RECORDAUTONUMBER() AS RecNo,
		|	T.LocalAccnting AS LocalAccnting,
		|	T.Period AS Period,
		|	T.Organization AS Organization,
		|	T.Department AS Department,
		|	T.ExpenseItem,
		|	T.ProductCostElement,
		|	T.CostSharingRule,
		|	T.BaseOfAllocationByLots
		|INTO SpendingOptions
		|FROM
		|	CurrentStandardsForPeriods AS T";
		
	Query.Text = StrReplace(Query.Text, "&VolumeM3", Catalogs.PackagesAndUnitsOfMeasure.QueryTextPackageVolume("SN.UnitOfMeasure", "SN"));
	Query.Text = StrReplace(Query.Text, "&Weight", Catalogs.PackagesAndUnitsOfMeasure.QueryTextPackageWeight("SN.UnitOfMeasure", "SN"));
	Query.SetParameter("AnalyticalAccountingByProductsGroups", GetFunctionalOption("AnalyticalAccountingByProductsGroups"));
	Query.SetParameter("UsedMaterials", UsedMaterials);
	
	Query.Execute();
	
	CalculationParameters.Insert("TempTablesManager", Query.TempTablesManager);
	CalculationParameters.Insert("AdditionalStageRequestParameters", New Structure);
	
	NameOfTemporaryObjectGroupTable = "InformationRegisterMultiplesOfLotsAndSemiFinishedProducts";
	GettingObjectText = 
		"SELECT
		|	Expenses.RecNo AS Ref,
		|	CASE
		|		WHEN RuleDetails.BaseOfAllocationByLots = VALUE(Enum.TypesOfCostAllocatingBase.AmountOfMaterialAndLaborCosts)
		|			THEN VALUE(Enum.TypesOfCostAllocatingBase.MaterialCostsAmount)
		|		ELSE
		|			RuleDetails.BaseOfAllocationByLots
		|	END AS AllocationBaseType,
		|	RuleDetails.SettingsOfBaseOfAllocationByLots AS SchemaSettings
		|FROM
		|	SpendingOptions AS Expenses
		|		INNER JOIN Catalog.CostAllocationRules AS RuleDetails
		|		ON Expenses.CostSharingRule = RuleDetails.Ref
		|			AND NOT RuleDetails.BaseOfAllocationByLots = VALUE(Enum.TypesOfCostAllocatingBase.EmptyRef)
		|
		|UNION ALL
		|
		|SELECT
		|	Expenses.RecNo,
		|	VALUE(Enum.TypesOfCostAllocatingBase.TotalPayrollExpenses) AS AllocationBaseType,
		|	RuleDetails.SettingsOfBaseOfAllocationByLots AS SchemaSettings
		|FROM
		|	SpendingOptions AS Expenses
		|		INNER JOIN Catalog.CostAllocationRules AS RuleDetails
		|		ON Expenses.CostSharingRule = RuleDetails.Ref
		|WHERE
		|	RuleDetails.BaseOfAllocationByLots = VALUE(Enum.TypesOfCostAllocatingBase.AmountOfMaterialAndLaborCosts)
		|
		|UNION ALL
		|
		|SELECT
		|	Expenses.RecNo AS Ref,
		|	CASE
		|		WHEN RuleDetails.BaseOfAllocationByLots = VALUE(Enum.TypesOfCostAllocatingBase.AmountOfMaterialAndLaborCosts)
		|			THEN VALUE(Enum.TypesOfCostAllocatingBase.MaterialCostsAmount)
		|		ELSE
		|			RuleDetails.BaseOfAllocationByLots
		|	END AS AllocationBaseType,
		|	RuleDetails.SettingsOfBaseOfAllocationByLots AS SchemaSettings
		|FROM
		|	SpendingOptions AS Expenses
		|		INNER JOIN Document.AllocationOfOtherCosts AS RuleDetails
		|		ON Expenses.CostSharingRule = RuleDetails.Ref
		|			AND NOT RuleDetails.BaseOfAllocationByLots = VALUE(Enum.TypesOfCostAllocatingBase.EmptyRef)
		|
		|UNION ALL
		|
		|SELECT
		|	Expenses.RecNo,
		|	VALUE(Enum.TypesOfCostAllocatingBase.TotalPayrollExpenses) AS AllocationBaseType,
		|	RuleDetails.SettingsOfBaseOfAllocationByLots AS SchemaSettings
		|FROM
		|	SpendingOptions AS Expenses
		|		INNER JOIN Document.AllocationOfOtherCosts AS RuleDetails
		|		ON Expenses.CostSharingRule = RuleDetails.Ref
		|WHERE
		|	RuleDetails.BaseOfAllocationByLots = VALUE(Enum.TypesOfCostAllocatingBase.AmountOfMaterialAndLaborCosts)";

	UnavailableSelectionFields = New Array;
	UnavailableSelectionFields.Add("LineOfBusiness");
	DescriptionOfGroups = CostCalculationItemizedCosts.GetDescriptionOfObjectGroupsBySelectionSettings(
		GettingObjectText, CalculationParameters, NameOfTemporaryObjectGroupTable, UnavailableSelectionFields);
	
	QueryTextDataDetails = 
		"SELECT
		|	FALSE AS LocalAccnting,
		|	0 AS RecNo,
		|	UNDEFINED AS LotBOM,
		|	&EmptyUIDString AS KeyLot,
		|	0 AS Cost,
		|	0 AS CostExcludingVAT,
		|	0 AS LocalCost
		|INTO DataDetails
		|WHERE
		|	FALSE";
	ReadyQueryTexts = New Array;
	ReadyQueryTexts.Add(CostCalculationItemizedCosts.TextForPlacingGroupOfObjectsInTemporaryTable(NameOfTemporaryObjectGroupTable));
	ReadyQueryTexts.Add(QueryTextDataDetails);
	CostCalculationItemizedCosts.AddTextsDescribingGroups(ReadyQueryTexts, DescriptionOfGroups,
		"InformationRegister.MultiplesOfLotsAndSemiFinishedProducts");
	
	TextsOfFormationOfFinalTable = New Array;
	TextDistributionBase = 
		"SELECT
		|	T.LocalAccnting AS LocalAccnting,
		|	T.RecNo,
		|	T.LotBOM,
		|	T.KeyLot,
		|	T.Cost,
		|	T.CostExcludingVAT,
		|	T.LocalCost
		|INTO AllocationBase
		|FROM
		|	DataDetails AS T";
	TextsOfFormationOfFinalTable.Add(TextDistributionBase);
	
	TextDistributionBase = StrReplace(TextDistributionBase, "INTO AllocationBase", "");
	For Each GroupDetails In DescriptionOfGroups Do
		TextsOfFormationOfFinalTable.Add(
			StrReplace(TextDistributionBase, 
				"DataDetails", StrTemplate("DataTable%1",
				Format(GroupDetails.NumberOfGroup, "NZ=0; NG=0"))));
	EndDo;
	
	ReadyQueryTexts.Add(StrConcat(TextsOfFormationOfFinalTable, TMCommonUse.QuerySeparatorInJoin()));
		
	TextPlannedOtherCosts = 
		"SELECT
		|	AllocationBase.LotBOM,
		|	AllocationBase.KeyLot AS KeyLot,
		|	&StandardCostEstimate AS StandardCostEstimate,
		|	CurrentStandardsForPeriods.Department,
		|	CurrentStandardsForPeriods.ProductCostElement,
		|	CurrentStandardsForPeriods.ExpenseItem,
		|	CurrentStandardsForPeriods.Period,
		|	SUM(CASE WHEN CurrentStandardsForPeriods.LocalAccnting
		|		THEN 0
		|		ELSE CAST(AllocationBase.Cost
		|				* CurrentStandardsForPeriods.NormativeStandard / CurrentStandardsForPeriods.Repetition AS NUMBER(31, 2))
		|	END) AS Cost,
		|	SUM(CASE WHEN CurrentStandardsForPeriods.LocalAccnting
		|		THEN 0
		|		ELSE
		|			CAST(AllocationBase.CostExcludingVAT
		|				* CurrentStandardsForPeriods.NormativeStandard / CurrentStandardsForPeriods.Repetition AS NUMBER(31, 2))
		|	END) AS CostExcludingVAT,
		|	SUM(CASE 
		|		WHEN NOT CurrentStandardsForPeriods.LocalAccnting OR MaExchangeRates.CourseDenominator = 0
		|			THEN 0
		|		ELSE
		|			CAST(AllocationBase.CostExcludingVAT
		|				* CurrentStandardsForPeriods.NormativeStandard / CurrentStandardsForPeriods.Repetition
		|				* MaExchangeRates.CourseNumerator / MaExchangeRates.CourseDenominator AS NUMBER(31, 2))
		|	END) AS LocalCost
		|INTO PlannedOtherCosts
		|FROM
		|	CurrentStandardsForPeriods AS CurrentStandardsForPeriods
		|		INNER JOIN SpendingOptions AS SpendingOptions
		|		ON CurrentStandardsForPeriods.Period = SpendingOptions.Period
		|			AND CurrentStandardsForPeriods.Organization = SpendingOptions.Organization
		|			AND CurrentStandardsForPeriods.Department = SpendingOptions.Department
		|			AND CurrentStandardsForPeriods.ExpenseItem = SpendingOptions.ExpenseItem
		|			AND CurrentStandardsForPeriods.ProductCostElement = SpendingOptions.ProductCostElement
		|			AND CurrentStandardsForPeriods.LocalAccnting = SpendingOptions.LocalAccnting
		|
		|		INNER JOIN AllocationBase AS AllocationBase
		|		ON SpendingOptions.RecNo = AllocationBase.RecNo
		|			AND SpendingOptions.LocalAccnting = AllocationBase.LocalAccnting
		|
		|		LEFT JOIN ExchangeRates AS MaExchangeRates
		|		ON (MaExchangeRates.TypeOfCurrency = ""CurrencyOfManAccounting"")
		|
		|		LEFT JOIN ExchangeRates AS LocalExchangeRates
		|		ON (LocalExchangeRates.TypeOfCurrency = ""CurrencyOfComplianceAccounting"")
		|
		|GROUP BY
		|	AllocationBase.KeyLot,
		|	AllocationBase.LotBOM,
		|	CurrentStandardsForPeriods.Department,
		|	CurrentStandardsForPeriods.ProductCostElement,
		|	CurrentStandardsForPeriods.ExpenseItem,
		|	CurrentStandardsForPeriods.Period
		|";
		
	ReadyQueryTexts.Add(TextPlannedOtherCosts);
	
	Query.Text = StrConcat(ReadyQueryTexts, Common.QueryBatchSeparator());
	
	For Each AddnlParameter_ In CalculationParameters.AdditionalStageRequestParameters Do
		Query.SetParameter(AddnlParameter_.Key, AddnlParameter_.Value);
	EndDo;
	Query.SetParameter("EmptyUIDString", CalculationParameters.EmptyUIDString);
	
	SetPrivilegedMode(True);
	Query.Execute();
	SetPrivilegedMode(False);
	
	CostCalculationAppliedAlgorithms.DestroyTemporaryTables(TempTableManager,
		"MultiplesOfLotsAndSemiFinishedProducts,MaterialCostsIncludingSemiFinishedProducts,AllocationBase,ProductData_6,DataOnLaborCosts,
		|PeriodsByMonth,CurrentDocumentsByPeriod,CurrentStandardsForPeriods,BatchesOfProducts, SpendingOptions,DataOnMaterialCosts_,
		|ManufacturedProductPreliminary, CurrentPricingPeriods, ItemsPricesPreliminary, ProductPrices_, " + NameOfTemporaryObjectGroupTable);
	
EndProcedure

Function DatabaseTextTemplate(DistributionBaseIndicator) Export
	
	DatabaseParameters = DistributionBaseParameters(DistributionBaseIndicator);
	
	Template = 
		"SELECT
		|	DD.LocalAccnting				AS LocalAccnting,
		|	DD.RecNo,
		|	SourceDatabase.LotBOM,
		|	SourceDatabase.KeyLot AS KeyLot,
		|	SUM(&ValueWithVAT)	AS Cost,
		|	SUM(&ValueWithoutVAT)	AS CostExcludingVAT,
		|	SUM(&LocalValue)	AS LocalCost
		|INTO DataTable
		|FROM
		|	SpendingOptions AS DD
		|
		|		INNER JOIN InformationRegisterMultiplesOfLotsAndSemiFinishedProducts AS Group
		|		ON DD.RecNo = Group.Object
		|			AND Group.NumberOfGroup = &NumberOfGroup
		|
		|		INNER JOIN NameOfDatabaseTable AS SourceDatabase
		|		ON DD.Period = SourceDatabase.Period
		|			AND DD.Organization = SourceDatabase.Organization
		|			AND DD.Department = SourceDatabase.Department
		|			AND &ConnectionCondition
		|
		|GROUP BY
		|	DD.LocalAccnting,
		|	DD.RecNo,
		|	SourceDatabase.LotBOM,
		|	SourceDatabase.KeyLot";

	Template = StrReplace(Template, "NameOfDatabaseTable", DatabaseParameters.NameOfDatabaseTable);
	Template = StrReplace(Template, "&ValueWithVAT", DatabaseParameters.ValueWithVAT);
	Template = StrReplace(Template,
		"&ValueWithoutVAT",
		?(DatabaseParameters.Property("ValueWithoutVAT"), DatabaseParameters.ValueWithoutVAT, DatabaseParameters.ValueWithVAT));
	Template = StrReplace(Template,
		"&LocalValue",
		?(DatabaseParameters.Property("LocalValue"), DatabaseParameters.LocalValue, DatabaseParameters.ValueWithVAT));
	
	Return Template;
	
EndFunction

Function DistributionBaseParameters(DistributionBaseIndicator)
	
	Parameters = New Structure;
	
	If DistributionBaseIndicator = "MaterialCosts" Then
		
		Parameters.Insert("NameOfDatabaseTable", "DataOnMaterialCosts_");
		Parameters.Insert("ValueWithVAT", "CASE DD.BaseOfAllocationByLots
											|	WHEN VALUE(Enum.TypesOfCostAllocatingBase.MaterialCostsAmount)
											|		THEN SourceDatabase.Cost
											|	WHEN VALUE(Enum.TypesOfCostAllocatingBase.AmountOfMaterialAndLaborCosts)
											|		THEN SourceDatabase.Cost
											|	WHEN VALUE(Enum.TypesOfCostAllocatingBase.WeightOfSpecifiedMaterials)
											|		THEN SourceDatabase.Weight
											|	WHEN VALUE(Enum.TypesOfCostAllocatingBase.QuantityOfSpecifiedMaterials)
											|		THEN SourceDatabase.Count
											|	WHEN VALUE(Enum.TypesOfCostAllocatingBase.VolumeOfSpecifiedMaterials)
											|		THEN SourceDatabase.VolumeM3
											|END");
		Parameters.Insert("ValueWithoutVAT", "CASE DD.BaseOfAllocationByLots
											|	WHEN VALUE(Enum.TypesOfCostAllocatingBase.MaterialCostsAmount)
											|		THEN SourceDatabase.CostExcludingVAT
											|	WHEN VALUE(Enum.TypesOfCostAllocatingBase.AmountOfMaterialAndLaborCosts)
											|		THEN SourceDatabase.CostExcludingVAT
											|	WHEN VALUE(Enum.TypesOfCostAllocatingBase.WeightOfSpecifiedMaterials)
											|		THEN SourceDatabase.Weight
											|	WHEN VALUE(Enum.TypesOfCostAllocatingBase.QuantityOfSpecifiedMaterials)
											|		THEN SourceDatabase.Count
											|	WHEN VALUE(Enum.TypesOfCostAllocatingBase.VolumeOfSpecifiedMaterials)
											|		THEN SourceDatabase.VolumeM3
											|END");
		Parameters.Insert("LocalValue", "CASE DD.BaseOfAllocationByLots
											|	WHEN VALUE(Enum.TypesOfCostAllocatingBase.MaterialCostsAmount)
											|		THEN SourceDatabase.LocalCost
											|	WHEN VALUE(Enum.TypesOfCostAllocatingBase.AmountOfMaterialAndLaborCosts)
											|		THEN SourceDatabase.LocalCost
											|	WHEN VALUE(Enum.TypesOfCostAllocatingBase.WeightOfSpecifiedMaterials)
											|		THEN SourceDatabase.Weight
											|	WHEN VALUE(Enum.TypesOfCostAllocatingBase.QuantityOfSpecifiedMaterials)
											|		THEN SourceDatabase.Count
											|	WHEN VALUE(Enum.TypesOfCostAllocatingBase.VolumeOfSpecifiedMaterials)
											|		THEN SourceDatabase.VolumeM3
											|END");
		
	ElsIf DistributionBaseIndicator = "LaborCosts" Then
		
		Parameters.Insert("NameOfDatabaseTable", "DataOnLaborCosts");
		Parameters.Insert("ValueWithVAT", "CASE DD.BaseOfAllocationByLots
											|	WHEN VALUE(Enum.TypesOfCostAllocatingBase.TotalPayrollExpenses)
											|		THEN SourceDatabase.Cost
											|	WHEN VALUE(Enum.TypesOfCostAllocatingBase.AmountOfMaterialAndLaborCosts)
											|		THEN SourceDatabase.Cost
											|	WHEN VALUE(Enum.TypesOfCostAllocatingBase.NumberOfWorksOfSpecifiedKinds)
											|		THEN SourceDatabase.Count
											|	WHEN VALUE(Enum.TypesOfCostAllocatingBase.StandardRemunerationLevel)
											|		THEN SourceDatabase.StandardCost
											|END");
		Parameters.Insert("LocalValue", "CASE DD.BaseOfAllocationByLots
											|	WHEN VALUE(Enum.TypesOfCostAllocatingBase.TotalPayrollExpenses)
											|		THEN SourceDatabase.LocalCost
											|	WHEN VALUE(Enum.TypesOfCostAllocatingBase.AmountOfMaterialAndLaborCosts)
											|		THEN SourceDatabase.LocalCost
											|	WHEN VALUE(Enum.TypesOfCostAllocatingBase.NumberOfWorksOfSpecifiedKinds)
											|		THEN SourceDatabase.Count
											|	WHEN VALUE(Enum.TypesOfCostAllocatingBase.StandardRemunerationLevel)
											|		THEN SourceDatabase.StandardCost
											|END");
		
	ElsIf DistributionBaseIndicator = "ManufacturedProduct" Then
		
		
		Parameters.Insert("NameOfDatabaseTable", "ProductData_6");
		Parameters.Insert("ValueWithVAT", "CASE DD.BaseOfAllocationByLots
											|	WHEN VALUE(Enum.TypesOfCostAllocatingBase.ProductsQuantity)
											|		THEN SourceDatabase.Count
											|	WHEN VALUE(Enum.TypesOfCostAllocatingBase.ProductsVolume)
											|		THEN SourceDatabase.VolumeM3
											|	WHEN VALUE(Enum.TypesOfCostAllocatingBase.ProductsWeight)
											|		THEN SourceDatabase.Weight
											|	WHEN VALUE(Enum.TypesOfCostAllocatingBase.TargetProductCost)
											|		THEN SourceDatabase.Cost
											|	WHEN VALUE(Enum.TypesOfCostAllocatingBase.ProductsQuantityConsideringFutureReleases)
											|		THEN SourceDatabase.Count
											|	WHEN VALUE(Enum.TypesOfCostAllocatingBase.ProductsVolumeConsideringFutureReleases)
											|		THEN SourceDatabase.VolumeM3
											|	WHEN VALUE(Enum.TypesOfCostAllocatingBase.ProductsWeightConsideringFutureReleases)
											|		THEN SourceDatabase.Weight
											|	WHEN VALUE(Enum.TypesOfCostAllocatingBase.TargetProductCostConsideringFutureReleases)
											|		THEN SourceDatabase.Cost
											|END");

	EndIf;
	
	Return Parameters;
	
EndFunction


Procedure CalculatePreliminaryCost_(CalculationParameters, TempTableManager)
	
	DeleteOtherCostTable = False;
	
	If TempTableManager.Tables.Find("PlannedOtherCosts") = Undefined Then
		
		Query = New Query;
		Query.TempTablesManager = TempTableManager;
		
		Query.Text = 
			"SELECT TOP 0
			|	*
			|INTO PlannedOtherCosts
			|FROM
			|	AccumulationRegister.PlannedOtherCosts";
		
		SetPrivilegedMode(True);
		Query.Execute();
		SetPrivilegedMode(False);
		
		DeleteOtherCostTable = True;
		
	EndIf;
	
	CalculateMaterialPrices(CalculationParameters, TempTableManager);
	
	Query = New Query;
	Query.TempTablesManager = TempTableManager;
	
	Query.Text =
		"SELECT
		|	MaterialCosts.StandardCostEstimate AS StandardCostEstimate,
		|	MaterialCosts.LotBOM AS LotBOM,
		|	MaterialCosts.KeyLot AS KeyLot,
		|	MaterialCosts.Products AS Products,
		|	MaterialCosts.Characteristic AS Characteristic,
		|	MaterialCosts.Department AS Department,
		|	MaterialCosts.Period AS Period,
		|	MaterialCosts.ProductCostElement AS ProductCostElement,
		|	MaterialCosts.Count AS Count,
		|	MaterialCosts.ThisIsASemiFinishedProduct AS ThisIsASemiFinishedProduct,
		|	CASE
		|		WHEN MaterialCosts.ThisIsASemiFinishedProduct
		|			THEN MaterialCosts.Count * ISNULL(MaterialPrices.PriceCost, 0)
		|		ELSE MaterialCosts.Cost
		|	END AS Cost,
		|	CASE
		|		WHEN MaterialCosts.ThisIsASemiFinishedProduct
		|			THEN MaterialCosts.Count * ISNULL(MaterialPrices.PriceValueWithoutVAT, 0)
		|		ELSE MaterialCosts.CostExcludingVAT
		|	END AS CostExcludingVAT,
		|	CASE
		|		WHEN MaterialCosts.ThisIsASemiFinishedProduct
		|			THEN MaterialCosts.Count * ISNULL(MaterialPrices.PriceLocalCost, 0)
		|		ELSE MaterialCosts.LocalCost
		|	END AS LocalCost,
		|	CASE
		|		WHEN MaterialCosts.ThisIsASemiFinishedProduct
		|			THEN MaterialCosts.Count * ISNULL(MaterialPrices.PriceLaborCosts, 0)
		|		ELSE 0
		|	END AS LaborCosts,
		|	CASE
		|		WHEN MaterialCosts.ThisIsASemiFinishedProduct
		|			THEN MaterialCosts.Count * ISNULL(MaterialPrices.PriceLaborCostsLocal, 0)
		|		ELSE 0
		|	END AS LaborCostsLocal,
		|	CASE
		|		WHEN MaterialCosts.ThisIsASemiFinishedProduct
		|			THEN MaterialCosts.Count * ISNULL(MaterialPrices.PriceArticleByArticleConstants, 0)
		|		ELSE 0
		|	END AS ItemizedFixed,
		|	CASE
		|		WHEN MaterialCosts.ThisIsASemiFinishedProduct
		|			THEN MaterialCosts.Count * ISNULL(MaterialPrices.PriceArticleByArticlePermanentWithoutVAT, 0)
		|		ELSE 0
		|	END AS ItemizedFixedCostsExcludingVAT,
		|	CASE
		|		WHEN MaterialCosts.ThisIsASemiFinishedProduct
		|			THEN MaterialCosts.Count * ISNULL(MaterialPrices.PriceArticleByArticlePermanentLocal, 0)
		|		ELSE 0
		|	END AS ItemizedFixedCostsCompl,
		|	CASE
		|		WHEN MaterialCosts.ThisIsASemiFinishedProduct
		|			THEN MaterialCosts.Count * ISNULL(MaterialPrices.PriceArticleByArticleVariables, 0)
		|		ELSE 0
		|	END AS ItemizedVariable,
		|	CASE
		|		WHEN MaterialCosts.ThisIsASemiFinishedProduct
		|			THEN MaterialCosts.Count * ISNULL(MaterialPrices.PriceArticleByArticleVariablesWithoutVAT, 0)
		|		ELSE 0
		|	END AS ItemizedVariableCostsExcludingVAT,
		|	CASE
		|		WHEN MaterialCosts.ThisIsASemiFinishedProduct
		|			THEN MaterialCosts.Count * ISNULL(MaterialPrices.PriceArticleByArticleVariablesLocal, 0)
		|		ELSE 0
		|	END AS ItemizedVariableCostsCompl,
		|	CASE
		|		WHEN MaterialCosts.ThisIsASemiFinishedProduct
		|			THEN MaterialCosts.Count * ISNULL(MaterialPrices.PriceCostOffBalanceSheet, 0)
		|		ELSE MaterialCosts.OffBalanceCost
		|	END AS OffBalanceCost,
		|	CASE
		|		WHEN MaterialCosts.ThisIsASemiFinishedProduct
		|			THEN MaterialCosts.Count * ISNULL(MaterialPrices.PriceCostOffBalanceLocal, 0)
		|		ELSE MaterialCosts.OffBalanceCostLocal
		|	END AS OffBalanceCostLocal,
		|	MaterialCosts.CostPeriod AS CostPeriod
		|INTO MaterialCostsIncludingSemiFinishedProducts
		|FROM
		|	MaterialCosts AS MaterialCosts
		|		LEFT JOIN MaterialPrices AS MaterialPrices
		|		ON MaterialCosts.StandardCostEstimate = MaterialPrices.StandardCostEstimate
		|			AND MaterialCosts.Products = MaterialPrices.Products
		|			AND MaterialCosts.Characteristic = MaterialPrices.Characteristic
		|			AND (MaterialCosts.ThisIsASemiFinishedProduct)
		|
		|INDEX BY
		|	LotBOM,
		|	StandardCostEstimate
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT DISTINCT
		|	MultiplesOfLotsAndSemiFinishedProducts.Period AS Period,
		|	MultiplesOfLotsAndSemiFinishedProducts.ManufacturedProduct AS ManufacturedProduct,
		|	MultiplesOfLotsAndSemiFinishedProducts.LotProductBOM AS LotProductBOM,
		|	MultiplesOfLotsAndSemiFinishedProducts.KeyLot AS KeyLot,
		|	MultiplesOfLotsAndSemiFinishedProducts.StandardCostEstimate AS StandardCostEstimate,
		|	MultiplesOfLotsAndSemiFinishedProducts.ItemVariant AS ItemVariant,
		|	MultiplesOfLotsAndSemiFinishedProducts.Purpose AS Purpose,
		|	MultiplesOfLotsAndSemiFinishedProducts.LotSemiFinishedProductBOM AS LotSemiFinishedProductBOM,
		|	MultiplesOfLotsAndSemiFinishedProducts.SemiFinishedProduct AS SemiFinishedProduct,
		|	MultiplesOfLotsAndSemiFinishedProducts.ItemVariantsOfIntermediateProduct AS ItemVariantsOfIntermediateProduct,
		|	MultiplesOfLotsAndSemiFinishedProducts.Order AS Order,
		|	MultiplesOfLotsAndSemiFinishedProducts.Numerator AS Numerator,
		|	MultiplesOfLotsAndSemiFinishedProducts.Denominator AS Denominator,
		|	MultiplesOfLotsAndSemiFinishedProducts.QuantityOfSemiFinishedProduct AS QuantityOfSemiFinishedProduct,
		|	MultiplesOfLotsAndSemiFinishedProducts.CalculationIsCompleted AS CalculationIsCompleted,
		|	MultiplesOfLotsAndSemiFinishedProducts.LotIsReleased AS LotIsReleased
		|INTO TTManufacturedProduct
		|FROM
		|	InformationRegister.MultiplesOfLotsAndSemiFinishedProducts AS MultiplesOfLotsAndSemiFinishedProducts
		|WHERE
		|	MultiplesOfLotsAndSemiFinishedProducts.StandardCostEstimate = &StandardCostEstimate
		|	AND MultiplesOfLotsAndSemiFinishedProducts.SemiFinishedProduct = VALUE(Catalog.Products.EmptyRef)
		// The expenses for the issued Lot references are taken into account when forming the report on the planned cost of products
		|	AND NOT MultiplesOfLotsAndSemiFinishedProducts.LotIsReleased
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT
		|	MultiplesOfLotsAndSemiFinishedProducts.Period AS Period,
		|	MultiplesOfLotsAndSemiFinishedProducts.StandardCostEstimate AS StandardCostEstimate,
		|	MultiplesOfLotsAndSemiFinishedProducts.LotProductBOM AS LotProductBOM,
		|	MultiplesOfLotsAndSemiFinishedProducts.ManufacturedProduct AS ManufacturedProduct,
		|	MultiplesOfLotsAndSemiFinishedProducts.ItemVariant AS ItemVariant,
		|	MultiplesOfLotsAndSemiFinishedProducts.Purpose AS Purpose,
		|	MultiplesOfLotsAndSemiFinishedProducts.LotSemiFinishedProductBOM AS LotSemiFinishedProductBOM,
		|	MultiplesOfLotsAndSemiFinishedProducts.KeyLot AS KeyLot,
		|	MultiplesOfLotsAndSemiFinishedProducts.SemiFinishedProduct AS SemiFinishedProduct,
		|	MultiplesOfLotsAndSemiFinishedProducts.ItemVariantsOfIntermediateProduct AS ItemVariantsOfIntermediateProduct,
		|	MultiplesOfLotsAndSemiFinishedProducts.Order AS Order,
		|	MultiplesOfLotsAndSemiFinishedProducts.QuantityOfSemiFinishedProduct AS QuantityOfSemiFinishedProduct,
		|	MultiplesOfLotsAndSemiFinishedProducts.CalculationIsCompleted AS CalculationIsCompleted,
		|	MultiplesOfLotsAndSemiFinishedProducts.LotIsReleased AS LotIsReleased,
		|	MaterialCostsIncludingSemiFinishedProducts.Cost * (MultiplesOfLotsAndSemiFinishedProducts.Numerator / MultiplesOfLotsAndSemiFinishedProducts.Denominator) AS Material_,
		|	MaterialCostsIncludingSemiFinishedProducts.CostExcludingVAT * (MultiplesOfLotsAndSemiFinishedProducts.Numerator / MultiplesOfLotsAndSemiFinishedProducts.Denominator) AS TangibleExcludingVAT,
		|	MaterialCostsIncludingSemiFinishedProducts.LocalCost * (MultiplesOfLotsAndSemiFinishedProducts.Numerator / MultiplesOfLotsAndSemiFinishedProducts.Denominator) AS TangibleCompl,
		|	MaterialCostsIncludingSemiFinishedProducts.LaborCosts * (MultiplesOfLotsAndSemiFinishedProducts.Numerator / MultiplesOfLotsAndSemiFinishedProducts.Denominator) AS LaborCosts,
		|	MaterialCostsIncludingSemiFinishedProducts.LaborCostsLocal * (MultiplesOfLotsAndSemiFinishedProducts.Numerator / MultiplesOfLotsAndSemiFinishedProducts.Denominator) AS LaborCostsLocal,
		|	MaterialCostsIncludingSemiFinishedProducts.ItemizedFixed * (MultiplesOfLotsAndSemiFinishedProducts.Numerator / MultiplesOfLotsAndSemiFinishedProducts.Denominator) AS ItemizedFixed,
		|	MaterialCostsIncludingSemiFinishedProducts.ItemizedFixedCostsExcludingVAT * (MultiplesOfLotsAndSemiFinishedProducts.Numerator / MultiplesOfLotsAndSemiFinishedProducts.Denominator) AS ItemizedFixedCostsExcludingVAT,
		|	MaterialCostsIncludingSemiFinishedProducts.ItemizedFixedCostsCompl * (MultiplesOfLotsAndSemiFinishedProducts.Numerator / MultiplesOfLotsAndSemiFinishedProducts.Denominator) AS ItemizedFixedCostsCompl,
		|	MaterialCostsIncludingSemiFinishedProducts.ItemizedVariable * (MultiplesOfLotsAndSemiFinishedProducts.Numerator / MultiplesOfLotsAndSemiFinishedProducts.Denominator) AS ItemizedVariable,
		|	MaterialCostsIncludingSemiFinishedProducts.ItemizedVariableCostsExcludingVAT * (MultiplesOfLotsAndSemiFinishedProducts.Numerator / MultiplesOfLotsAndSemiFinishedProducts.Denominator) AS ItemizedVariableCostsExcludingVAT,
		|	MaterialCostsIncludingSemiFinishedProducts.ItemizedVariableCostsCompl * (MultiplesOfLotsAndSemiFinishedProducts.Numerator / MultiplesOfLotsAndSemiFinishedProducts.Denominator) AS ItemizedVariableCostsCompl,
		|	MaterialCostsIncludingSemiFinishedProducts.OffBalanceCost * (MultiplesOfLotsAndSemiFinishedProducts.Numerator / MultiplesOfLotsAndSemiFinishedProducts.Denominator) AS MaterialOffBalance,
		|	MaterialCostsIncludingSemiFinishedProducts.OffBalanceCostLocal * (MultiplesOfLotsAndSemiFinishedProducts.Numerator / MultiplesOfLotsAndSemiFinishedProducts.Denominator) AS MaterialOffBalanceLocal,
		|	MultiplesOfLotsAndSemiFinishedProducts.Numerator AS Numerator,
		|	MultiplesOfLotsAndSemiFinishedProducts.Denominator AS Denominator
		|INTO Costs
		|FROM
		|	MaterialCostsIncludingSemiFinishedProducts AS MaterialCostsIncludingSemiFinishedProducts
		|		INNER JOIN InformationRegister.MultiplesOfLotsAndSemiFinishedProducts AS MultiplesOfLotsAndSemiFinishedProducts
		|		ON MultiplesOfLotsAndSemiFinishedProducts.StandardCostEstimate = MaterialCostsIncludingSemiFinishedProducts.StandardCostEstimate
		|			AND MultiplesOfLotsAndSemiFinishedProducts.LotSemiFinishedProductBOM = MaterialCostsIncludingSemiFinishedProducts.LotBOM
		|			AND MultiplesOfLotsAndSemiFinishedProducts.KeyLot = MaterialCostsIncludingSemiFinishedProducts.KeyLot
		|WHERE
		|	MultiplesOfLotsAndSemiFinishedProducts.StandardCostEstimate = &StandardCostEstimate
		|	AND NOT MultiplesOfLotsAndSemiFinishedProducts.SemiFinishedProduct = VALUE(Catalog.Products.EmptyRef)
		// The expenses for the issued Lot references are taken into account when forming the report on the planned cost of products
		|	AND NOT MultiplesOfLotsAndSemiFinishedProducts.LotIsReleased
		|
		|UNION ALL
		|
		|SELECT
		|	MultiplesOfLotsAndSemiFinishedProducts.Period,
		|	MultiplesOfLotsAndSemiFinishedProducts.StandardCostEstimate,
		|	MultiplesOfLotsAndSemiFinishedProducts.LotProductBOM,
		|	MultiplesOfLotsAndSemiFinishedProducts.ManufacturedProduct,
		|	MultiplesOfLotsAndSemiFinishedProducts.ItemVariant,
		|	MultiplesOfLotsAndSemiFinishedProducts.Purpose,
		|	MultiplesOfLotsAndSemiFinishedProducts.LotSemiFinishedProductBOM,
		|	MultiplesOfLotsAndSemiFinishedProducts.KeyLot AS KeyLot,
		|	MultiplesOfLotsAndSemiFinishedProducts.SemiFinishedProduct,
		|	MultiplesOfLotsAndSemiFinishedProducts.ItemVariantsOfIntermediateProduct,
		|	MultiplesOfLotsAndSemiFinishedProducts.Order,
		|	MultiplesOfLotsAndSemiFinishedProducts.QuantityOfSemiFinishedProduct,
		|	MultiplesOfLotsAndSemiFinishedProducts.CalculationIsCompleted,
		|	MultiplesOfLotsAndSemiFinishedProducts.LotIsReleased AS LotIsReleased,
		|	0,
		|	0,
		|	0,
		|	PlannedLaborCosts.Cost * (MultiplesOfLotsAndSemiFinishedProducts.Numerator / MultiplesOfLotsAndSemiFinishedProducts.Denominator),
		|	PlannedLaborCosts.LocalCost * (MultiplesOfLotsAndSemiFinishedProducts.Numerator / MultiplesOfLotsAndSemiFinishedProducts.Denominator),
		|	0,
		|	0,
		|	0,
		|	0,
		|	0,
		|	0,
		|	0,
		|	0,
		|	MultiplesOfLotsAndSemiFinishedProducts.Numerator,
		|	MultiplesOfLotsAndSemiFinishedProducts.Denominator
		|FROM
		|	PlannedLaborCosts AS PlannedLaborCosts
		|		INNER JOIN InformationRegister.MultiplesOfLotsAndSemiFinishedProducts AS MultiplesOfLotsAndSemiFinishedProducts
		|		ON MultiplesOfLotsAndSemiFinishedProducts.StandardCostEstimate = PlannedLaborCosts.StandardCostEstimate
		|			AND MultiplesOfLotsAndSemiFinishedProducts.LotSemiFinishedProductBOM = PlannedLaborCosts.LotBOM
		|			AND MultiplesOfLotsAndSemiFinishedProducts.KeyLot = PlannedLaborCosts.KeyLot
		|WHERE
		|	MultiplesOfLotsAndSemiFinishedProducts.StandardCostEstimate = &StandardCostEstimate
		|	AND NOT MultiplesOfLotsAndSemiFinishedProducts.SemiFinishedProduct = VALUE(Catalog.Products.EmptyRef)
		// The expenses for the issued Lot references are taken into account when forming the report on the planned cost of products
		|	AND NOT MultiplesOfLotsAndSemiFinishedProducts.LotIsReleased
		|
		|UNION ALL
		|
		|SELECT
		|	MultiplesOfLotsAndSemiFinishedProducts.Period,
		|	MultiplesOfLotsAndSemiFinishedProducts.StandardCostEstimate,
		|	MultiplesOfLotsAndSemiFinishedProducts.LotProductBOM,
		|	MultiplesOfLotsAndSemiFinishedProducts.ManufacturedProduct,
		|	MultiplesOfLotsAndSemiFinishedProducts.ItemVariant,
		|	MultiplesOfLotsAndSemiFinishedProducts.Purpose,
		|	MultiplesOfLotsAndSemiFinishedProducts.LotSemiFinishedProductBOM,
		|	MultiplesOfLotsAndSemiFinishedProducts.KeyLot AS KeyLot,
		|	MultiplesOfLotsAndSemiFinishedProducts.SemiFinishedProduct,
		|	MultiplesOfLotsAndSemiFinishedProducts.ItemVariantsOfIntermediateProduct,
		|	MultiplesOfLotsAndSemiFinishedProducts.Order,
		|	MultiplesOfLotsAndSemiFinishedProducts.QuantityOfSemiFinishedProduct,
		|	MultiplesOfLotsAndSemiFinishedProducts.CalculationIsCompleted,
		|	MultiplesOfLotsAndSemiFinishedProducts.LotIsReleased AS LotIsReleased,
		|	0,
		|	0,
		|	0,
		|	0,
		|	0,
		|	CASE
		|		WHEN PlannedOtherCosts.ExpenseItem.ProductionCostType = VALUE(Enum.ProductionCostType.Variables1)
		|			THEN 0
		|		ELSE PlannedOtherCosts.Cost * (MultiplesOfLotsAndSemiFinishedProducts.Numerator / MultiplesOfLotsAndSemiFinishedProducts.Denominator)
		|	END,
		|	CASE
		|		WHEN PlannedOtherCosts.ExpenseItem.ProductionCostType = VALUE(Enum.ProductionCostType.Variables1)
		|			THEN 0
		|		ELSE PlannedOtherCosts.CostExcludingVAT * (MultiplesOfLotsAndSemiFinishedProducts.Numerator / MultiplesOfLotsAndSemiFinishedProducts.Denominator)
		|	END,
		|	CASE
		|		WHEN PlannedOtherCosts.ExpenseItem.ProductionCostType = VALUE(Enum.ProductionCostType.Variables1)
		|			THEN 0
		|		ELSE PlannedOtherCosts.LocalCost * (MultiplesOfLotsAndSemiFinishedProducts.Numerator / MultiplesOfLotsAndSemiFinishedProducts.Denominator)
		|	END,
		|	CASE
		|		WHEN PlannedOtherCosts.ExpenseItem.ProductionCostType = VALUE(Enum.ProductionCostType.Variables1)
		|			THEN PlannedOtherCosts.Cost * (MultiplesOfLotsAndSemiFinishedProducts.Numerator / MultiplesOfLotsAndSemiFinishedProducts.Denominator)
		|		ELSE 0
		|	END,
		|	CASE
		|		WHEN PlannedOtherCosts.ExpenseItem.ProductionCostType = VALUE(Enum.ProductionCostType.Variables1)
		|			THEN PlannedOtherCosts.CostExcludingVAT * (MultiplesOfLotsAndSemiFinishedProducts.Numerator / MultiplesOfLotsAndSemiFinishedProducts.Denominator)
		|		ELSE 0
		|	END,
		|	CASE
		|		WHEN PlannedOtherCosts.ExpenseItem.ProductionCostType = VALUE(Enum.ProductionCostType.Variables1)
		|			THEN PlannedOtherCosts.LocalCost * (MultiplesOfLotsAndSemiFinishedProducts.Numerator / MultiplesOfLotsAndSemiFinishedProducts.Denominator)
		|		ELSE 0
		|	END,
		|	0,
		|	0,
		|	MultiplesOfLotsAndSemiFinishedProducts.Numerator,
		|	MultiplesOfLotsAndSemiFinishedProducts.Denominator
		|FROM
		|	PlannedOtherCosts AS PlannedOtherCosts
		|		INNER JOIN InformationRegister.MultiplesOfLotsAndSemiFinishedProducts AS MultiplesOfLotsAndSemiFinishedProducts
		|		ON MultiplesOfLotsAndSemiFinishedProducts.StandardCostEstimate = PlannedOtherCosts.StandardCostEstimate
		|			AND MultiplesOfLotsAndSemiFinishedProducts.LotSemiFinishedProductBOM = PlannedOtherCosts.LotBOM
		|			AND MultiplesOfLotsAndSemiFinishedProducts.KeyLot = PlannedOtherCosts.KeyLot
		|WHERE
		|	MultiplesOfLotsAndSemiFinishedProducts.StandardCostEstimate = &StandardCostEstimate
		|	AND NOT MultiplesOfLotsAndSemiFinishedProducts.SemiFinishedProduct = VALUE(Catalog.Products.EmptyRef)
		// The expenses for the issued Lot references are taken into account when forming the report on the planned cost of products
		|	AND NOT MultiplesOfLotsAndSemiFinishedProducts.LotIsReleased
		|
		|UNION ALL
		|
		|SELECT
		|	TTManufacturedProduct.Period,
		|	TTManufacturedProduct.StandardCostEstimate,
		|	TTManufacturedProduct.LotProductBOM,
		|	TTManufacturedProduct.ManufacturedProduct,
		|	TTManufacturedProduct.ItemVariant,
		|	TTManufacturedProduct.Purpose,
		|	TTManufacturedProduct.LotSemiFinishedProductBOM,
		|	TTManufacturedProduct.KeyLot AS KeyLot,
		|	TTManufacturedProduct.SemiFinishedProduct,
		|	TTManufacturedProduct.ItemVariantsOfIntermediateProduct,
		|	TTManufacturedProduct.Order,
		|	TTManufacturedProduct.QuantityOfSemiFinishedProduct,
		|	TTManufacturedProduct.CalculationIsCompleted,
		|	TTManufacturedProduct.LotIsReleased AS LotIsReleased,
		|	MaterialCostsIncludingSemiFinishedProducts.Cost * (TTManufacturedProduct.Numerator / TTManufacturedProduct.Denominator),
		|	MaterialCostsIncludingSemiFinishedProducts.CostExcludingVAT * (TTManufacturedProduct.Numerator / TTManufacturedProduct.Denominator),
		|	MaterialCostsIncludingSemiFinishedProducts.LocalCost * (TTManufacturedProduct.Numerator / TTManufacturedProduct.Denominator),
		|	MaterialCostsIncludingSemiFinishedProducts.LaborCosts * (TTManufacturedProduct.Numerator / TTManufacturedProduct.Denominator),
		|	MaterialCostsIncludingSemiFinishedProducts.LaborCostsLocal * (TTManufacturedProduct.Numerator / TTManufacturedProduct.Denominator),
		|	MaterialCostsIncludingSemiFinishedProducts.ItemizedFixed * (TTManufacturedProduct.Numerator / TTManufacturedProduct.Denominator),
		|	MaterialCostsIncludingSemiFinishedProducts.ItemizedFixedCostsExcludingVAT * (TTManufacturedProduct.Numerator / TTManufacturedProduct.Denominator),
		|	MaterialCostsIncludingSemiFinishedProducts.ItemizedFixedCostsCompl * (TTManufacturedProduct.Numerator / TTManufacturedProduct.Denominator),
		|	MaterialCostsIncludingSemiFinishedProducts.ItemizedVariable * (TTManufacturedProduct.Numerator / TTManufacturedProduct.Denominator),
		|	MaterialCostsIncludingSemiFinishedProducts.ItemizedVariableCostsExcludingVAT * (TTManufacturedProduct.Numerator / TTManufacturedProduct.Denominator),
		|	MaterialCostsIncludingSemiFinishedProducts.ItemizedVariableCostsCompl * (TTManufacturedProduct.Numerator / TTManufacturedProduct.Denominator),
		|	MaterialCostsIncludingSemiFinishedProducts.OffBalanceCost * (TTManufacturedProduct.Numerator / TTManufacturedProduct.Denominator),
		|	MaterialCostsIncludingSemiFinishedProducts.OffBalanceCostLocal * (TTManufacturedProduct.Numerator / TTManufacturedProduct.Denominator),
		|	TTManufacturedProduct.Numerator,
		|	TTManufacturedProduct.Denominator
		|FROM
		|	TTManufacturedProduct AS TTManufacturedProduct
		|		INNER JOIN MaterialCostsIncludingSemiFinishedProducts AS MaterialCostsIncludingSemiFinishedProducts
		|		ON TTManufacturedProduct.StandardCostEstimate = MaterialCostsIncludingSemiFinishedProducts.StandardCostEstimate
		|			AND TTManufacturedProduct.LotProductBOM = MaterialCostsIncludingSemiFinishedProducts.LotBOM
		|			AND TTManufacturedProduct.KeyLot = MaterialCostsIncludingSemiFinishedProducts.KeyLot
		|
		|UNION ALL
		|
		|SELECT
		|	TTManufacturedProduct.Period,
		|	TTManufacturedProduct.StandardCostEstimate,
		|	TTManufacturedProduct.LotProductBOM,
		|	TTManufacturedProduct.ManufacturedProduct,
		|	TTManufacturedProduct.ItemVariant,
		|	TTManufacturedProduct.Purpose,
		|	TTManufacturedProduct.LotSemiFinishedProductBOM,
		|	TTManufacturedProduct.KeyLot AS KeyLot,
		|	TTManufacturedProduct.SemiFinishedProduct,
		|	TTManufacturedProduct.ItemVariantsOfIntermediateProduct,
		|	TTManufacturedProduct.Order,
		|	TTManufacturedProduct.QuantityOfSemiFinishedProduct,
		|	TTManufacturedProduct.CalculationIsCompleted,
		|	TTManufacturedProduct.LotIsReleased AS LotIsReleased,
		|	0,
		|	0,
		|	0,
		|	PlannedLaborCosts.Cost * (TTManufacturedProduct.Numerator / TTManufacturedProduct.Denominator),
		|	PlannedLaborCosts.LocalCost * (TTManufacturedProduct.Numerator / TTManufacturedProduct.Denominator),
		|	0,
		|	0,
		|	0,
		|	0,
		|	0,
		|	0,
		|	0,
		|	0,
		|	TTManufacturedProduct.Numerator,
		|	TTManufacturedProduct.Denominator
		|FROM
		|	TTManufacturedProduct AS TTManufacturedProduct
		|		INNER JOIN PlannedLaborCosts AS PlannedLaborCosts
		|		ON TTManufacturedProduct.StandardCostEstimate = PlannedLaborCosts.StandardCostEstimate
		|			AND TTManufacturedProduct.LotProductBOM = PlannedLaborCosts.LotBOM
		|			AND TTManufacturedProduct.KeyLot = PlannedLaborCosts.KeyLot
		|
		|UNION ALL
		|
		|SELECT
		|	TTManufacturedProduct.Period,
		|	TTManufacturedProduct.StandardCostEstimate,
		|	TTManufacturedProduct.LotProductBOM,
		|	TTManufacturedProduct.ManufacturedProduct,
		|	TTManufacturedProduct.ItemVariant,
		|	TTManufacturedProduct.Purpose,
		|	TTManufacturedProduct.LotSemiFinishedProductBOM,
		|	TTManufacturedProduct.KeyLot AS KeyLot,
		|	TTManufacturedProduct.SemiFinishedProduct,
		|	TTManufacturedProduct.ItemVariantsOfIntermediateProduct,
		|	TTManufacturedProduct.Order,
		|	TTManufacturedProduct.QuantityOfSemiFinishedProduct,
		|	TTManufacturedProduct.CalculationIsCompleted,
		|	TTManufacturedProduct.LotIsReleased AS LotIsReleased,
		|	0,
		|	0,
		|	0,
		|	0,
		|	0,
		|	CASE
		|		WHEN PlannedOtherCosts.ExpenseItem.ProductionCostType = VALUE(Enum.ProductionCostType.Constant)
		|			THEN PlannedOtherCosts.Cost * (TTManufacturedProduct.Numerator / TTManufacturedProduct.Denominator)
		|		ELSE 0
		|	END,
		|	CASE
		|		WHEN PlannedOtherCosts.ExpenseItem.ProductionCostType = VALUE(Enum.ProductionCostType.Constant)
		|			THEN PlannedOtherCosts.CostExcludingVAT * (TTManufacturedProduct.Numerator / TTManufacturedProduct.Denominator)
		|		ELSE 0
		|	END,
		|	CASE
		|		WHEN PlannedOtherCosts.ExpenseItem.ProductionCostType = VALUE(Enum.ProductionCostType.Constant)
		|			THEN PlannedOtherCosts.LocalCost * (TTManufacturedProduct.Numerator / TTManufacturedProduct.Denominator)
		|		ELSE 0
		|	END,
		|	CASE
		|		WHEN PlannedOtherCosts.ExpenseItem.ProductionCostType = VALUE(Enum.ProductionCostType.Constant)
		|			THEN 0
		|		ELSE PlannedOtherCosts.Cost * (TTManufacturedProduct.Numerator / TTManufacturedProduct.Denominator)
		|	END,
		|	CASE
		|		WHEN PlannedOtherCosts.ExpenseItem.ProductionCostType = VALUE(Enum.ProductionCostType.Constant)
		|			THEN 0
		|		ELSE PlannedOtherCosts.LocalCost * (TTManufacturedProduct.Numerator / TTManufacturedProduct.Denominator)
		|	END,
		|	CASE
		|		WHEN PlannedOtherCosts.ExpenseItem.ProductionCostType = VALUE(Enum.ProductionCostType.Constant)
		|			THEN 0
		|		ELSE PlannedOtherCosts.LocalCost * (TTManufacturedProduct.Numerator / TTManufacturedProduct.Denominator)
		|	END,
		|	0,
		|	0,
		|	TTManufacturedProduct.Numerator,
		|	TTManufacturedProduct.Denominator
		|FROM
		|	TTManufacturedProduct AS TTManufacturedProduct
		|		INNER JOIN PlannedOtherCosts AS PlannedOtherCosts
		|		ON TTManufacturedProduct.StandardCostEstimate = PlannedOtherCosts.StandardCostEstimate
		|			AND TTManufacturedProduct.LotProductBOM = PlannedOtherCosts.LotBOM
		|			AND TTManufacturedProduct.KeyLot = PlannedOtherCosts.KeyLot
		|;
		|
		|SELECT DISTINCT
		|	Costs.ManufacturedProduct AS ManufacturedProduct,
		|	Costs.LotProductBOM AS LotProductBOM,
		|	Costs.StandardCostEstimate AS StandardCostEstimate,
		|	Costs.ItemVariant AS ItemVariant,
		|	Costs.Purpose AS Purpose,
		|	Costs.LotSemiFinishedProductBOM AS LotSemiFinishedProductBOM,
		|	Costs.KeyLot AS KeyLot,
		|	Costs.SemiFinishedProduct AS SemiFinishedProduct,
		|	Costs.ItemVariantsOfIntermediateProduct AS ItemVariantsOfIntermediateProduct,
		|	Costs.Order AS Order
		|INTO SummaryMultipliers
		|FROM
		|	Costs AS Costs
		|
		|INDEX BY
		|	ManufacturedProduct,
		|	LotProductBOM,
		|	StandardCostEstimate,
		|	ItemVariant,
		|	Purpose,
		|	LotSemiFinishedProductBOM,
		|	KeyLot,
		|	SemiFinishedProduct,
		|	ItemVariantsOfIntermediateProduct,
		|	Order
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT
		|	Costs.Period AS Period,
		|	Costs.ManufacturedProduct AS ManufacturedProduct,
		|	Costs.LotProductBOM AS LotProductBOM,
		|	Costs.StandardCostEstimate AS StandardCostEstimate,
		|	Costs.ItemVariant AS ItemVariant,
		|	Costs.Purpose AS Purpose,
		|	SUM(Costs.LaborCosts) AS LaborCosts,
		|	SUM(Costs.LaborCostsLocal) AS LaborCostsLocal,
		|	SUM(Costs.ItemizedVariable) AS ItemizedVariable,
		|	SUM(Costs.ItemizedVariableCostsExcludingVAT) AS ItemizedVariableCostsExcludingVAT,
		|	SUM(Costs.ItemizedVariableCostsCompl) AS ItemizedVariableCostsCompl,
		|	SUM(Costs.ItemizedFixed) AS ItemizedFixed,
		|	SUM(Costs.ItemizedFixedCostsExcludingVAT) AS ItemizedFixedCostsExcludingVAT,
		|	SUM(Costs.ItemizedFixedCostsCompl) AS ItemizedFixedCostsCompl,
		|	SUM(Costs.Material_ + Costs.LaborCosts + Costs.ItemizedVariable + Costs.ItemizedFixed) AS Cost,
		|	SUM(Costs.TangibleExcludingVAT + Costs.LaborCosts + Costs.ItemizedVariableCostsExcludingVAT + Costs.ItemizedFixedCostsExcludingVAT) AS CostExcludingVAT,
		|	SUM(Costs.TangibleCompl + Costs.LaborCostsLocal + Costs.ItemizedVariableCostsCompl + Costs.ItemizedFixedCostsCompl) AS LocalCost,
		|	SUM(Costs.MaterialOffBalance) AS OffBalanceCost,
		|	SUM(Costs.MaterialOffBalanceLocal) AS OffBalanceCostLocal,
		|	Costs.LotSemiFinishedProductBOM AS LotSemiFinishedProductBOM,
		|	Costs.KeyLot AS KeyLot,
		|	Costs.SemiFinishedProduct AS SemiFinishedProduct,
		|	Costs.ItemVariantsOfIntermediateProduct AS ItemVariantsOfIntermediateProduct,
		|	Costs.Order AS Order,
		|	Costs.Numerator AS Numerator,
		|	Costs.Denominator AS Denominator,
		|	Costs.QuantityOfSemiFinishedProduct AS QuantityOfSemiFinishedProduct,
		|	Costs.CalculationIsCompleted AS CalculationIsCompleted,
		|	Costs.LotIsReleased AS LotIsReleased
		|INTO MultiplesOfLotsAndSemiFinishedProducts
		|FROM
		|	Costs AS Costs
		|
		|GROUP BY
		|	Costs.Period,
		|	Costs.ManufacturedProduct,
		|	Costs.LotProductBOM,
		|	Costs.StandardCostEstimate,
		|	Costs.ItemVariant,
		|	Costs.Purpose,
		|	Costs.LotSemiFinishedProductBOM,
		|	Costs.KeyLot,
		|	Costs.SemiFinishedProduct,
		|	Costs.ItemVariantsOfIntermediateProduct,
		|	Costs.Order,
		|	Costs.Denominator,
		|	Costs.Numerator,
		|	Costs.QuantityOfSemiFinishedProduct,
		|	Costs.CalculationIsCompleted,
		|	Costs.LotIsReleased
		|
		|UNION ALL
		|
		|SELECT
		|	MultiplesOfLotsAndSemiFinishedProducts.Period,
		|	MultiplesOfLotsAndSemiFinishedProducts.ManufacturedProduct,
		|	MultiplesOfLotsAndSemiFinishedProducts.LotProductBOM,
		|	MultiplesOfLotsAndSemiFinishedProducts.StandardCostEstimate,
		|	MultiplesOfLotsAndSemiFinishedProducts.ItemVariant,
		|	MultiplesOfLotsAndSemiFinishedProducts.Purpose,
		|	MultiplesOfLotsAndSemiFinishedProducts.LaborCosts,
		|	MultiplesOfLotsAndSemiFinishedProducts.LaborCostsLocal,
		|	MultiplesOfLotsAndSemiFinishedProducts.ItemizedVariable,
		|	MultiplesOfLotsAndSemiFinishedProducts.ItemizedVariableCostsExcludingVAT,
		|	MultiplesOfLotsAndSemiFinishedProducts.ItemizedVariableCostsCompl,
		|	MultiplesOfLotsAndSemiFinishedProducts.ItemizedFixed,
		|	MultiplesOfLotsAndSemiFinishedProducts.ItemizedFixedCostsExcludingVAT,
		|	MultiplesOfLotsAndSemiFinishedProducts.ItemizedFixedCostsCompl,
		|	MultiplesOfLotsAndSemiFinishedProducts.Cost,
		|	MultiplesOfLotsAndSemiFinishedProducts.CostExcludingVAT,
		|	MultiplesOfLotsAndSemiFinishedProducts.LocalCost,
		|	MultiplesOfLotsAndSemiFinishedProducts.OffBalanceCost,
		|	MultiplesOfLotsAndSemiFinishedProducts.OffBalanceCostLocal,
		|	MultiplesOfLotsAndSemiFinishedProducts.LotSemiFinishedProductBOM,
		|	MultiplesOfLotsAndSemiFinishedProducts.KeyLot AS KeyLot,
		|	MultiplesOfLotsAndSemiFinishedProducts.SemiFinishedProduct,
		|	MultiplesOfLotsAndSemiFinishedProducts.ItemVariantsOfIntermediateProduct,
		|	MultiplesOfLotsAndSemiFinishedProducts.Order,
		|	MultiplesOfLotsAndSemiFinishedProducts.Numerator,
		|	MultiplesOfLotsAndSemiFinishedProducts.Denominator,
		|	MultiplesOfLotsAndSemiFinishedProducts.QuantityOfSemiFinishedProduct,
		|	MultiplesOfLotsAndSemiFinishedProducts.CalculationIsCompleted,
		|	MultiplesOfLotsAndSemiFinishedProducts.LotIsReleased
		|FROM
		|	InformationRegister.MultiplesOfLotsAndSemiFinishedProducts AS MultiplesOfLotsAndSemiFinishedProducts
		|WHERE
		|	MultiplesOfLotsAndSemiFinishedProducts.LotIsReleased
		|	AND MultiplesOfLotsAndSemiFinishedProducts.StandardCostEstimate = &StandardCostEstimate
		|
		|UNION ALL
		|
		|SELECT
		|	MultiplesOfLotsAndSemiFinishedProducts.Period,
		|	MultiplesOfLotsAndSemiFinishedProducts.ManufacturedProduct,
		|	MultiplesOfLotsAndSemiFinishedProducts.LotProductBOM,
		|	MultiplesOfLotsAndSemiFinishedProducts.StandardCostEstimate,
		|	MultiplesOfLotsAndSemiFinishedProducts.ItemVariant,
		|	MultiplesOfLotsAndSemiFinishedProducts.Purpose,
		|	MultiplesOfLotsAndSemiFinishedProducts.LaborCosts,
		|	MultiplesOfLotsAndSemiFinishedProducts.LaborCostsLocal,
		|	MultiplesOfLotsAndSemiFinishedProducts.ItemizedVariable,
		|	MultiplesOfLotsAndSemiFinishedProducts.ItemizedVariableCostsExcludingVAT,
		|	MultiplesOfLotsAndSemiFinishedProducts.ItemizedVariableCostsCompl,
		|	MultiplesOfLotsAndSemiFinishedProducts.ItemizedFixed,
		|	MultiplesOfLotsAndSemiFinishedProducts.ItemizedFixedCostsExcludingVAT,
		|	MultiplesOfLotsAndSemiFinishedProducts.ItemizedFixedCostsCompl,
		|	MultiplesOfLotsAndSemiFinishedProducts.Cost,
		|	MultiplesOfLotsAndSemiFinishedProducts.CostExcludingVAT,
		|	MultiplesOfLotsAndSemiFinishedProducts.LocalCost,
		|	MultiplesOfLotsAndSemiFinishedProducts.OffBalanceCost,
		|	MultiplesOfLotsAndSemiFinishedProducts.OffBalanceCostLocal,
		|	MultiplesOfLotsAndSemiFinishedProducts.LotSemiFinishedProductBOM,
		|	MultiplesOfLotsAndSemiFinishedProducts.KeyLot AS KeyLot,
		|	MultiplesOfLotsAndSemiFinishedProducts.SemiFinishedProduct,
		|	MultiplesOfLotsAndSemiFinishedProducts.ItemVariantsOfIntermediateProduct,
		|	MultiplesOfLotsAndSemiFinishedProducts.Order,
		|	MultiplesOfLotsAndSemiFinishedProducts.Numerator,
		|	MultiplesOfLotsAndSemiFinishedProducts.Denominator,
		|	MultiplesOfLotsAndSemiFinishedProducts.QuantityOfSemiFinishedProduct,
		|	MultiplesOfLotsAndSemiFinishedProducts.CalculationIsCompleted,
		|	MultiplesOfLotsAndSemiFinishedProducts.LotIsReleased
		|FROM
		|	InformationRegister.MultiplesOfLotsAndSemiFinishedProducts AS MultiplesOfLotsAndSemiFinishedProducts
		|		LEFT JOIN SummaryMultipliers AS SummaryMultipliers
		|		ON SummaryMultipliers.StandardCostEstimate = MultiplesOfLotsAndSemiFinishedProducts.StandardCostEstimate 
		|			AND SummaryMultipliers.LotProductBOM = MultiplesOfLotsAndSemiFinishedProducts.LotProductBOM 
		|			AND SummaryMultipliers.ManufacturedProduct = MultiplesOfLotsAndSemiFinishedProducts.ManufacturedProduct 
		|			AND SummaryMultipliers.ItemVariant = MultiplesOfLotsAndSemiFinishedProducts.ItemVariant 
		|			AND SummaryMultipliers.Purpose = MultiplesOfLotsAndSemiFinishedProducts.Purpose 
		|			AND SummaryMultipliers.LotSemiFinishedProductBOM = MultiplesOfLotsAndSemiFinishedProducts.LotSemiFinishedProductBOM 
		|			AND SummaryMultipliers.KeyLot = MultiplesOfLotsAndSemiFinishedProducts.KeyLot
		|			AND SummaryMultipliers.SemiFinishedProduct = MultiplesOfLotsAndSemiFinishedProducts.SemiFinishedProduct 
		|			AND SummaryMultipliers.ItemVariantsOfIntermediateProduct = MultiplesOfLotsAndSemiFinishedProducts.ItemVariantsOfIntermediateProduct 
		|			AND SummaryMultipliers.Order = MultiplesOfLotsAndSemiFinishedProducts.Order 
		|WHERE
		|	MultiplesOfLotsAndSemiFinishedProducts.QuantityOfSemiFinishedProduct = 0
		|	AND MultiplesOfLotsAndSemiFinishedProducts.StandardCostEstimate = &StandardCostEstimate
		|	AND SummaryMultipliers.StandardCostEstimate IS NULL
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|DROP SummaryMultipliers
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|DROP MaterialPrices
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|DROP Costs
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|DROP TTManufacturedProduct";
	
	Query.SetParameter("StandardCostEstimate", CalculationParameters.StandardCostEstimate);
	
	Query.ExecuteBatch();
	
	If DeleteOtherCostTable Then
		
		Query.Text =
			"DROP PlannedOtherCosts";
		
		SetPrivilegedMode(True);
		Query.Execute();
		SetPrivilegedMode(False);
		
	EndIf;
	
EndProcedure

Procedure CalculateMaterialPrices(CalculationParameters, TempTableManager)

	Query = New Query;
	Query.TempTablesManager = TempTableManager;
	       
	Query.Text =
		"SELECT
		|	Multipliers.StandardCostEstimate,
		|	Multipliers.LotSemiFinishedProductBOM AS LotSemiFinishedProductBOM,
		|	Multipliers.KeyLot AS KeyLot,
		|	Multipliers.SemiFinishedProduct AS Products,
		|	Multipliers.ItemVariantsOfIntermediateProduct AS Characteristic,
		|	Multipliers.Denominator AS Denominator,
		|	MAX(Multipliers.Order) AS Order,
		|	SUM(Multipliers.QuantityOfSemiFinishedProduct) AS QuantityOfSemiFinishedProduct,
		|	SUM(Multipliers.Numerator) AS Numerator,
		|	SUM(CASE
		|			WHEN Multipliers.LotIsReleased
		|				THEN CAST(Multipliers.Cost / (Multipliers.Numerator / Multipliers.Denominator) AS NUMBER(31,2))
		|			ELSE 0
		|		END) AS Cost,
		|	SUM(CASE
		|			WHEN Multipliers.LotIsReleased
		|				THEN CAST(Multipliers.CostExcludingVAT / (Multipliers.Numerator / Multipliers.Denominator) AS NUMBER(31,2))
		|			ELSE 0
		|		END) AS CostExcludingVAT,
		|	SUM(CASE
		|			WHEN Multipliers.LotIsReleased
		|				THEN CAST(Multipliers.LocalCost / (Multipliers.Numerator / Multipliers.Denominator) AS NUMBER(31,2))
		|			ELSE 0
		|		END) AS LocalCost,
		|	SUM(CASE
		|			WHEN Multipliers.LotIsReleased
		|				THEN CAST(Multipliers.LaborCosts / (Multipliers.Numerator / Multipliers.Denominator) AS NUMBER(31,2))
		|			ELSE 0
		|		END) AS LaborCosts,
		|	SUM(CASE
		|			WHEN Multipliers.LotIsReleased
		|				THEN CAST(Multipliers.LaborCostsLocal / (Multipliers.Numerator / Multipliers.Denominator) AS NUMBER(31,2))
		|			ELSE 0
		|		END) AS LaborCostsLocal,
		|	SUM(CASE
		|			WHEN Multipliers.LotIsReleased
		|				THEN CAST(Multipliers.ItemizedFixed / (Multipliers.Numerator / Multipliers.Denominator) AS NUMBER(31,2))
		|			ELSE 0
		|		END) AS ItemizedFixed,
		|	SUM(CASE
		|			WHEN Multipliers.LotIsReleased
		|				THEN CAST(Multipliers.ItemizedFixedCostsExcludingVAT / (Multipliers.Numerator / Multipliers.Denominator) AS NUMBER(31,2))
		|			ELSE 0
		|		END) AS ItemizedFixedCostsExcludingVAT,
		|	SUM(CASE
		|			WHEN Multipliers.LotIsReleased
		|				THEN CAST(Multipliers.ItemizedFixedCostsCompl / (Multipliers.Numerator / Multipliers.Denominator) AS NUMBER(31,2))
		|			ELSE 0
		|		END) AS ItemizedFixedCostsCompl,
		|	SUM(CASE
		|			WHEN Multipliers.LotIsReleased
		|				THEN CAST(Multipliers.ItemizedVariable / (Multipliers.Numerator / Multipliers.Denominator) AS NUMBER(31,2))
		|			ELSE 0
		|		END) AS ItemizedVariable,
		|	SUM(CASE
		|			WHEN Multipliers.LotIsReleased
		|				THEN CAST(Multipliers.ItemizedVariableCostsExcludingVAT / (Multipliers.Numerator / Multipliers.Denominator) AS NUMBER(31,2))
		|			ELSE 0
		|		END) AS ItemizedVariableCostsExcludingVAT,
		|	SUM(CASE
		|			WHEN Multipliers.LotIsReleased
		|				THEN CAST(Multipliers.ItemizedVariableCostsCompl / (Multipliers.Numerator / Multipliers.Denominator) AS NUMBER(31,2))
		|			ELSE 0
		|		END) AS ItemizedVariableCostsCompl,
		|	SUM(CASE
		|			WHEN Multipliers.LotIsReleased
		|				THEN CAST(Multipliers.OffBalanceCost / (Multipliers.Numerator / Multipliers.Denominator) AS NUMBER(31,2))
		|			ELSE 0
		|		END) AS OffBalanceCost,
		|	SUM(CASE
		|			WHEN Multipliers.LotIsReleased
		|				THEN CAST(Multipliers.OffBalanceCostLocal / (Multipliers.Numerator / Multipliers.Denominator) AS NUMBER(31,2))
		|			ELSE 0
		|		END) AS OffBalanceCostLocal
		|INTO SetOfSemiFinishedProducts
		|FROM
		|	InformationRegister.MultiplesOfLotsAndSemiFinishedProducts AS Multipliers
		|WHERE
		|	Multipliers.StandardCostEstimate = &StandardCostEstimate
		|	AND NOT Multipliers.SemiFinishedProduct = VALUE(Catalog.Products.EmptyRef)
		|
		|GROUP BY
		|	Multipliers.ItemVariantsOfIntermediateProduct,
		|	Multipliers.LotSemiFinishedProductBOM,
		|	Multipliers.KeyLot,
		|	Multipliers.StandardCostEstimate,
		|	Multipliers.SemiFinishedProduct,
		|	Multipliers.Denominator
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT
		|	SetOfSemiFinishedProducts.StandardCostEstimate AS StandardCostEstimate,
		|	SetOfSemiFinishedProducts.Products AS Products,
		|	SetOfSemiFinishedProducts.Characteristic AS Characteristic,
		|	SetOfSemiFinishedProducts.Denominator AS Denominator,
		|	SetOfSemiFinishedProducts.Order AS Order,
		|	SetOfSemiFinishedProducts.QuantityOfSemiFinishedProduct AS Count,
		|	SetOfSemiFinishedProducts.Numerator AS Numerator,
		|	SetOfSemiFinishedProducts.LotSemiFinishedProductBOM AS SemiFinishedProductLot,
		|	SetOfSemiFinishedProducts.KeyLot AS KeyLot
		|FROM
		|	SetOfSemiFinishedProducts AS SetOfSemiFinishedProducts
		|
		|ORDER BY
		|	SetOfSemiFinishedProducts.Order DESC
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT
		|	SetOfSemiFinishedProducts.StandardCostEstimate AS StandardCostEstimate,
		|	SetOfSemiFinishedProducts.LotSemiFinishedProductBOM AS LotSemiFinishedProductBOM,
		|	SetOfSemiFinishedProducts.KeyLot AS KeyLot,
		|	SetOfSemiFinishedProducts.Products AS Products,
		|	SetOfSemiFinishedProducts.Characteristic AS Characteristic,
		|	SUM(SetOfSemiFinishedProducts.Cost) AS Cost,
		|	SUM(SetOfSemiFinishedProducts.CostExcludingVAT) AS CostExcludingVAT,
		|	SUM(SetOfSemiFinishedProducts.LocalCost) AS LocalCost,
		|	SUM(SetOfSemiFinishedProducts.LaborCosts) AS LaborCosts,
		|	SUM(SetOfSemiFinishedProducts.LaborCostsLocal) AS LaborCostsLocal,
		|	SUM(SetOfSemiFinishedProducts.ItemizedFixed) AS ItemizedFixed,
		|	SUM(SetOfSemiFinishedProducts.ItemizedFixedCostsExcludingVAT) AS ItemizedFixedCostsExcludingVAT,
		|	SUM(SetOfSemiFinishedProducts.ItemizedFixedCostsCompl) AS ItemizedFixedCostsCompl,
		|	SUM(SetOfSemiFinishedProducts.ItemizedVariable) AS ItemizedVariable,
		|	SUM(SetOfSemiFinishedProducts.ItemizedVariableCostsExcludingVAT) AS ItemizedVariableCostsExcludingVAT,
		|	SUM(SetOfSemiFinishedProducts.ItemizedVariableCostsCompl) AS ItemizedVariableCostsCompl,
		|	SUM(SetOfSemiFinishedProducts.OffBalanceCost) AS OffBalanceCost,
		|	SUM(SetOfSemiFinishedProducts.OffBalanceCostLocal) AS OffBalanceCostLocal
		|INTO SemiFinishedProductsConsolidated
		|FROM
		|	SetOfSemiFinishedProducts AS SetOfSemiFinishedProducts
		|
		|GROUP BY
		|	SetOfSemiFinishedProducts.Characteristic,
		|	SetOfSemiFinishedProducts.LotSemiFinishedProductBOM,
		|	SetOfSemiFinishedProducts.KeyLot,
		|	SetOfSemiFinishedProducts.StandardCostEstimate,
		|	SetOfSemiFinishedProducts.Products
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT
		|	Costs.StandardCostEstimate AS StandardCostEstimate,
		|	Costs.Products AS Products,
		|	Costs.Characteristic AS Characteristic,
		|	Costs.LotSemiFinishedProductBOM AS SemiFinishedProductLot,
		|	Costs.KeyLot,
		|	Costs.Material AS Material,
		|	Costs.ItemVariantOfMaterial AS ItemVariantOfMaterial,
		|	SUM(Costs.MaterialQuantity) AS MaterialQuantity,
		|	SUM(Costs.Cost) AS Cost,
		|	SUM(Costs.CostExcludingVAT) AS CostExcludingVAT,
		|	SUM(Costs.LocalCost) AS LocalCost,
		|	SUM(Costs.LaborCosts) AS LaborCosts,
		|	SUM(Costs.LaborCostsLocal) AS LaborCostsLocal,
		|	SUM(Costs.ItemizedFixed) AS ItemizedFixed,
		|	SUM(Costs.ItemizedFixedCostsExcludingVAT) AS ItemizedFixedCostsExcludingVAT,
		|	SUM(Costs.ItemizedFixedCostsCompl) AS ItemizedFixedCostsCompl,
		|	SUM(Costs.ItemizedVariable) AS ItemizedVariable,
		|	SUM(Costs.ItemizedVariableCostsExcludingVAT) AS ItemizedVariableCostsExcludingVAT,
		|	SUM(Costs.ItemizedVariableCostsCompl) AS ItemizedVariableCostsCompl,
		|	SUM(Costs.OffBalanceCost) AS OffBalanceCost,
		|	SUM(Costs.OffBalanceCostLocal) AS OffBalanceCostLocal
		|FROM
		|	(SELECT
		|		SetOfSemiFinishedProducts.StandardCostEstimate AS StandardCostEstimate,
		|		SetOfSemiFinishedProducts.Products AS Products,
		|		SetOfSemiFinishedProducts.Characteristic AS Characteristic,
		|		SetOfSemiFinishedProducts.LotSemiFinishedProductBOM AS LotSemiFinishedProductBOM,
		|		SetOfSemiFinishedProducts.KeyLot AS KeyLot,
		|		CASE
		|			WHEN PMZ.ThisIsASemiFinishedProduct
		|				THEN PMZ.Count
		|			ELSE 0
		|		END AS MaterialQuantity,
		|		CASE
		|			WHEN PMZ.ThisIsASemiFinishedProduct
		|				THEN 0
		|			ELSE PMZ.Cost
		|		END AS Cost,
		|		CASE
		|			WHEN PMZ.ThisIsASemiFinishedProduct
		|				THEN 0
		|			ELSE PMZ.CostExcludingVAT
		|		END AS CostExcludingVAT,
		|		CASE
		|			WHEN PMZ.ThisIsASemiFinishedProduct
		|				THEN 0
		|			ELSE PMZ.LocalCost
		|		END AS LocalCost,
		|		0 AS LaborCosts,
		|		0 AS LaborCostsLocal,
		|		0 AS ItemizedFixed,
		|		0 AS ItemizedFixedCostsExcludingVAT,
		|		0 AS ItemizedFixedCostsCompl,
		|		0 AS ItemizedVariable,
		|		0 AS ItemizedVariableCostsExcludingVAT,
		|		0 AS ItemizedVariableCostsCompl,
		|		0 AS OffBalanceCost,
		|		0 AS OffBalanceCostLocal,
		|		CASE
		|			WHEN PMZ.ThisIsASemiFinishedProduct
		|				THEN PMZ.Products
		|			ELSE UNDEFINED
		|		END AS Material,
		|		CASE
		|			WHEN PMZ.ThisIsASemiFinishedProduct
		|				THEN PMZ.Characteristic
		|			ELSE UNDEFINED
		|		END AS ItemVariantOfMaterial
		|	FROM
		|		SemiFinishedProductsConsolidated AS SetOfSemiFinishedProducts
		|			INNER JOIN MaterialCosts AS PMZ
		|			ON SetOfSemiFinishedProducts.StandardCostEstimate = PMZ.StandardCostEstimate
		|				AND SetOfSemiFinishedProducts.LotSemiFinishedProductBOM = PMZ.LotBOM
		|				AND SetOfSemiFinishedProducts.KeyLot = PMZ.KeyLot
		|	
		|	UNION ALL
		|	
		|	SELECT
		|		SetOfSemiFinishedProducts.StandardCostEstimate,
		|		SetOfSemiFinishedProducts.Products,
		|		SetOfSemiFinishedProducts.Characteristic,
		|		SetOfSemiFinishedProducts.LotSemiFinishedProductBOM,
		|		SetOfSemiFinishedProducts.KeyLot AS KeyLot,
		|		0,
		|		0,
		|		0,
		|		0,
		|		PlannedLaborCosts.Cost,
		|		PlannedLaborCosts.LocalCost,
		|		0,
		|		0,
		|		0,
		|		0,
		|		0,
		|		0,
		|		0,
		|		0,
		|		UNDEFINED,
		|		UNDEFINED
		|	FROM
		|		SemiFinishedProductsConsolidated AS SetOfSemiFinishedProducts
		|			INNER JOIN PlannedLaborCosts AS PlannedLaborCosts
		|			ON SetOfSemiFinishedProducts.StandardCostEstimate = PlannedLaborCosts.StandardCostEstimate
		|				AND SetOfSemiFinishedProducts.LotSemiFinishedProductBOM = PlannedLaborCosts.LotBOM
		|				AND SetOfSemiFinishedProducts.KeyLot = PlannedLaborCosts.KeyLot
		|	
		|	UNION ALL
		|	
		|	SELECT
		|		SetOfSemiFinishedProducts.StandardCostEstimate,
		|		SetOfSemiFinishedProducts.Products,
		|		SetOfSemiFinishedProducts.Characteristic,
		|		SetOfSemiFinishedProducts.LotSemiFinishedProductBOM,
		|		SetOfSemiFinishedProducts.KeyLot AS KeyLot,
		|		0,
		|		0,
		|		0,
		|		0,
		|		0,
		|		0,
		|		CASE
		|			WHEN PlannedOtherCosts.ExpenseItem.ProductionCostType = VALUE(Enum.ProductionCostType.Constant)
		|				THEN PlannedOtherCosts.Cost
		|			ELSE
		|				0
		|		END AS ItemizedFixed,
		|		CASE
		|			WHEN PlannedOtherCosts.ExpenseItem.ProductionCostType = VALUE(Enum.ProductionCostType.Constant)
		|				THEN PlannedOtherCosts.CostExcludingVAT
		|			ELSE
		|				0
		|		END AS ItemizedFixedCostsExcludingVAT,
		|		CASE
		|			WHEN PlannedOtherCosts.ExpenseItem.ProductionCostType = VALUE(Enum.ProductionCostType.Constant)
		|				THEN PlannedOtherCosts.LocalCost
		|			ELSE
		|				0
		|		END AS ItemizedFixedCostsCompl,
		|		CASE
		|			WHEN PlannedOtherCosts.ExpenseItem.ProductionCostType = VALUE(Enum.ProductionCostType.Variables1)
		|				THEN PlannedOtherCosts.Cost
		|			ELSE
		|				0
		|		END AS ItemizedVariable,
		|		CASE
		|			WHEN PlannedOtherCosts.ExpenseItem.ProductionCostType = VALUE(Enum.ProductionCostType.Variables1)
		|				THEN PlannedOtherCosts.CostExcludingVAT
		|			ELSE
		|				0
		|		END AS ItemizedVariableCostsExcludingVAT,
		|		CASE
		|			WHEN PlannedOtherCosts.ExpenseItem.ProductionCostType = VALUE(Enum.ProductionCostType.Variables1)
		|				THEN PlannedOtherCosts.LocalCost
		|			ELSE
		|				0
		|		END AS ItemizedVariableCostsCompl,
		|		0,
		|		0,
		|		UNDEFINED,
		|		UNDEFINED
		|	FROM
		|		SetOfSemiFinishedProducts AS SetOfSemiFinishedProducts
		|			INNER JOIN PlannedOtherCosts AS PlannedOtherCosts
		|			ON SetOfSemiFinishedProducts.StandardCostEstimate = PlannedOtherCosts.StandardCostEstimate
		|				AND SetOfSemiFinishedProducts.LotSemiFinishedProductBOM = PlannedOtherCosts.LotBOM
		|				AND SetOfSemiFinishedProducts.KeyLot = PlannedOtherCosts.KeyLot
		|	
		|	UNION ALL
		|	
		|	SELECT
		|		SetOfSemiFinishedProducts.StandardCostEstimate,
		|		SetOfSemiFinishedProducts.Products,
		|		SetOfSemiFinishedProducts.Characteristic,
		|		SetOfSemiFinishedProducts.LotSemiFinishedProductBOM,
		|		SetOfSemiFinishedProducts.KeyLot,
		|		0,
		|		SetOfSemiFinishedProducts.Cost,
		|		SetOfSemiFinishedProducts.CostExcludingVAT,
		|		SetOfSemiFinishedProducts.LocalCost,
		|		SetOfSemiFinishedProducts.LaborCosts,
		|		SetOfSemiFinishedProducts.LaborCostsLocal,
		|		SetOfSemiFinishedProducts.ItemizedFixed,
		|		SetOfSemiFinishedProducts.ItemizedFixedCostsExcludingVAT,
		|		SetOfSemiFinishedProducts.ItemizedFixedCostsCompl,
		|		SetOfSemiFinishedProducts.ItemizedVariable,
		|		SetOfSemiFinishedProducts.ItemizedVariableCostsExcludingVAT,
		|		SetOfSemiFinishedProducts.ItemizedVariableCostsCompl,
		|		SetOfSemiFinishedProducts.OffBalanceCost,
		|		SetOfSemiFinishedProducts.OffBalanceCostLocal,
		|		UNDEFINED,
		|		UNDEFINED
		|	FROM
		|		SetOfSemiFinishedProducts AS SetOfSemiFinishedProducts
		|	WHERE
		|		NOT(SetOfSemiFinishedProducts.Cost = 0
		|					AND SetOfSemiFinishedProducts.CostExcludingVAT = 0
		|					AND SetOfSemiFinishedProducts.LocalCost = 0
		|					AND SetOfSemiFinishedProducts.LaborCosts = 0
		|					AND SetOfSemiFinishedProducts.LaborCostsLocal = 0
		|					AND SetOfSemiFinishedProducts.ItemizedFixed = 0
		|					AND SetOfSemiFinishedProducts.ItemizedFixedCostsExcludingVAT = 0
		|					AND SetOfSemiFinishedProducts.ItemizedFixedCostsCompl = 0
		|					AND SetOfSemiFinishedProducts.ItemizedVariable = 0
		|					AND SetOfSemiFinishedProducts.ItemizedVariableCostsExcludingVAT = 0
		|					AND SetOfSemiFinishedProducts.ItemizedVariableCostsCompl = 0
		|					AND SetOfSemiFinishedProducts.OffBalanceCost = 0
		|					AND SetOfSemiFinishedProducts.OffBalanceCostLocal = 0)) AS Costs
		|
		|GROUP BY
		|	Costs.Products,
		|	Costs.ItemVariantOfMaterial,
		|	Costs.LotSemiFinishedProductBOM,
		|	Costs.KeyLot,
		|	Costs.Material,
		|	Costs.StandardCostEstimate,
		|	Costs.Characteristic
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|DROP SemiFinishedProductsConsolidated
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|DROP SetOfSemiFinishedProducts";
	
	Query.SetParameter("StandardCostEstimate", CalculationParameters.StandardCostEstimate);
	ResultsArray = Query.ExecuteBatch();
	
	SelectionOfSemiFinishedProducts = ResultsArray[1].Select();
	
	Costs = ResultsArray[3].Unload(); // ValueTable
	Costs.Indexes.Add("StandardCostEstimate, Products, Characteristic, SemiFinishedProductLot, KeyLot");
	
	FilterCosts_ = New Structure("StandardCostEstimate, Products, Characteristic, SemiFinishedProductLot, KeyLot");
	
	ResourcesToCalculate = New Map();
	ResourcesToCalculate.Insert("Cost","PriceCost");										//@Query-part
	ResourcesToCalculate.Insert("CostExcludingVAT","PriceValueWithoutVAT");							//@Query-part
	ResourcesToCalculate.Insert("LocalCost","PriceLocalCost");								//@Query-part
	ResourcesToCalculate.Insert("LaborCosts","PriceLaborCosts");								//@Query-part
	ResourcesToCalculate.Insert("LaborCostsLocal","PriceLaborCostsLocal");						//@Query-part
	ResourcesToCalculate.Insert("ItemizedFixed","PriceArticleByArticleConstants");				//@Query-part
	ResourcesToCalculate.Insert("ItemizedFixedCostsExcludingVAT","PriceArticleByArticlePermanentWithoutVAT");	//@Query-part
	ResourcesToCalculate.Insert("ItemizedFixedCostsCompl","PriceArticleByArticlePermanentLocal");		//@Query-part
	ResourcesToCalculate.Insert("ItemizedVariable","PriceArticleByArticleVariables");				//@Query-part
	ResourcesToCalculate.Insert("ItemizedVariableCostsExcludingVAT","PriceArticleByArticleVariablesWithoutVAT");	//@Query-part
	ResourcesToCalculate.Insert("ItemizedVariableCostsCompl","PriceArticleByArticleVariablesLocal");		//@Query-part
	ResourcesToCalculate.Insert("OffBalanceCost","PriceCostOffBalanceSheet");				//@Query-part
	ResourcesToCalculate.Insert("OffBalanceCostLocal","PriceCostOffBalanceLocal");		//@Query-part
	
	MaterialPrices = New ValueTable;
	MaterialPrices.Columns.Add("StandardCostEstimate", New TypeDescription("DocumentRef.StandardCosting2_2"));
	MaterialPrices.Columns.Add("Products", New TypeDescription("CatalogRef.Products"));
	MaterialPrices.Columns.Add("Characteristic", New TypeDescription("CatalogRef.ItemsCharacteristics"));
	
	For Each Resource In ResourcesToCalculate Do
		MaterialPrices.Columns.Add(Resource.Value, New TypeDescription("Number", New NumberQualifiers(23, 10)));
	EndDo;
	
	MaterialPrices.Indexes.Add("StandardCostEstimate, Products, Characteristic");
	
	FilterPrices_ = New Structure("StandardCostEstimate, Products, Characteristic");
	
	While SelectionOfSemiFinishedProducts.Next() Do
		
		FillPropertyValues(FilterCosts_, SelectionOfSemiFinishedProducts);
		
		ResourceIndicators = New Structure;
		For Each Resource In ResourcesToCalculate Do
			ResourceIndicators.Insert(Resource.Key, 0);
		EndDo;
		
		SemiFinishedProductCosts = Costs.FindRows(FilterCosts_);
		For Each Cost_ In SemiFinishedProductCosts Do
			
			If ValueIsFilled(Cost_.Material) Then
				
				FillPropertyValues(FilterPrices_, Cost_);
				FilterPrices_.Products = Cost_.Material;
				FilterPrices_.Characteristic = Cost_.ItemVariantOfMaterial;
				
				ExternalResources = New Structure;
				For Each Resource In ResourcesToCalculate Do
					ExternalResources.Insert(Resource.Key, 0);
				EndDo;
				
				RowsWithPrices = MaterialPrices.FindRows(FilterPrices_);
				For Each PriceLine_ In RowsWithPrices Do
					For Each Resource In ResourcesToCalculate Do
						ExternalResources[Resource.Key] = ExternalResources[Resource.Key] + PriceLine_[Resource.Value];
					EndDo;
				EndDo;
				
				For Each Resource In ResourcesToCalculate Do
					ResourceIndicators[Resource.Key] = ResourceIndicators[Resource.Key] + ExternalResources[Resource.Key] * Cost_.MaterialQuantity;
				EndDo;
				
			Else
				For Each Resource In ResourcesToCalculate Do
					ResourceIndicators[Resource.Key] = ResourceIndicators[Resource.Key] + Cost_[Resource.Key];
				EndDo;
			EndIf;
			
		EndDo;
		
		FillPropertyValues(FilterPrices_, SelectionOfSemiFinishedProducts);
		If MaterialPrices.FindRows(FilterPrices_).Count() > 0 Then
			Continue;
		EndIf;

		MaterialPrice = MaterialPrices.Add();
		FillPropertyValues(MaterialPrice, SelectionOfSemiFinishedProducts);
		
		If Not SelectionOfSemiFinishedProducts.Count = 0 Then
			For Each Resource In ResourcesToCalculate Do
				MaterialPrice[Resource.Value] = ResourceIndicators[Resource.Key] 
					* SelectionOfSemiFinishedProducts.Numerator / SelectionOfSemiFinishedProducts.Denominator / SelectionOfSemiFinishedProducts.Count;
			EndDo;
		EndIf;
		
	EndDo;
	
	Query.Text =
		"SELECT
		|	T.StandardCostEstimate AS StandardCostEstimate,
		|	T.Products AS Products,
		|	T.Characteristic AS Characteristic,
		|	T.PriceCost,
		|	T.PriceValueWithoutVAT,
		|	T.PriceLocalCost,
		|	T.PriceLaborCosts,
		|	T.PriceLaborCostsLocal,
		|	T.PriceArticleByArticleConstants,
		|	T.PriceArticleByArticlePermanentWithoutVAT,
		|	T.PriceArticleByArticlePermanentLocal,
		|	T.PriceArticleByArticleVariables,
		|	T.PriceArticleByArticleVariablesWithoutVAT,
		|	T.PriceArticleByArticleVariablesLocal,
		|	T.PriceCostOffBalanceSheet,
		|	T.PriceCostOffBalanceLocal
		|INTO PreliminaryMaterialPrices
		|FROM
		|	&MaterialPrices AS T
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT
		|	T.StandardCostEstimate AS StandardCostEstimate,
		|	T.Products AS Products,
		|	T.Characteristic AS Characteristic,
		|	AVG(T.PriceCost),
		|	AVG(T.PriceValueWithoutVAT),
		|	AVG(T.PriceLocalCost),
		|	AVG(T.PriceLaborCosts),
		|	AVG(T.PriceLaborCostsLocal),
		|	AVG(T.PriceArticleByArticleConstants),
		|	AVG(T.PriceArticleByArticlePermanentWithoutVAT),
		|	AVG(T.PriceArticleByArticlePermanentLocal),
		|	AVG(T.PriceArticleByArticleVariables),
		|	AVG(T.PriceArticleByArticleVariablesWithoutVAT),
		|	AVG(T.PriceArticleByArticleVariablesLocal),
		|	AVG(T.PriceCostOffBalanceSheet),
		|	AVG(T.PriceCostOffBalanceLocal)
		|INTO MaterialPrices
		|FROM
		|	PreliminaryMaterialPrices AS T
		|
		|GROUP BY
		|	T.StandardCostEstimate,
		|	T.Products,
		|	T.Characteristic
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|DROP PreliminaryMaterialPrices";
	
	Query.SetParameter("MaterialPrices", MaterialPrices);

	SetPrivilegedMode(True);
	Query.Execute();
	SetPrivilegedMode(False);
	
EndProcedure

Procedure BringMultipliersToCommonDenominator(Multipliers)
	
	UniquenessColumns = "Period, LotProductBOM, ManufacturedProduct, ItemVariant, Purpose,
	| LotSemiFinishedProductBOM, KeyLot, SemiFinishedProduct, ItemVariantsOfIntermediateProduct,
	| Order, CalculationIsCompleted, LotIsReleased";	
	CopyMultipliers = Multipliers.Copy(, UniquenessColumns);
	
	CopyMultipliers.Columns.Add("Duplicate1");
	CopyMultipliers.FillValues(1, "Duplicate1");
	
	CopyMultipliers.GroupBy(UniquenessColumns, "Duplicate1");
	
	Multipliers.Indexes.Add(UniquenessColumns);
	SelectionOfMultipliers = New Structure(UniquenessColumns);
	
	For Each Multiplier In CopyMultipliers Do
		
		If Multiplier.Duplicate1 <= 1 Or Not Multiplier.CalculationIsCompleted Then
			Continue;
		EndIf;
		
		FillPropertyValues(SelectionOfMultipliers, Multiplier);
		MultipliersForCasting = Multipliers.FindRows(SelectionOfMultipliers);
		
		UniqueDenominators = New Map();
		ArrayOfDenominators = New Array();
		For Each MultiplierForCasting In MultipliersForCasting Do
			If UniqueDenominators[MultiplierForCasting.Denominator] = Undefined Then
				UniqueDenominators.Insert(MultiplierForCasting.Denominator, True);
				ArrayOfDenominators.Add(MultiplierForCasting.Denominator);
			EndIf;
		EndDo;
		
		NOC = ProductionServer.SmallestCommonMultiple(ArrayOfDenominators);
		
		For Each MultiplierForCasting In MultipliersForCasting Do
			MultiplierForCasting.Numerator = NOC / MultiplierForCasting.Denominator * MultiplierForCasting.Numerator;
			MultiplierForCasting.Denominator = NOC;
		EndDo;
	EndDo;
	
EndProcedure

Procedure PrepareServiceTemporaryTables(TempTableManager, StandardCostEstimate)
	
	Period = Common.ObjectAttributeValue(StandardCostEstimate, "Date");
	Query = New Query;
	Query.TempTablesManager = TempTableManager;
	
	Query.Text = 
		"SELECT
		|	ManagementAccountingCurrency.Value AS Currency,
		|	""CurrencyOfManAccounting"" AS TypeOfCurrency
		|INTO Currencies
		|FROM
		|	Constant.ManagementAccountingCurrency AS ManagementAccountingCurrency
		|
		|UNION ALL
		|
		|SELECT
		|	StandardCosting2_2.Organization.LocalAccountingCurrency AS Value,
		|	""CurrencyOfComplianceAccounting""
		|FROM
		|	Document.StandardCosting2_2 AS StandardCosting2_2
		|WHERE
		|	StandardCosting2_2.Ref = &StandardCostEstimate
		|
		|UNION ALL
		|
		|SELECT
		|	CurrencyOfActivityKindRates.Value,
		|	""CurrencyOfActivityKindRates""
		|FROM
		|	Constant.CurrencyOfActivityKindRates AS CurrencyOfActivityKindRates
		|
		|INDEX BY
		|	TypeOfCurrency,
		|	Currency
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT
		|	Currencies.Currency AS Currency,
		|	ISNULL(CurrencyRatesCut.CourseNumerator, 0) AS CourseNumerator,
		|	ISNULL(CurrencyRatesCut.CourseDenominator, 0) AS CourseDenominator,
		|	Currencies.TypeOfCurrency AS TypeOfCurrency
		|INTO ExchangeRates
		|FROM
		|	Currencies AS Currencies
		|		LEFT JOIN InformationRegister.RelativeExchangeRates.SliceLast(
		|				&Period,
		|				Currency IN
		|					(SELECT
		|						Currencies.Currency AS Currency
		|					FROM
		|						Currencies AS Currencies)
		|					AND BaseCurrency = &BaseCurrency) AS CurrencyRatesCut
		|		ON Currencies.Currency = CurrencyRatesCut.Currency
		|
		|INDEX BY
		|	TypeOfCurrency,
		|	Currency";
	
	Query.SetParameter("Period", Period);
	Query.SetParameter("StandardCostEstimate", StandardCostEstimate);
	Query.SetParameter("BaseCurrency", SettingsValueCached.CurrencyOfOrganizationSRegulatedAccounting(
					Common.ObjectAttributeValue(StandardCostEstimate, "Organization")));
	
	SetPrivilegedMode(True);
	Query.Execute();
	SetPrivilegedMode(False);
	
EndProcedure

#EndRegion

#Region ActualData

Procedure AddActualMaterialCosts(StructureOfData, CalculationParameters, TreeRow, MultiplierParent)
	NewMaterial = StructureOfData.PlannedMaterialCosts.Add();
	NewMaterial.StandardCostEstimate = CalculationParameters.StandardCostEstimate;
	NewMaterial.KeyLot = MultiplierParent.KeyLot;
	NewMaterial.Period = MultiplierParent.Period;
	NewMaterial.CostPeriod = MultiplierParent.Period;
	NewMaterial.LotBOM = ?(ValueIsFilled(MultiplierParent.LotSemiFinishedProductBOM),
		MultiplierParent.LotSemiFinishedProductBOM, MultiplierParent.LotProductBOM);
	NewMaterial.Department = TreeRow.Department;
	NewMaterial.ProductCostElement = TreeRow.ProductCostElement;
	NewMaterial.Products = TreeRow.Products;
	NewMaterial.Characteristic = TreeRow.Characteristic;
	NewMaterial.Count = TreeRow.Count;
	NewMaterial.Cost = TreeRow.Sum;
	NewMaterial.CostExcludingVAT = TreeRow.ItemizedFixedCostsExcludingVAT + TreeRow.ItemizedVariableCostsExcludingVAT
		+ TreeRow.TangibleExcludingVAT + TreeRow.AdditionalExpensesExcludingVAT + TreeRow.LaborCosts;
	NewMaterial.LocalCost = TreeRow.ItemizedFixedCostsCompl + TreeRow.ItemizedVariableCostsCompl
		+ TreeRow.TangibleCompl + TreeRow.AddExpensesLocal + TreeRow.LaborCostsLocal;
	NewMaterial.OffBalanceCost = TreeRow.OffBalanceSheetAmount;
	NewMaterial.OffBalanceCostLocal = TreeRow.OffBalanceCostLocal;
	NewMaterial.ThisIsASemiFinishedProduct = TreeRow.LineKind = Enums.KindsOfCostTreeRows.SemiFinishedProductLot;
EndProcedure

Procedure ProcessCostTreeLine(StructureOfData, CalculationParameters, DisjunctionLine, TreeRow, MultiplierParent)
	
	If TreeRow.LineKind = Enums.KindsOfCostTreeRows.ProductsBatch
		Or TreeRow.LineKind = Enums.KindsOfCostTreeRows.SemiFinishedProductLot Then
		
		NewMultiplier = ?(DisjunctionLine = Undefined,
			StructureOfData.MultiplesOfLotsAndSemiFinishedProducts.Add(),
			DisjunctionLine);
		
		NewMultiplier.Period = CalculationParameters.PCDetails.CalculationDate;
		NewMultiplier.StandardCostEstimate = CalculationParameters.StandardCostEstimate;
		
		If TreeRow.LineKind = Enums.KindsOfCostTreeRows.ProductsBatch Then
			ParentData = ?(MultiplierParent = Undefined, DisjunctionLine, MultiplierParent);
			
			NewMultiplier.ManufacturedProduct					= ParentData.ManufacturedProduct;
			NewMultiplier.ItemVariant		= ParentData.ItemVariant;
			NewMultiplier.KeyLot					= String(NewMultiplier.ItemVariant.UUID());
			NewMultiplier.Purpose					= ParentData.Purpose;
			NewMultiplier.LotProductBOM	= ParentData.LotProductBOM;
			
			NewMultiplier.QuantityOfSemiFinishedProduct	= TreeRow.Count * TreeRow.Numerator / TreeRow.Denominator;
			NewMultiplier.Numerator				= TreeRow.Numerator;
			NewMultiplier.Denominator				= TreeRow.Denominator;

		ElsIf TreeRow.LineKind = Enums.KindsOfCostTreeRows.SemiFinishedProductLot Then
			NewMultiplier.LotProductBOM	= MultiplierParent.LotProductBOM;
			NewMultiplier.ManufacturedProduct					= MultiplierParent.ManufacturedProduct;
			NewMultiplier.ItemVariant		= MultiplierParent.ItemVariant;
			NewMultiplier.Purpose					= MultiplierParent.Purpose;
			
			NewMultiplier.LotSemiFinishedProductBOM	= TreeRow.Lot;
			NewMultiplier.SemiFinishedProduct						= TreeRow.Products;
			NewMultiplier.ItemVariantsOfIntermediateProduct		= TreeRow.Characteristic;
			NewMultiplier.KeyLot						= String(NewMultiplier.ItemVariantsOfIntermediateProduct.UUID());
			
			NewMultiplier.QuantityOfSemiFinishedProduct	= TreeRow.Count;
			NewMultiplier.Numerator				= TreeRow.Numerator;
			NewMultiplier.Denominator				= TreeRow.Denominator;
			NewMultiplier.Order					= MultiplierParent.Order + 1;
		EndIf;
		
		NewMultiplier.Cost					= TreeRow.Sum;
		NewMultiplier.CostExcludingVAT				= TreeRow.ItemizedFixedCostsExcludingVAT
			+ TreeRow.ItemizedVariableCostsExcludingVAT + TreeRow.TangibleExcludingVAT
			+ TreeRow.AdditionalExpensesExcludingVAT + TreeRow.LaborCosts;
		NewMultiplier.LocalCost				= TreeRow.ItemizedFixedCostsCompl
			+ TreeRow.ItemizedVariableCostsCompl + TreeRow.TangibleCompl
			+ TreeRow.AddExpensesLocal + TreeRow.LaborCostsLocal;
			
		NewMultiplier.LaborCosts					= TreeRow.LaborCosts;
		NewMultiplier.LaborCostsLocal				= TreeRow.LaborCostsLocal;
		NewMultiplier.ItemizedFixed		= TreeRow.ItemizedFixed;
		NewMultiplier.ItemizedFixedCostsExcludingVAT	= TreeRow.ItemizedFixedCostsExcludingVAT;
		NewMultiplier.ItemizedFixedCostsCompl	= TreeRow.ItemizedFixedCostsCompl;
		NewMultiplier.ItemizedVariable		= TreeRow.ItemizedVariable;
		NewMultiplier.ItemizedVariableCostsExcludingVAT	= TreeRow.ItemizedVariableCostsExcludingVAT;
		NewMultiplier.ItemizedVariableCostsCompl	= TreeRow.ItemizedVariableCostsCompl;
		NewMultiplier.OffBalanceCost		= TreeRow.OffBalanceSheetAmount;
		NewMultiplier.OffBalanceCostLocal	= TreeRow.OffBalanceCostLocal;
		
		NewMultiplier.LotIsReleased = True;
		NewMultiplier.CalculationIsCompleted = True;
		
		If TreeRow.LineKind = Enums.KindsOfCostTreeRows.SemiFinishedProductLot
			And MultiplierParent <> Undefined Then
			// To connect the current PF with PF / manufactured products at a higher level, add tech. PF is like a checkmate. expenses.
			AddActualMaterialCosts(StructureOfData, CalculationParameters, TreeRow,
				MultiplierParent);
		EndIf;
		
		If TreeRow.ExplosionIsRequired And TreeRow.Rows.Count() > 0 Then
			For Each Page1 In TreeRow.Rows Do
				ProcessCostTreeLine(StructureOfData, CalculationParameters, Undefined,
					Page1, NewMultiplier);
			EndDo;
		EndIf;
		
	ElsIf TreeRow.LineKind = Enums.KindsOfCostTreeRows.LotCosts Then
		If TreeRow.ExpenseType = CalculationParameters.TypesOfCostsOfCostTree.TypeOfCostsMaterial Then
			AddActualMaterialCosts(StructureOfData, CalculationParameters, TreeRow,
				MultiplierParent);
			
		ElsIf TreeRow.ExpenseType = CalculationParameters.TypesOfCostsOfCostTree.TypeOfCostsArticleByArticle Then
			NewOtherExpenses = StructureOfData.PlannedOtherCosts.Add();
			NewOtherExpenses.StandardCostEstimate = CalculationParameters.StandardCostEstimate;
			NewOtherExpenses.Period = CalculationParameters.PCDetails.CalculationDate;
			NewOtherExpenses.LotBOM = ?(ValueIsFilled(MultiplierParent.LotSemiFinishedProductBOM),
				MultiplierParent.LotSemiFinishedProductBOM,
				MultiplierParent.LotProductBOM);
			NewOtherExpenses.Department = TreeRow.Department;
			NewOtherExpenses.ProductCostElement = TreeRow.ProductCostElement;
			NewOtherExpenses.ExpenseItem = TreeRow.Products;
			NewOtherExpenses.KeyLot = MultiplierParent.KeyLot;
			
			NewOtherExpenses.Cost = TreeRow.Sum;
			NewOtherExpenses.CostExcludingVAT = TreeRow.ItemizedFixedCostsExcludingVAT
				+ TreeRow.ItemizedVariableCostsExcludingVAT;
			NewOtherExpenses.LocalCost = TreeRow.ItemizedFixedCostsCompl
				+ TreeRow.ItemizedVariableCostsCompl;
			
		ElsIf TreeRow.ExpenseType = CalculationParameters.TypesOfCostsOfCostTree.CostTypeLaborCosts Then
			NewLaborCosts = StructureOfData.PlannedLaborCosts.Add();
			NewLaborCosts.StandardCostEstimate = CalculationParameters.StandardCostEstimate;
			NewLaborCosts.Period = MultiplierParent.Period;
			NewLaborCosts.CostPeriod = MultiplierParent.Period;
			NewLaborCosts.LotBOM = ?(ValueIsFilled(MultiplierParent.LotSemiFinishedProductBOM),
				MultiplierParent.LotSemiFinishedProductBOM,
				MultiplierParent.LotProductBOM);
			NewLaborCosts.Department = TreeRow.Department;
			NewLaborCosts.ProductCostElement = TreeRow.ProductCostElement;
			NewLaborCosts.WorkKind = TreeRow.Products;
			NewLaborCosts.KeyLot = MultiplierParent.KeyLot;
			NewLaborCosts.Count = TreeRow.Count;
			NewLaborCosts.Cost = TreeRow.Sum;
			NewLaborCosts.LocalCost = TreeRow.LaborCostsLocal;
		EndIf;
	EndIf;
	
EndProcedure

Procedure CalculateMultipliersFromActualData(StructureOfData, CalculationParameters)

	Filter = New Structure("LotIsReleased", True);
	LinesToUnify = StructureOfData.MultiplesOfLotsAndSemiFinishedProducts.FindRows(Filter);
	If LinesToUnify.Count() = 0 Then
		// Comment 5263
		// During the formation of multipliers on the cost tree, it is not known how many of each Lot reference total will be taken PF.
		// For the correct calculation of expenses, it is necessary to recalculate the common denominators.
		// Since the uncoupling up to this point works for this recalculation,
		// we re-calculate regardless of whether there is a need for tree uncoupling or not.
		// There is a condition - if there is a tree split, the recalculation should work after the tree split.
		RecalculateDenominators(CalculationParameters, StructureOfData);
		Return;
	EndIf;
	
	Query = New Query();
	Query.TempTablesManager = New TempTablesManager();

	GroupingColumns = CalculationParameters.Multipliers_GroupingColumnsWithoutPriority;
	CostCalculationAppliedAlgorithms.PutTableOfValuesInTemporaryTable(Query.TempTablesManager,
		"TTMultipliers", StructureOfData.MultiplesOfLotsAndSemiFinishedProducts.Copy(LinesToUnify),
		GroupingColumns + ", "+ CalculationParameters.Multipliers_SummationColumns,
		"CalculationIsCompleted,LotIsReleased");
		
	Filter = New Structure("LotIsReleased", False);
	LinesThatDoNotRequireUndifferentiation = StructureOfData.MultiplesOfLotsAndSemiFinishedProducts.FindRows(Filter);
	StructureOfData.MultiplesOfLotsAndSemiFinishedProducts = StructureOfData.MultiplesOfLotsAndSemiFinishedProducts.Copy(
		LinesThatDoNotRequireUndifferentiation);
		
	Query.Text = "
		|SELECT
		|	TTMultipliers.Period AS Period,
		|	TTMultipliers.StandardCostEstimate AS StandardCostEstimate,
		|	TTMultipliers.LotProductBOM AS LotProductBOM,
		|	TTMultipliers.ManufacturedProduct AS ManufacturedProduct,
		|	TTMultipliers.ItemVariant AS ItemVariant,
		|	TTMultipliers.Purpose AS Purpose,
		|	ISNULL(ProcessorReports2_5.Ref, TTMultipliers.LotSemiFinishedProductBOM) AS LotSemiFinishedProductBOM,
		|	TTMultipliers.KeyLot AS KeyLot,
		|	TTMultipliers.SemiFinishedProduct AS SemiFinishedProduct,
		|	TTMultipliers.ItemVariantsOfIntermediateProduct AS ItemVariantsOfIntermediateProduct,
		|	TTMultipliers.Order AS Order,
		|	TTMultipliers.Denominator AS Denominator,
		|	TTMultipliers.CalculationIsCompleted AS CalculationIsCompleted,
		|	TTMultipliers.LotIsReleased AS LotIsReleased,
		|	TTMultipliers.Numerator AS Numerator,
		|	TTMultipliers.QuantityOfSemiFinishedProduct AS QuantityOfSemiFinishedProduct,
		|	TTMultipliers.Cost AS Cost,
		|	TTMultipliers.CostExcludingVAT AS CostExcludingVAT,
		|	TTMultipliers.LocalCost AS LocalCost,
		|	TTMultipliers.LaborCosts AS LaborCosts,
		|	TTMultipliers.LaborCostsLocal AS LaborCostsLocal,
		|	TTMultipliers.ItemizedFixed AS ItemizedFixed,
		|	TTMultipliers.ItemizedFixedCostsExcludingVAT AS ItemizedFixedCostsExcludingVAT,
		|	TTMultipliers.ItemizedFixedCostsCompl AS ItemizedFixedCostsCompl,
		|	TTMultipliers.ItemizedVariable AS ItemizedVariable,
		|	TTMultipliers.ItemizedVariableCostsExcludingVAT AS ItemizedVariableCostsExcludingVAT,
		|	TTMultipliers.ItemizedVariableCostsCompl AS ItemizedVariableCostsCompl,
		|	TTMultipliers.OffBalanceCost AS OffBalanceCost,
		|	TTMultipliers.OffBalanceCostLocal AS OffBalanceCostLocal
		|FROM
		|	TTMultipliers AS TTMultipliers
		|		LEFT JOIN Document.ProductionStage2_2 AS DocProductionStage
		|		ON (TTMultipliers.LotSemiFinishedProductBOM = DocProductionStage.Ref)
		|			AND (DocProductionStage.ProductionByThirdParty2_5)
		|		LEFT JOIN Document.SubcontractorReport2_5.ManufacturedProducts AS ProcessorReports2_5
		|		ON (ProcessorReports2_5.ProductionStage = DocProductionStage.Ref)
		|			AND (NOT ProcessorReports2_5.ToExpenseAs)
		|
		|";
	
	SelectionOfSemiFinishedProducts_1 = New Structure("ProductsBatch, ManufacturedProduct, ItemVariant, ExplosionIsRequired");
	SelectionOfSemiFinishedProducts_1.ExplosionIsRequired = True;
	
	QueryResult = Query.Execute().Select();
	
	CalculationParameters.Insert("TypesOfCostsOfCostTree", CostStructure.TypesOfCostsOfCostTree());
	
	TreeParameters = CostStructure.CostTreeParameters();
	TreeParameters.DynamicReading = False;
	TreeParameters.ResultTypeValueTree = True;
	TreeParameters.InteractiveSetup = False;
	
	CostStructure.FillInParametersOfCostTree(TreeParameters);
	MapOfNodes = New Map();
	
	While QueryResult.Next() Do
		
		NewNodeId = String(New UUID());
		MultiplierCurrent = StructureOfData.MultiplesOfLotsAndSemiFinishedProducts.Add();
		FillPropertyValues(MultiplierCurrent, QueryResult);
		
		MapOfNodes.Insert(NewNodeId, MultiplierCurrent);
		
		NewSelectionLine = TreeParameters.NodeSelectionTable.Add();
		NewSelectionLine.NodeID = NewNodeId;
		NewSelectionLine.IdOfFirstLevelNode = NewSelectionLine.NodeID;
		NewSelectionLine.Level = TreeParameters.NodeLevel;
		
		If ValueIsFilled(QueryResult.SemiFinishedProduct) Then
			NewSelectionLine.ManufacturedProduct = QueryResult.SemiFinishedProduct;
			NewSelectionLine.ItemVariant = QueryResult.ItemVariantsOfIntermediateProduct;
			NewSelectionLine.ProductsBatch = QueryResult.LotSemiFinishedProductBOM;
		Else
			NewSelectionLine.ManufacturedProduct = QueryResult.ManufacturedProduct;
			NewSelectionLine.ItemVariant = QueryResult.ItemVariant;
			NewSelectionLine.ProductsBatch = QueryResult.LotProductBOM;
			NewSelectionLine.AssignmentOfProducts = QueryResult.Purpose;
		EndIf;
		
		NewSelectionLine.NodeOfFirstLevel_LotReferenceOfManufacturedProducts = NewSelectionLine.ProductsBatch;
		NewSelectionLine.ForAllSeries = True;
		NewSelectionLine.AccordingToAllPartyAnalysts = True;
		
		NewSelectionLine.Numerator = QueryResult.Numerator;
		// For correct calculation, the denominator should be calculated only on the lines where the batch is released = The truth!
		NewSelectionLine.Denominator = QueryResult.Denominator;
		NewSelectionLine.ProductsQuantity = QueryResult.QuantityOfSemiFinishedProduct;
	EndDo;
	
	CostStructure.BuildCostTree(TreeParameters);
	
	If TreeParameters.Result = Undefined Then
		Raise NStr("ru = 'При расчете множителей по фактическим данным, не были получены данные разузлования дерева себестоимости.';
					|vi = 'When calculating multipliers based on the actual data, the cost tree explosion data was not obtained.';
					|en = 'When calculating multipliers based on the actual data, the cost tree explosion data was not obtained.'; fa = 'When calculating multipliers based on the actual data, the cost tree explosion data was not obtained.';
					|it = 'When calculating multipliers based on the actual data, the cost tree explosion data was not obtained.';
					|pl = 'When calculating multipliers based on the actual data, the cost tree explosion data was not obtained.';
					|tr = 'Gerçek verilere göre çarpanlar hesaplanırken maliyet ağacı ayrıştırma verileri alınamadı.'");
	EndIf;
	
	// Comment 5594.
	// Within one stage, at one point in time, there may be a release of 2 or more identical products,
	// so it is necessary to keep track of whether the multiplier line has already been processed,
	// and if it has already been processed, add another one by copying the first one.
	ProcessedFirstLevelIdentifiers = New Array();
	For Each FirstLevelTreeString In TreeParameters.Result.Rows Do
		MultiplierCurrent = MapOfNodes[FirstLevelTreeString.IdOfFirstLevelNode];
		If ProcessedFirstLevelIdentifiers.Find(
			FirstLevelTreeString.IdOfFirstLevelNode) = Undefined Then
			ProcessedFirstLevelIdentifiers.Add(FirstLevelTreeString.IdOfFirstLevelNode);
		Else
			NewMultiplier = StructureOfData.MultiplesOfLotsAndSemiFinishedProducts.Add();
			FillPropertyValues(NewMultiplier, MultiplierCurrent);
			MultiplierCurrent = NewMultiplier;
		EndIf;
		ProcessCostTreeLine(StructureOfData, CalculationParameters, MultiplierCurrent,
				FirstLevelTreeString, Undefined);
	EndDo;
	
	// see comment 5263
	RecalculateDenominators(CalculationParameters, StructureOfData);
	
	BringMultipliersToCommonDenominator(StructureOfData.MultiplesOfLotsAndSemiFinishedProducts);
	CollapseMultipliersWithinVT(StructureOfData.MultiplesOfLotsAndSemiFinishedProducts, CalculationParameters);
	CollapseRegistersOfExpensesWithinFrameworkOfVT(CalculationParameters, StructureOfData);
	
EndProcedure

#EndRegion

#Region Validation

Procedure AddCalculationToValidation(StandardCostEstimate, ArrayOfCalculations)
	
	If ArrayOfCalculations = Undefined Then
		ArrayOfCalculations = New Array;
	EndIf;
	
	If ThereWasCancellationOfEvent(StandardCostEstimate) Then
		Return;
	EndIf;
	
	#Region ThereWasPCCalculationError
	Query = New Query();
	Query.Text = "
	|SELECT TOP 1
	|	DD.StandardCostEstimate
	|FROM InformationRegister.StatesOfStandardCostEstimates AS DD
	|WHERE
	|	DD.StandardCostEstimate = &StandardCostEstimate
	|	AND DD.State = VALUE(Enum.StatesOfStandardCostEstimateCalculation.CalculationError)";
	Query.SetParameter("StandardCostEstimate", StandardCostEstimate);
	QueryResult = Query.Execute();
	If Not QueryResult.IsEmpty() Then
		Return;
	EndIf;
	#EndRegion
	
	If ArrayOfCalculations.Find(StandardCostEstimate) = Undefined Then
		ArrayOfCalculations.Add(StandardCostEstimate);
	EndIf;
	
EndProcedure

Procedure CheckCost(Calculations_)
	
	Validation = AuditOfSystemState.FindValidationByKeyFields(Documents.StandardCosting2_2.EmptyRef(), "ZeroCostRegisteredRecords");
	
	If Not ValueIsFilled(Validation) Then
		Raise NStr("vi = 'Chưa tìm thấy việc kiểm tra ngữ cảnh hệ thống cho giao dịch ""Tính giá thành sản phẩm""';
					|ru = 'Не найдена служебная контекстная проверка для операции ""Калькуляция продукциии""';
					|en = 'Service context check for the ""Product costing"" operation was not found'; fa = 'Service context check for the ""Product costing"" operation was not found';
					|it = 'Nessun controllo contestuale di servizio trovato per l''operazione ""Calcolo prodotti""';
					|pl = 'Nie znaleziono serwisowe sprawdzenie kontekstu dla operacji ""Kalkulacja  produkcji""';
					|tr = '""Ürün maliyetlendirme"" işlemi için hizmet bağlamında kontrol bulunamadı'");
	EndIf;
	
	AddlParameters = New Structure;
	AddlParameters.Insert("Calculations_", Calculations_);
	
	SetPrivilegedMode(True);
	CheckParameters = AuditOfSystemState.CheckSystemState(Validation, AddlParameters);
	SetPrivilegedMode(False);
	
	CalculationsWithCalculationErrors = CheckParameters.AdditionalParameters.CalculationsWithCalculationErrors;
	
	For Each StandardCostEstimate In Calculations_ Do
		
		If Not CalculationsWithCalculationErrors.Find(StandardCostEstimate) = Undefined Then
			Continue;
		EndIf;
		
		RecordStateOfCalculation(StandardCostEstimate, 
			Enums.StatesOfStandardCostEstimateCalculation.Calculated);
		
	EndDo;
	
	If CalculationsWithCalculationErrors.Count() > 0 Then
		UpdateStateOfCalculations(CalculationsWithCalculationErrors);
	EndIf;
	
EndProcedure

#EndRegion

#Region Other

Function GetCostPeriod(PeriodCalculationParameters)
	
	CostPeriod = BegOfDay(PeriodCalculationParameters.Period);
	StagePosition = 0;
	Counter = 0;
	
	CurrentStageLine = PeriodCalculationParameters.Stages.Find(PeriodCalculationParameters.CurrentStep, "Stage");
	If CurrentStageLine <> Undefined Then
		StagePosition = PeriodCalculationParameters.Stages.IndexOf(CurrentStageLine);
	EndIf;
	
	While Counter < StagePosition Do
		
		CostPeriod = CostPeriod + PeriodCalculationParameters.DurationOfStages[Counter] * 86400;
		Counter = Counter + 1;
		
	EndDo;
	
	Return BegOfMonth(CostPeriod);
	
EndFunction

Function PeriodCalculationParameters()
	
	Parameters = New Structure;
	Parameters.Insert("Period", Date(1, 1, 1));
	Parameters.Insert("Stages");
	Parameters.Insert("CurrentStep");
	Parameters.Insert("DurationOfStages");
	
	Return Parameters;
	
EndFunction

#EndRegion

#Region InfobaseUpdate

// See InfobaseUpdateSSL.OnAddUpdateHandlers
Procedure OnAddUpdateHandlers(Handlers) Export

	Handler = Handlers.Add();
	Handler.Procedure = "InformationRegisters.MultiplesOfLotsAndSemiFinishedProducts.ProcessDataForMigrationToNewVersion";
	Handler.Version = "2.5.26.24";
	Handler.ExecutionMode = "Deferred";
	Handler.Id = New UUID("941997c3-10d2-4efa-abdf-3e3df95f61c7");
	Handler.Multithreaded = True;
	Handler.UpdateDataFillingProcedure = "InformationRegisters.MultiplesOfLotsAndSemiFinishedProducts.RegisterDataToProcessForMigrationToNewVersion";
	Handler.CheckProcedure = "InfobaseUpdate.DataUpdatedForNewApplicationVersion";
	Handler.Order = Enums.OrderOfUpdateHandlers.Normal;
	Handler.Comment = NStr("vi = 'Chuyển đổi kiểu cột ""Khóa lô hàng"" trong biểu ghi thông tin ""Hệ số lô hàng và bán thành phẩm"".';
							|ru = 'Конвертация типа колонки ""Ключ партия"" регистра сведений ""Множители партий и полуфабрикатов"".';
							|en = 'Conversion of the ""Key lot"" column type of the ""Multiples of lots and semi-finished products"" information register.'; fa = 'Conversion of the ""Key lot"" column type of the ""Multiples of lots and semi-finished products"" information register.';
							|it = 'Conversion of the ""Key lot"" column type of the ""Multiples of lots and semi-finished products"" information register.';
							|pl = 'Conversion of the ""Key lot"" column type of the ""Multiples of lots and semi-finished products"" information register.';
							|tr = '""Lot ve yarı mamul ürünlerin çarpanları"" bilgi kayıt tablosunun ""Anahtar Lot"" sütun tipinin dönüştürülmesi.'");
	
	ItemsToRead = New Array;
	ItemsToRead.Add(Metadata.InformationRegisters.MultiplesOfLotsAndSemiFinishedProducts.FullName());
	Handler.ObjectsToRead = StrConcat(ItemsToRead, ",");
	
	Editable1 = New Array;
	Editable1.Add(Metadata.InformationRegisters.MultiplesOfLotsAndSemiFinishedProducts.FullName());
	Handler.ObjectsToChange = StrConcat(Editable1, ",");
	
	ToLock = New Array;
	ToLock.Add(Metadata.InformationRegisters.MultiplesOfLotsAndSemiFinishedProducts.FullName());
	Handler.ObjectsToLock = StrConcat(ToLock, ",");
	
	Handler.ExecutionPriorities = InfobaseUpdate.HandlerExecutionPriorities();

	NewRow = Handler.ExecutionPriorities.Add();
	NewRow.Procedure = "InformationRegisters.MultiplesOfLotsAndSemiFinishedProducts.ProcessDataForMigrationToNewVersion";
	NewRow.Order = "After";
	
EndProcedure

// Parameters:
// 	Parameters - See InfobaseUpdate.MainProcessingMarkParameters
//
Procedure RegisterDataToProcessForMigrationToNewVersion(Parameters) Export
	
	FullRegisterName = "InformationRegister.MultiplesOfLotsAndSemiFinishedProducts";
	
	SelectionParameters = Parameters.SelectionParameters;
	SelectionParameters.FullRegistersNames = FullRegisterName;
	SelectionParameters.OrderingFieldsOnUserOperations.Add("Period DESC");
	SelectionParameters.OrderingFieldsOnProcessData.Add("Period DESC");
	SelectionParameters.SelectionMethod = InfobaseUpdate.SelectionMethodOfIndependentInfoRegistryMeasurements();
	
	AdditionalParameters = InfobaseUpdate.AdditionalProcessingMarkParameters();
	AdditionalParameters.Insert("IsIndependentInformationRegister", True);
	AdditionalParameters.Insert("FullRegisterName", FullRegisterName);
	
	QueryText = "SELECT DISTINCT
	|	MultiplesOfLotsAndSemiFinishedProducts.StandardCostEstimate AS StandardCostEstimate
	|FROM
	|	InformationRegister.MultiplesOfLotsAndSemiFinishedProducts AS MultiplesOfLotsAndSemiFinishedProducts
	|
	|WHERE
	// It makes sense to convert column values only for those documents that have the Keyparty value filled in at least one line.
	|	MultiplesOfLotsAndSemiFinishedProducts.DeleteKeyLot IS NOT NULL
	|	AND MultiplesOfLotsAndSemiFinishedProducts.DeleteKeyLot <> &EmptyUID";
	
	Query = New Query(QueryText);
	Query.SetParameter("EmptyUID", CommonClientServer.BlankUUID());
	
	InfobaseUpdate.MarkForProcessing(
		Parameters,
		Query.Execute().Unload(),
		AdditionalParameters);
	
EndProcedure

// An update handler.
// 
// Parameters:
//  Parameters - Structure - parameters.
//
Procedure ProcessDataForMigrationToNewVersion(Parameters) Export
	
	FullRegisterName = "InformationRegister.MultiplesOfLotsAndSemiFinishedProducts";
	
	UpdatedData = InfobaseUpdate.DataToUpdateInMultithreadHandler(Parameters);
	
	If UpdatedData.Count() = 0 Then
		Parameters.ProcessingCompleted = InfobaseUpdate.DataProcessingCompleted(Parameters.Queue, FullRegisterName);
		Return;
	EndIf;
	
	For Each Selection In UpdatedData Do
		
		BeginTransaction();
		
		Try
			
			DataLock = New DataLock;
			
			LockItem = DataLock.Add("InformationRegister.MultiplesOfLotsAndSemiFinishedProducts");
			LockItem.SetValue("StandardCostEstimate", Selection.StandardCostEstimate);
			LockItem.Mode = DataLockMode.Exclusive;
			DataLock.Lock();
			
			RecordSet = InformationRegisters.MultiplesOfLotsAndSemiFinishedProducts.CreateRecordSet();
			RecordSet.Filter.StandardCostEstimate.Set(Selection.StandardCostEstimate);
			RecordSet.Read();
			
			For Each Record In RecordSet Do
				Record.KeyLot = String(Record.DeleteKeyLot);
			EndDo;
			
			InfobaseUpdate.WriteRecordSet(RecordSet);
			
			CommitTransaction();
			
		Except
			
			RollbackTransaction();
			
			MessageText = StrTemplate(
					NStr("vi = 'Không thể ghi dữ liệu vào biểu ghi ""Hệ số lô hàng và bán thành phẩm"" theo giá thành dự tính ""%1"", do nguyên nhân: %2';
						|ru = 'Не удалось записать данные в регистр ""Множители партий и полуфабрикатов"" по плановой калькуляции ""%1"", по причине: %2';
						|en = 'Cannot write data to the ""Multiples of lots and semi-finished products"" information register based on the ""%1"" product standard cost. Reason: %2'; fa = 'Cannot write data to the ""Multiples of lots and semi-finished products"" information register based on the ""%1"" product standard cost. Reason: %2';
						|it = 'Cannot write data to the ""Multiples of lots and semi-finished products"" information register based on the ""%1"" product standard cost. Reason: %2';
						|pl = 'Cannot write data to the ""Multiples of lots and semi-finished products"" information register based on the ""%1"" product standard cost. Reason: %2';
						|tr = '""%1"" standart ürün maliyeti için ""Lot ve yarı mamul ürünlerin çarpanları"" kaydına şu nedenden dolayı veri yazılamadı: %2'"),
					Selection.StandardCostEstimate,
					ErrorProcessing.DetailErrorDescription(ErrorInfo()));
			
			WriteLogEvent(
				InfobaseUpdate.EventLogEvent(),
				EventLogLevel.Warning,
				Metadata.InformationRegisters.MultiplesOfLotsAndSemiFinishedProducts,,
				MessageText);
			
		EndTry;
		
	EndDo;
	
	Parameters.ProcessingCompleted = Not InfobaseUpdate.HasDataToProcess(
		Parameters.Queue,
		FullRegisterName);
	
EndProcedure

#EndRegion

#EndRegion

#EndIf
