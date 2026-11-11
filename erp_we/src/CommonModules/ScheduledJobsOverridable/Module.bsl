///////////////////////////////////////////////////////////////////////////////////////////////////////
// Copyright (c) 2025, OOO 1C-Soft
// All rights reserved. This software and the related materials 
// are licensed under a Creative Commons Attribution 4.0 International license (CC BY 4.0).
// To view the license terms, follow the link:
// https://creativecommons.org/licenses/by/4.0/legalcode
///////////////////////////////////////////////////////////////////////////////////////////////////////
//

#Region Public

// Determines the following properties of scheduled jobs:
//  - dependence on functional options.
//  - ability of execution in different application modes.
//  - other parameters.
//
// Parameters:
//  Settings - ValueTable:
//    * ScheduledJob - MetadataObjectScheduledJob - a scheduled job.
//    * FunctionalOption - MetadataObjectFunctionalOption - functional option
//        the scheduled job depends on.
//    * DependenceByT      - Boolean - if the scheduled job depends on more than
//        one functional option and you want to enable it only
//        when all functional options are enabled, specify True
//        for each dependency.
//        The default value is False - if one or more functional options are enabled,
//        the scheduled job is also enabled.
//    * EnableOnEnableFunctionalOption - Boolean
//                                              - Undefined - if False, the scheduled job
//        will not be enabled if the functional option is enabled. The
//        Undefined value corresponds to True.
//        The default value is Undefined.
//    * AvailableInSubordinateDIBNode - Boolean
//                                  - Undefined - True or Undefined if the scheduled
//        job is available in the DIB node.
//        The default value is Undefined.
//    * AvailableAtStandaloneWorkstation - Boolean
//                                      - Undefined - True or Undefined if the scheduled
//        job is available in the standalone workplace.
//        The default value is Undefined.
//    * AvailableSaaS - Boolean
//                             - Undefined - — False if scheduled job
//        execution (including queue jobs) in the infobase with enabled separator must be locked.
//        The Undefined value is read as True.
//        Default value: Undefined.
//    * UseExternalResources  - Boolean - "True" if the scheduled job modifies data
//        in external sources (receiving emails, synchronizing data, etc.). Do not set the
//        value to True for scheduled jobs that do not modify data in external sources.
//        For example, CurrencyRateImport scheduled job. Scheduled jobs operating with external resources are
//        automatically disabled in the copy of the infobase and are blocked if the
//        "Allow access to web services" functional option is disabled. The default value is False.
//    * CanAccessExternalResources - Boolean - If UseExternalResources is set to False, but the scheduled job accesses external resources
//        (web services), for example, the ImportCurrenciesRates job,
//        then this flag should be set to True. By default, it equals the UseExternalResources parameter.
//        Scheduled jobs that work with Internet services will not run if the "Allow access to web services"
//        functional option is disabled.
//    * IsParameterized             - Boolean - True if the scheduled job is parameterized.
//        The default value is False.
//
// Example:
//	Setting = Settings.Add();
//	Setting.ScheduledJob = Metadata.ScheduledJobs.SMSDeliveryStatusUpdate;
//	Setting.FunctionalOption = Metadata.FunctionalOptions.UseEmailClient;
//	Setting.AvailableInSaaS = False;
//
Procedure OnDefineScheduledJobSettings(Settings) Export
	
	// IntegrationWith1CDocumentManagementSubsystem
	IntegrationWith1CDocumentManagementCore.OnDefineScheduledJobSettings(Settings);
	// End IntegrationWith1CDocumentManagementSubsystem
	
	ScheduledJobsLocalization.OnDefineScheduledJobSettings(Settings);
	FinancialAccountingOfGeneralPurpose.OnDefineScheduledJobSettings(Settings);
	Setting = Settings.Add();
	Setting.ScheduledJob = Metadata.ScheduledJobs.ArchiveCashRegisterReceipts;
	Setting.UseExternalResources = False;
	Setting.FunctionalOption = Metadata.FunctionalOptions.UseRetailSales;
	
	Setting = Settings.Add();
	Setting.ScheduledJob = Metadata.ScheduledJobs.DeleteDeferredCashRegisterReceipts;
	Setting.UseExternalResources = False;
	Setting.FunctionalOption = Metadata.FunctionalOptions.UseRetailSales;
	
	Setting = Settings.Add();
	Setting.ScheduledJob = Metadata.ScheduledJobs.DeleteCashRegisterReceipts;
	Setting.UseExternalResources = False;
	Setting.FunctionalOption = Metadata.FunctionalOptions.UseRetailSales;
	
	Setting = Settings.Add();
	Setting.ScheduledJob = Metadata.ScheduledJobs.UpdateDataOnGoodsAvailabilityForExternalUsers;
	Setting.FunctionalOption = Metadata.FunctionalOptions.WorkIsExecutedViaSalesRepresentatives;
	Setting.AvailableSaaS = False;
	
	Setting = Settings.Add();
	Setting.ScheduledJob = Metadata.ScheduledJobs.ActualizationDemandsAlongSupplyBorder;
	Setting.FunctionalOption = Metadata.FunctionalOptions.UseOrdersAtLeastOneType;
	Setting.UseExternalResources = False;
	Setting.EnableOnEnableFunctionalOption = True;
	
	Setting = Settings.Add();
	Setting.ScheduledJob = Metadata.ScheduledJobs.ABCInventoryClassification;
	Setting.FunctionalOption = Metadata.FunctionalOptions.UseABCXYZClassificationOfInventoryByGrossProfit;
	
	Setting = Settings.Add();
	Setting.ScheduledJob = Metadata.ScheduledJobs.ABCInventoryClassification;
	Setting.FunctionalOption = Metadata.FunctionalOptions.UseABCXYZClassificationOfInventoryByRevenue;
	
	Setting = Settings.Add();
	Setting.ScheduledJob = Metadata.ScheduledJobs.ABCInventoryClassification;
	Setting.FunctionalOption = Metadata.FunctionalOptions.UseABCXYZClassificationOfInventoryByNumberOfSales;
	
	Setting = Settings.Add();
	Setting.ScheduledJob = Metadata.ScheduledJobs.XYZInventoryClassification;
	Setting.FunctionalOption = Metadata.FunctionalOptions.UseABCXYZClassificationOfInventoryByGrossProfit;
	
	Setting = Settings.Add();
	Setting.ScheduledJob = Metadata.ScheduledJobs.XYZInventoryClassification;
	Setting.FunctionalOption = Metadata.FunctionalOptions.UseABCXYZClassificationOfInventoryByRevenue;
	
	Setting = Settings.Add();
	Setting.ScheduledJob = Metadata.ScheduledJobs.XYZInventoryClassification;
	Setting.FunctionalOption = Metadata.FunctionalOptions.UseABCXYZClassificationOfInventoryByNumberOfSales;
	
	Setting = Settings.Add();
	Setting.ScheduledJob = Metadata.ScheduledJobs.ABCPartnerClassification;
	Setting.FunctionalOption = Metadata.FunctionalOptions.UseABCXYZClassificationOfPartnersByGrossProfit;
	
	Setting = Settings.Add();
	Setting.ScheduledJob = Metadata.ScheduledJobs.ABCPartnerClassification;
	Setting.FunctionalOption = Metadata.FunctionalOptions.UseABCXYZClassificationOfPartnersByRevenue;
	
	Setting = Settings.Add();
	Setting.ScheduledJob = Metadata.ScheduledJobs.ABCPartnerClassification;
	Setting.FunctionalOption = Metadata.FunctionalOptions.UseABCXYZClassificationOfPartnersByNumberOfSales;
	
	Setting = Settings.Add();
	Setting.ScheduledJob = Metadata.ScheduledJobs.XYZPartnerClassification;
	Setting.FunctionalOption = Metadata.FunctionalOptions.UseABCXYZClassificationOfPartnersByGrossProfit;
	
	Setting = Settings.Add();
	Setting.ScheduledJob = Metadata.ScheduledJobs.XYZPartnerClassification;
	Setting.FunctionalOption = Metadata.FunctionalOptions.UseABCXYZClassificationOfPartnersByRevenue;
	
	Setting = Settings.Add();
	Setting.ScheduledJob = Metadata.ScheduledJobs.XYZPartnerClassification;
	Setting.FunctionalOption = Metadata.FunctionalOptions.UseABCXYZClassificationOfPartnersByNumberOfSales;
	
	Setting = Settings.Add();
	Setting.ScheduledJob = Metadata.ScheduledJobs.AutomaticAccrueAndDeductionOfBonusPoints;
	Setting.FunctionalOption = Metadata.FunctionalOptions.UseLoyaltyPrograms;
	Setting.IsParameterized     = True;
	Setting.EnableOnEnableFunctionalOption = False;
	
	Setting = Settings.Add();
	Setting.ScheduledJob = Metadata.ScheduledJobs.DataAnalysisForNotificationsToCustomers;
	Setting.FunctionalOption = Metadata.FunctionalOptions.UseEmailClient;
	Setting.EnableOnEnableFunctionalOption = False;
	
	Setting = Settings.Add();
	Setting.ScheduledJob = Metadata.ScheduledJobs.CalculationOfCost;
	Setting.FunctionalOption = Metadata.FunctionalOptions.CalculatePreliminaryCostWithScheduledJob;
	
	Setting = Settings.Add();
	Setting.ScheduledJob = Metadata.ScheduledJobs.CalculationOfAnalysisOptionDataSources;
	Setting.FunctionalOption = Metadata.FunctionalOptions.UseTargetValueMonitoring;
	Setting.EnableOnEnableFunctionalOption = False;
	
	Setting = Settings.Add();
	Setting.ScheduledJob = Metadata.ScheduledJobs.UpdateItemsSoldTogether;
	Setting.FunctionalOption = Metadata.FunctionalOptions.UseItemsSoldTogether;
	
	Setting = Settings.Add();
	Setting.ScheduledJob = Metadata.ScheduledJobs.AdjustmentOfMeasuringGoodsOrderRows;
	Setting.FunctionalOption = Metadata.FunctionalOptions.UseAutomaticClosingOfMeasuringGoodsOrderRows;
	
	Setting = Settings.Add();
	Setting.ScheduledJob = Metadata.ScheduledJobs.UpdatePeripheralsGoodsCodes;
	Setting.FunctionalOption = Metadata.FunctionalOptions.UseExchangeWithOfflinePeripherals;
	Setting.EnableOnEnableFunctionalOption = False;
	
	Setting = Settings.Add();
	Setting.ScheduledJob = Metadata.ScheduledJobs.SegmentClearance;
	Setting.FunctionalOption = Metadata.FunctionalOptions.UseProductSegments;
	
	Setting = Settings.Add();
	Setting.ScheduledJob = Metadata.ScheduledJobs.SegmentClearance;
	Setting.FunctionalOption = Metadata.FunctionalOptions.UsePartnersSegments;
	
	Setting = Settings.Add();
	Setting.ScheduledJob = Metadata.ScheduledJobs.DeleteInteractionsRelatedToMailoutsAndNotifications;
	Setting.FunctionalOption = Metadata.FunctionalOptions.UseEmailClient;
	Setting.EnableOnEnableFunctionalOption = False;
	
	Setting = Settings.Add();
	Setting.ScheduledJob = Metadata.ScheduledJobs.SegmentGeneration;
	Setting.FunctionalOption = Metadata.FunctionalOptions.UsePartnersSegments;
	Setting.IsParameterized     = True;
	Setting.EnableOnEnableFunctionalOption = False;
	
	Setting = Settings.Add();
	Setting.ScheduledJob = Metadata.ScheduledJobs.SegmentGeneration;
	Setting.FunctionalOption = Metadata.FunctionalOptions.UseProductSegments;
	Setting.IsParameterized     = True;
	Setting.EnableOnEnableFunctionalOption = False;
	
	Setting = Settings.Add();
	Setting.ScheduledJob = Metadata.ScheduledJobs.MessageGenerationByCustomerNotifications;
	Setting.FunctionalOption = Metadata.FunctionalOptions.UseEmailClient;
	
	Setting = Settings.Add();
	Setting.ScheduledJob = Metadata.ScheduledJobs.MessageGenerationForCustomerMailouts;
	Setting.FunctionalOption = Metadata.FunctionalOptions.UseEmailClient;
	
	Setting = Settings.Add();
	Setting.ScheduledJob = Metadata.ScheduledJobs.MonthEndTransactions;
	Setting.AvailableInSubordinateDIBNode = False;
	
	Setting = Settings.Add();
	Setting.ScheduledJob = Metadata.ScheduledJobs.GenerateNotificationsForBudgetTasks;
	Setting.FunctionalOption = Metadata.FunctionalOptions.UseNotificationsForBudgetingTasks;
	
	Setting = Settings.Add();
	Setting.ScheduledJob = Metadata.ScheduledJobs.BudgetTasksGeneration;
	Setting.FunctionalOption = Metadata.FunctionalOptions.UseBudgeting;
	
	Setting = Settings.Add();
	Setting.ScheduledJob = Metadata.ScheduledJobs.ImportProductionMasterData;
	Setting.FunctionalOption = Metadata.FunctionalOptions.UseImportOfProductionMasterData;
	Setting.UseExternalResources              = True;
	Setting.AvailableSaaS                  = False;
	Setting.EnableOnEnableFunctionalOption = False;
	Setting = Settings.Add();
	Setting.ScheduledJob = Metadata.ScheduledJobs.DeferredPostingOfBudgetEntryForms;
	Setting.FunctionalOption = Metadata.FunctionalOptions.UseBudgeting;
	
	Setting = Settings.Add();
	Setting.ScheduledJob = Metadata.ScheduledJobs.DocumentPostingInBudgeting;
	Setting.FunctionalOption = Metadata.FunctionalOptions.UseBudgeting;
	
	Setting = Settings.Add();
	Setting.ScheduledJob = Metadata.ScheduledJobs.CompanySafeStockRollup;
	Setting.FunctionalOption = Metadata.FunctionalOptions.UseCustodyDuringPurchase;
	
	Setting = Settings.Add();
	Setting.ScheduledJob = Metadata.ScheduledJobs.SendSMSMessage;
	Setting.UseExternalResources = True;
	
	Setting = Settings.Add();
	Setting.ScheduledJob = Metadata.ScheduledJobs.SendReceiveSystemMessages;
	Setting.UseExternalResources = True;
	
	Setting = Settings.Add();
	Setting.ScheduledJob = Metadata.ScheduledJobs.ReportMailing;
	Setting.UseExternalResources = True;
	
	Setting = Settings.Add();
	Setting.ScheduledJob = Metadata.ScheduledJobs.FilesSynchronization;
	Setting.UseExternalResources = True;
	
	Setting = Settings.Add();
	Setting.ScheduledJob = Metadata.ScheduledJobs.CalculationOfStockReplenishmentRecommendations;
	Setting.FunctionalOption = Metadata.FunctionalOptions.UseAdvancedDemandFulfillment;
	Setting.EnableOnEnableFunctionalOption = False;
	
	Setting = Settings.Add();
	Setting.ScheduledJob = Metadata.ScheduledJobs.CompanySafeStockRollup;
	Setting.FunctionalOption = Metadata.FunctionalOptions.UseCustomerInvoiceIntercompany;
	
	Setting = Settings.Add();
	Setting.ScheduledJob = Metadata.ScheduledJobs.CompanySafeStockRollup;
	Setting.FunctionalOption = Metadata.FunctionalOptions.UseProductionManagement2_2;
	
	Setting = Settings.Add();
	Setting.ScheduledJob = Metadata.ScheduledJobs.DownloadingECBExchangeRates;
	Setting.FunctionalOption = Metadata.FunctionalOptions.UseTheDownloadOfECBExchangeRates;
	
	Setting = Settings.Add();
	Setting.ScheduledJob = Metadata.ScheduledJobs.DeleteUnusedInventoryAffiliationDataOfRetailOutlets;
	Setting.UseExternalResources = False;
	Setting.FunctionalOption = Metadata.FunctionalOptions.UseRetailSales;
	
	// LoyaltyServer
	Setting = Settings.Add();
	Setting.ScheduledJob = Metadata.ScheduledJobs.ProcessStateOfBonusPointsAndGiftCardsLoyaltyServer;
	Setting.FunctionalOption = Metadata.FunctionalOptions.UseLoyaltyServerDataProvider;
	Setting.EnableOnEnableFunctionalOption = True;
	// End LoyaltyServer
	
	Setting = Settings.Add();
	Setting.ScheduledJob = Metadata.ScheduledJobs.UserNotificationsOfEvents;
	Setting.FunctionalOption = Metadata.FunctionalOptions.UseUserNotificationsOfSystemEvents;
	Setting.EnableOnEnableFunctionalOption = True;
	Setting.UseExternalResources = True;
	
	Setting = Settings.Add();
	Setting.ScheduledJob = Metadata.ScheduledJobs.BotsProcessing;
	If Not Common.DataSeparationEnabled() And Common.SeparatedDataUsageAvailable() Then
		// In the box, the routine task depends on the functional option.
		// In Service Mode, it should always work in undivided mode.
		Setting.FunctionalOption = Metadata.FunctionalOptions.UseUserNotificationsViaTelegram;
	EndIf;
	Setting.CanAccessExternalResources = True;

EndProcedure

// Allows to overwrite the default subsystem settings.
//
// Parameters:
//  Settings - Structure:
//    * UnlockCommandPlacement - String - determines unlock
//                                                     command location for operations with external resources
//                                                     on infobase movement.
//
Procedure OnDefineSettings(Settings) Export
	
EndProcedure


#EndRegion