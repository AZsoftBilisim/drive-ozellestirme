///////////////////////////////////////////////////////////////////////////////////////////////////////
// Copyright (c) 2018, 1C-Soft LLC
// All rights reserved. This program and accompanying materials are provided 
// in accordance with the terms of the Attribution 4.0 International (CC BY 4.0) license
// The license text is available at the link:
// https://creativecommons.org/licenses/by/4.0/legalcode
///////////////////////////////////////////////////////////////////////////////////////////////////////
//

#Region Public

// Generates a list of queue task templates.
// @skip-warning EmptyMethod - Overridable method.
//
// Parameters:
//  JobTemplates - Array of String - Add the names of predefined
//   undivided routine tasks to the parameter, which should be used as
//   templates for queue tasks.
//
Procedure OnGetTemplateList(JobTemplates) Export
	
	//BPO
	PELSubsystemsIntegration.OnGetTemplateList(JobTemplates);
	//End BPO
	
	JobTemplates.Add(Metadata.ScheduledJobs.ABCInventoryClassification.Name);
	JobTemplates.Add(Metadata.ScheduledJobs.ABCPartnerClassification.Name);
	JobTemplates.Add(Metadata.ScheduledJobs.XYZInventoryClassification.Name);
	JobTemplates.Add(Metadata.ScheduledJobs.XYZPartnerClassification.Name);
	JobTemplates.Add(Metadata.ScheduledJobs.UpdateDataOnGoodsAvailabilityForExternalUsers.Name);
	JobTemplates.Add(Metadata.ScheduledJobs.UpdateItemsSoldTogether.Name);
	JobTemplates.Add(Metadata.ScheduledJobs.AdjustmentOfMeasuringGoodsOrderRows.Name);
	JobTemplates.Add(Metadata.ScheduledJobs.ActualizationDemandsAlongSupplyBorder.Name);
	JobTemplates.Add(Metadata.ScheduledJobs.DeferredPostingOfBudgetEntryForms.Name);
	JobTemplates.Add(Metadata.ScheduledJobs.DocumentPostingInBudgeting.Name);
	JobTemplates.Add(Metadata.ScheduledJobs.PostingToPartnersARAPAccounting.Name);
	JobTemplates.Add(Metadata.ScheduledJobs.ExchangeDifferenceCalculation.Name);
	JobTemplates.Add(Metadata.ScheduledJobs.CalculationOfAnalysisOptionDataSources.Name);
	JobTemplates.Add(Metadata.ScheduledJobs.CalculationOfStockReplenishmentRecommendations.Name);
	JobTemplates.Add(Metadata.ScheduledJobs.CalculationOfCost.Name);
	JobTemplates.Add(Metadata.ScheduledJobs.DeleteInteractionsRelatedToMailoutsAndNotifications.Name);
	JobTemplates.Add(Metadata.ScheduledJobs.UpdatePeripheralsGoodsCodes.Name);
	JobTemplates.Add(Metadata.ScheduledJobs.SegmentClearance.Name);
	JobTemplates.Add(Metadata.ScheduledJobs.GenerateNotificationsForBudgetTasks.Name);
	JobTemplates.Add(Metadata.ScheduledJobs.CalculateProductionOrderStructure.Name);
	JobTemplates.Add(Metadata.ScheduledJobs.RollUpRecordOrderStructureRegister.Name);
	JobTemplates.Add(Metadata.ScheduledJobs.ClearLoadHistoryOfWorkCenterTypes.Name);
	JobTemplates.Add(Metadata.ScheduledJobs.MessageGenerationByCustomerNotifications.Name);
	JobTemplates.Add(Metadata.ScheduledJobs.MessageGenerationForCustomerMailouts.Name);
	JobTemplates.Add(Metadata.ScheduledJobs.CompanySafeStockRollup.Name);
	JobTemplates.Add(Metadata.ScheduledJobs.ExecuteDeferredJobs.Name);
	JobTemplates.Add(Metadata.ScheduledJobs.UserNotificationsOfEvents.Name);
	JobTemplates.Add(Metadata.ScheduledJobs.BotsProcessing.Name);
	JobTemplates.Add(Metadata.ScheduledJobs.BackdateJobQueueExecution.Name);
	JobTemplates.Add(Metadata.ScheduledJobs.UpdateMonthEndClosingState.Name);
	FinancialAccountingOfGeneralPurpose.OnGetTemplateList(JobTemplates);
	
	JobsQueueLocalization.OnGetTemplateList(JobTemplates);
EndProcedure

// Fills in the matching of method names to their aliases for calling from the task queue.
// @skip-warning EmptyMethod - Overridable method.
//
// Parameters:
//  NamesAndAliasesMap - Map of KeyAndValue:
//    * Key - String - the alias of the method, for example, "Clear the data area".
//    * Value - String - The name of the method to call, for example, "Running the Service model.Purify the Data domain."
//        You can specify an Undefined value as a value. In this case, it is assumed that the name 
//        matches the alias.
//
Procedure OnDefineHandlerAliases(NamesAndAliasesMap) Export
	
	//BPO
	PELSubsystemsIntegration.OnDefineHandlerAliases(NamesAndAliasesMap);
	//End BPO
	
	NamesAndAliasesMap.Insert(Metadata.ScheduledJobs.SegmentGeneration.MethodName);
	NamesAndAliasesMap.Insert(Metadata.ScheduledJobs.DataAnalysisForNotificationsToCustomers.MethodName);
	NamesAndAliasesMap.Insert(Metadata.ScheduledJobs.AutomaticAccrueAndDeductionOfBonusPoints.MethodName);
	NamesAndAliasesMap.Insert(Metadata.ScheduledJobs.CalculationOfPackageConsumptionForecast.MethodName);
	NamesAndAliasesMap.Insert(Metadata.ScheduledJobs.CreateTransferJobs.MethodName);
	NamesAndAliasesMap.Insert(Metadata.ScheduledJobs.CreatePickingJobs.MethodName);
	NamesAndAliasesMap.Insert(Metadata.ScheduledJobs.CreateGoodsRecountJobs.MethodName);
	NamesAndAliasesMap.Insert(Metadata.ScheduledJobs.CompanySafeStockRollup.MethodName);
	NamesAndAliasesMap.Insert(Metadata.ScheduledJobs.ActualizationDemandsAlongSupplyBorder.MethodName);
	NamesAndAliasesMap.Insert("DataExchangeServer.ExecuteDataExchangeForInfobaseNode");
	NamesAndAliasesMap.Insert(Metadata.ScheduledJobs.GenerateNotificationsForBudgetTasks.MethodName);
	NamesAndAliasesMap.Insert(Metadata.ScheduledJobs.BudgetTasksGeneration.MethodName);
	NamesAndAliasesMap.Insert(Metadata.ScheduledJobs.RollUpRecordOrderStructureRegister.MethodName);
	NamesAndAliasesMap.Insert(Metadata.ScheduledJobs.ClearLoadHistoryOfWorkCenterTypes.MethodName);
	NamesAndAliasesMap.Insert(Metadata.ScheduledJobs.CompanySafeStockRollup.MethodName);
	NamesAndAliasesMap.Insert(Metadata.ScheduledJobs.MonthEndTransactions.MethodName);
	NamesAndAliasesMap.Insert(Metadata.ScheduledJobs.ExecuteDeferredJobs.MethodName);
	NamesAndAliasesMap.Insert(Metadata.ScheduledJobs.BackdateJobQueueExecution.MethodName);
	NamesAndAliasesMap.Insert(Metadata.ScheduledJobs.UpdateMonthEndClosingState.MethodName);
	
	NamesAndAliasesMap.Insert(Metadata.ScheduledJobs.DeleteDuplicatesOfDocumentRegistryKeys.MethodName);
	
	SettingPricesServer.OnDefineHandlerAliases(NamesAndAliasesMap);
	BonusPointsServer.OnDefineHandlerAliases(NamesAndAliasesMap);
	
	
	JobsQueueLocalization.OnDefineHandlerAliases(NamesAndAliasesMap);
	// LoyaltyServer
	NamesAndAliasesMap.Insert(Metadata.ScheduledJobs.ProcessStateOfBonusPointsAndGiftCardsLoyaltyServer.MethodName);
	// End LoyaltyServer
	
	// IntegrationWith1CDocumentManagementSubsystem
	IntegrationWith1CDocumentManagementCore.OnDefineHandlerAliases(NamesAndAliasesMap);
	// End IntegrationWith1CDocumentManagementSubsystem
	
EndProcedure

// Fills in the correspondence of error handler methods to the aliases of the methods
// in which they are called when errors occur.
// @skip-warning EmptyMethod - Overridable method.
//
// Parameters:
//  ErrorHandlers - Map of KeyAndValue:
//    * Key - String - alias of the method, such as clear data Area.
//    * Value - String - Name of the error handler method to call when an error occurs. 
//        the error handler is called if the initial task
//        Ends with an error. The error handler is called in the same data area as the original job.
//        The error handler method is considered allowed to be called by the queue mechanisms.
//        Error Handler Parameters:
//          Task parameters - Structure - queue task parameters.
//          Parameters
//          Test numbers
//          The number of repetitions of the accident completion
//          The date of the last recording.
//
Procedure OnDefineErrorHandlers(ErrorHandlers) Export
	
EndProcedure

// Generates a table of routine tasks with a sign of use in the service model.
// @skip-warning EmptyMethod - Overridable method.
// 
// Parameters:
//  UsageTable - ValueTable - LongDesc:
//	* ScheduledJob - String - the name of the routine task.
//  * Use - Boolean - signs of use.
//
Procedure OnDefineScheduledJobsUsage(UsageTable) Export
	
EndProcedure

#EndRegion
