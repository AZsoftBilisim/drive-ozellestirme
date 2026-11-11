#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region EventHandlers

Procedure BeforeWrite(Cancel, Replacing)
	
	If DataExchange.Load Then
		Return;
	EndIf;
	
	// In the "New calculation" mode, manual adjustments are canceled in batch mode before starting the calculation
	If Not AdditionalProperties.Property("SettlementMode")
		Or AdditionalProperties.SettlementMode = CalculationOfProductionPlan.RecalculationMode() Then
		
		TempTablesManager = New TempTablesManager();
		AdditionalProperties.Insert("TempTablesManager", TempTablesManager);
		
		Query = New Query(
		"SELECT
		|	RegisterRecords.Period AS Period,
		|	RegisterRecords.Scenario AS Scenario,
		|	RegisterRecords.Products AS Products,
		|	RegisterRecords.Characteristic AS Characteristic,
		|	RegisterRecords.Department AS Department,
		|	RegisterRecords.ProductionPlan AS ProductionPlan,
		|	RegisterRecords.BillOfMaterials AS BillOfMaterials,
		|	RegisterRecords.Purpose AS Purpose,
		|	RegisterRecords.ProductionIssueDateOfIntermediateProducts AS ProductionIssueDateOfIntermediateProducts,
		|	RegisterRecords.DateOfOrderReleaseAndProductionIssue AS DateOfOrderReleaseAndProductionIssue,
		|	RegisterRecords.ThisIsASemiFinishedProduct AS ThisIsASemiFinishedProduct,
		|	RegisterRecords.ToPlan AS ToPlan,
		|	RegisterRecords.ProductionProcessType AS ProductionProcessType,
		|	RegisterRecords.Count AS Count,
		|	RegisterRecords.ToOrder AS ToOrder,
		|	RegisterRecords.ManualAdjustment AS ManualAdjustment,
		|	RegisterRecords.AdjustmentDate AS AdjustmentDate,
		|	RegisterRecords.AdjustmentAuthor AS AdjustmentAuthor,
		|	RegisterRecords.Comment AS Comment
		|INTO ListOfAdjustmentsBeforeWrite
		|FROM
		|	AccumulationRegister.ProductionPlans AS RegisterRecords
		|WHERE
		|	RegisterRecords.Recorder = &Recorder
		|	AND RegisterRecords.ManualAdjustment
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT TOP 1
		|	TRUE
		|FROM
		|	ListOfAdjustmentsBeforeWrite AS ListOfAdjustmentsBeforeWrite");
	
		Query.TempTablesManager = TempTablesManager;
		Query.SetParameter("Recorder", Filter.Recorder.Value);
		
		QueryResult = Query.ExecuteBatch();  
		Selection = QueryResult[0].Select();
		Selection.Next();
		
		AdditionalProperties.Insert("ThereAreAdjustingEntries", Selection.Count > 0);
		
	EndIf;
EndProcedure

Procedure OnWrite(Cancel, Replacing)
	
	If DataExchange.Load Then
		Return;
	EndIf;
	
	// Information about canceled manual adjustments is saved
	If AdditionalProperties.Property("ThereAreAdjustingEntries") And AdditionalProperties.ThereAreAdjustingEntries Then
		
		AccumulationRegisters.ProductionPlans.SaveManualAdjustmentsWhenRecording(Filter.Recorder.Value, AdditionalProperties.TempTablesManager);
		
	EndIf;
	
	RegistrarsData = Unload(, "Recorder, Scenario");
	RegistrarsData.GroupBy("Recorder, Scenario");
	YouNeedToRunTask = False;
	For Each DataString1 In RegistrarsData Do
		If TypeOf(DataString1.Recorder) = Type("DocumentRef.RegisterProductionPlan")
			And ValueIsFilled(Common.ObjectAttributeValue(DataString1.Scenario, "BudgetingScenario")) Then
			InformationRegisters.JobsForPostingPlanningDocumentsInBudgeting.AddJob(DataString1.Recorder);
			YouNeedToRunTask = True;
		EndIf;
	EndDo;
	If YouNeedToRunTask Then
		InformationRegisters.JobsForPostingPlanningDocumentsInBudgeting.RunJob();
	EndIf;
	
EndProcedure

#EndRegion

#EndIf
