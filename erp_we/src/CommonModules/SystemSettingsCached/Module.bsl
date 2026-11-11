////////////////////////////////////////////////////////////////////////////////
// Server procedures and functions that control system settings
//
////////////////////////////////////////////////////////////////////////////////
//

#Region Public

#Region Constants

// Returns a structure that describes the "subordinate" constants for the specified "parent" constant.
//
//	Parameters:
//		NameOfParentConstant 	  - String - name of the constant as set in the Configurator
//		ValueOfParentConstant - Arbitrary - the value of the constant.
//
//	Returns:
//		Structure
//			Key - name of the subordinate constant
//			Value - the value of the subordinate constant corresponding to the value of the parent constant.
//
Function GetValidValuesOfSubordinateConstants(NameOfParentConstant, ValueOfParentConstant) Export
	
	Result 		= New Structure;
	TableOfConstants = SystemSettingsCached.GetTableOfConstantDependencies();
	
	SubordinateConstants = TableOfConstants.FindRows(
		New Structure(
			"NameOfParentConstant, ValueOfParentConstant",
			NameOfParentConstant, ValueOfParentConstant));
	
	For Each TableRow In SubordinateConstants Do
		Result.Insert(TableRow.NameOfSubordinateConstant, TableRow.ValueOfSubordinateConstant);
	EndDo;
	
	Return Result;
	
EndFunction

// Returns an indication whether the constants are "subordinates" of the constants.
//
//	Parameters:
//		NameOfParentConstant 	  - String - name of the constant as set in the Configurator
//		ValueOfParentConstant - Arbitrary - the value of the constant.
//
//	Returns:
//		Boolean - if True, then the constant has constants "subordinate" to it.
//
Function ThereAreSubordinateConstants(NameOfParentConstant, ValueOfParentConstant) Export
	
	TableOfConstants = SystemSettingsCached.GetTableOfConstantDependencies();
	
	SubordinateConstants = TableOfConstants.FindRows(
		New Structure(
			"NameOfParentConstant, ValueOfParentConstant",
			NameOfParentConstant, ValueOfParentConstant));
	
	Return SubordinateConstants.Count() > 0;
	
EndFunction

// Returns a structure that describes the "parent" constants for the specified "subordinate" constants.
//
//	Parameters:
//		StructureOfSubordinateConstants - Structure - names of subordinate constants.
//
//	Returns:
//		Structure
//			Key - name of the parent constant.
//
Function GetStructureOfParentConstants(StructureOfSubordinateConstants) Export
	
	TableOfConstants 	  = SystemSettingsCached.GetTableOfConstantDependencies();
	ProcessedConstants = New Structure;
	
	Result = SystemSettings.GetStructureOfParentConstantsRecursively(
		StructureOfSubordinateConstants,
		TableOfConstants,
		ProcessedConstants);
	
	For Each KeyAndValue In StructureOfSubordinateConstants Do
		// The parent constants do not need to include those that are part of the subordinate structure.
		Result.Delete(KeyAndValue.Key);
	EndDo;
	
	Return Result;
	
EndFunction

// Returns a structure that describes the "subordinate" constants for the specified "parent" constant.
//
//	Parameters:
//		NameOfParentConstant - Structure - the name of the parent constant.
//
//	Returns:
//		Structure
//			Key - name of the subordinate constant.
//
Function GetStructureOfSubordinateConstants(NameOfParentConstant) Export
	
	TableOfConstants = SystemSettingsCached.GetTableOfConstantDependencies();
	ProcessedConstants = New Structure;
	
	Result = SystemSettings.GetStructureOfSubordinateConstantsRecursively(
		NameOfParentConstant,
		TableOfConstants,
		ProcessedConstants);
	
	Return Result;
	
EndFunction

// Returns the values of constants in the new default is.
//
//	Returns:
//		Structure
//			The key is the name of the constant.
Function GetDefaultValuesOfConstants() Export
	
	BaseVersion = StandardSubsystemsServer.IsBaseConfigurationVersion();
	
	Result = New Structure;
	
#Region Service_constants
	Result.Insert(Metadata.Constants.BaseVersion.Name, 				 BaseVersion);
	Result.Insert(Metadata.Constants.NotBaseVersion.Name, 				 Not BaseVersion);
	Result.Insert(Metadata.Constants.UseAccessManagement.Name, Not BaseVersion);
	Result.Insert(Metadata.Constants.EmployeeInChargeInDocuments.Name,		 Not BaseVersion);
#EndRegion
#Region _holdingManagement
	Result.Insert(Metadata.Constants.NotCPM.Name, False);
	Result.Insert(Metadata.Constants.NotCPM.Name, True);
#EndRegion
#Region Production
	Result.Insert(Metadata.Constants.UseProduction.Name, False); // in UT11
	Result.Insert(Metadata.Constants.UseProduction.Name, True);
	Result.Insert(Metadata.Constants.UseProductionManagement.Name,    False);
	Result.Insert(Metadata.Constants.UseProductionManagement2_2.Name, True);
	Result.Insert(Metadata.Constants.EnabledOnlyProductionManagement21.Name, False);
	Result.Insert(Metadata.Constants.EnabledOnlyProductionManagement22.Name, True);
	Result.Insert(Metadata.Constants.UseOrderSupplyWithAssignment.Name, True);
	Result.Insert(Metadata.Constants.ProductionManagementMethod.Name, Enums.ProductionManagementMethod.WithoutCalculationOfProductionSchedule);
	Result.Insert(Metadata.Constants.StartDateOfAccountingForOutputByOperations.Name, Date("19800101"));
#EndRegion

#Region Assignment_options
	Result.Insert(Metadata.Constants.OptionOfGoodsAssignmentInSales.Name,               Enums.OptionsOfGoodsAssignmentInSales.SalesOrder);
	Result.Insert(Metadata.Constants.OptionOfGoodslAssignmentInTransfer.Name,            Enums.OptionsOfGoodslAssignmentInTransfer.AssignmentRecipient);
	Result.Insert(Metadata.Constants.OptionOfGoodsAssignmentInInventoryConsumption.Name, Enums.OptionsOfGoodsAssignmentInInventoryConsumption.InventoryConsumptionOrder);
	Result.Insert(Metadata.Constants.OptionOfGoodsAssignmentInAssembly.Name,                 Enums.OptionsOfGoodsAssignmentInAssembly.AssignmentOfAssembledKit);
	Result.Insert(Metadata.Constants.OptionOfMaterialAssignmentWhenTransferringToProduction.Name, Enums.OptionsOfMaterialAssignmentWhenTransferringToProduction.AssignmentRecipient);
	Result.Insert(Metadata.Constants.SubcontractorOptionOfAssignment2_5.Name,                  Enums.OptionsOfAssignmentDuringTransferToProcessing.DoNotAssign);
	Result.Insert(Metadata.Constants.OptionOfAssignmentAtTransferToSubcontractor2_5.Name,          Enums.OptionsOfAssignmentDuringTransferToProcessing.SubcontractOrder);
	Result.Insert(Metadata.Constants.OptionOfMaterialAssignmentInProduction.Name,            Enums.OptionsOfMaterialAssignmentInProduction.ProductionOrder);
	Result.Insert(Metadata.Constants.OptionOfMaterialAssignmentInRM.Name,                Enums.OptionsOfMaterialAssignmentInRM.RMOrder);
	
	Result.Insert(Metadata.Constants.OptionOfMaterialAssignmentUponSubcontractingServicesDelivered.Name,    Enums.AssignmentAtSubcontractingServicesDelivered.ContractWithMaterialProviderForProcessing);
	Result.Insert(Metadata.Constants.OptionOfManufacturedProductAssignmentUponSubcontractingServicesDelivered.Name,     Enums.AssignmentAtSubcontractingServicesDelivered.ContractWithMaterialProviderForProcessing);
#EndRegion
	
#Region Interface
	CurrentMode = Metadata.InterfaceCompatibilityMode;
	Taxi = (CurrentMode = Metadata.ObjectProperties.InterfaceCompatibilityMode.Taxi
		Or CurrentMode = Metadata.ObjectProperties.InterfaceCompatibilityMode.TaxiEnableVersion8_2)
		Or BaseVersion;
	Result.Insert(Metadata.Constants.InterfaceVersion82.Name, Not Taxi);
#EndRegion
	
#Region Agreements_With_Clients
	Result.Insert(Metadata.Constants.UseTermsOfSales.Name, 					 Enums.UseTermsOfSales.DontUse);
	Result.Insert(Metadata.Constants.UseStandardAndIndividualTermsOfSalesWithCustomers.Name, False);
	Result.Insert(Metadata.Constants.UseStandardTermsOfSalesWithCustomers.Name, 				 False);
	Result.Insert(Metadata.Constants.UseCustomerTermsOfSales.Name, 		 False);
#EndRegion

#Region StagesOf_payment
	If BaseVersion Then
		Result.Insert(Metadata.Constants.UsePaymentStepsInPurchases.Name, Enums.UsePaymentSteps.SimplifiedScheme);
		Result.Insert(Metadata.Constants.UsePaymentStepsInSales.Name, Enums.UsePaymentSteps.SimplifiedScheme);
	Else
		Result.Insert(Metadata.Constants.UsePaymentStepsInPurchases.Name, Enums.UsePaymentSteps.CustomSettings);
		Result.Insert(Metadata.Constants.UsePaymentStepsInSales.Name, Enums.UsePaymentSteps.CustomSettings);
	EndIf;
#EndRegion
	
#Region BaseVersion
	If BaseVersion Then
		Result.Insert(Metadata.Constants.UseDataSynchronization.Name, True);
		Result.Insert(Metadata.Constants.UseMultipleCashAccounts.Name, False);
		Result.Insert(Metadata.Constants.UseAuthorizationLettersForInventoryReceipt.Name, True);
		Result.Insert(Metadata.Constants.UseOrderMovementReport.Name, False);
		Result.Insert(Metadata.Constants.DisplayAdditionalVATColumns.Name, True);
	Else
		Result.Insert(Metadata.Constants.UseOrderMovementReport.Name, Constants.UseAdvancedFeaturesOfSalesOrder.Get());
	EndIf;
#EndRegion
	
#Region EvaluationOf_renterability_sales
	Result.Insert(Metadata.Constants.GoodsCostWhenEvaluatingSalesProfitability.Name, Enums.GoodsCostWhenEvaluatingSalesProfitability.ByEstimatedCost);
#EndRegion

#Region ABC_XYZ_Classification_OfProductItem
	Result.Insert(Metadata.Constants.PeriodOfABCClassificationOfInventory.Name, 			 Enums.Periodicity.Month);
	Result.Insert(Metadata.Constants.PeriodOfXYZClassificationOfInventory.Name, 			 Enums.Periodicity.Month);
	Result.Insert(Metadata.Constants.SubperiodOfXYZClassificationOfInventory.Name, 		 Enums.Periodicity.Month);
	Result.Insert(Metadata.Constants.NumberOfPeriodsOfABCClassificationOfInventory.Name, 1);
	Result.Insert(Metadata.Constants.NumberOfPeriodsOfXYZClassificationOfInventory.Name, 2);
#EndRegion
	
#Region ABC_XYZ_partners_classification
	Result.Insert(Metadata.Constants.PeriodOfABCClassificationOfPartners.Name, 			  Enums.Periodicity.Month);
	Result.Insert(Metadata.Constants.PeriodOfXYZClassificationOfPartners.Name, 			  Enums.Periodicity.Month);
	Result.Insert(Metadata.Constants.SubperiodOfXYZClassificationOfPartners.Name, 		  Enums.Periodicity.Month);
	Result.Insert(Metadata.Constants.NumberOfPeriodsOfABCClassificationOfPartners.Name, 1);
	Result.Insert(Metadata.Constants.NumberOfPeriodsOfXYZClassificationOfPartners.Name, 2);
#EndRegion
	
#Region CalculationOf_Commodity_Constraints
	Result.Insert(Metadata.Constants.PeriodOfGoodsLimitationCalculation.Name,             Enums.Periodicity.Month);
	Result.Insert(Metadata.Constants.NumberOfCommercialRestrictionCalculationPeriods.Name, 2);
	Result.Insert(Metadata.Constants.SeasonalFluctuationsRegistrationOption.Name,                Enums.SeasonalFluctuationsAccounting.DontConsider);
#EndRegion
	
#Region Products
	Result.Insert(Metadata.Constants.UseMultipleKindsOfProducts.Name, 			Not BaseVersion);
	Result.Insert(Metadata.Constants.ControlItemUniquenessByCombinationValuesAttributes.Name, Not BaseVersion);
	Result.Insert(Metadata.Constants.ControlUniquenessOfWorkingNamesOfProductsAndItemVariants.Name, 			True);
	Result.Insert(Metadata.Constants.MaximumNumberOfItemsInItemFilterTree.Name, 			50);
	Result.Insert(Metadata.Constants.AllowableDeviationOfAutomaticRounding.Name, 			                3);
#EndRegion
	
#Region Products_sold_place
	Result.Insert(Metadata.Constants.FrequencyForInventoryAnalysis.Name, 		Enums.Periodicity.Year);
	Result.Insert(Metadata.Constants.MinimumCredibility.Name, 		60);
	Result.Insert(Metadata.Constants.MinimumSignificance.Name, 		0);
	Result.Insert(Metadata.Constants.MinimumRateOfCases.Name, 	10);
	Result.Insert(Metadata.Constants.NumberOfPeriodsForItemsSoldTogetherAnalisys.Name, 	1);
#EndRegion
	
#Region Print
	Result.Insert(Metadata.Constants.AdditionalColumnOfDocumentPrintForms.Name, Enums.AdditionalColumnOfDocumentPrintForms.DontOutput);
	Result.Insert(Metadata.Constants.DisplayDiscountsInPrintFormsOfSalesDocuments.Name, Enums.OptionsOfDiscountsDisplayingInPrintForms.NotDisplayDiscounts);
	Result.Insert(Metadata.Constants.UseInternationalPrintingForms.Name, True);
#EndRegion

#Region Partners_contragents
	// By default, only partners are used, since the inclusion of
	// the "Use partners and counterparties" attribute is not subject to reverse change.
	Result.Insert(Metadata.Constants.UsePartnersAndCounterparties.Name, False);
#EndRegion
	
#Region Approval
	// By default, we use internal coordination, not through 1C:Document flow.
	Result.Insert(Metadata.Constants.UseInternalSalesOrderApproval.Name, 				 True);
	Result.Insert(Metadata.Constants.UseInternalApprovalOfRequestsForReturnOfGoodsFromCustomers.Name, True);
	Result.Insert(Metadata.Constants.UseInternalApprovalOfTermsOfSales.Name, 			 True);
#EndRegion
	
#Region JobsForSalesRepresentatives
	Result.Insert(Metadata.Constants.UseJobsToSalesRepresentatives.Name, Enums.UseJobsToSalesRepresentatives.NotUsed_);
#EndRegion
	
#Region Finances
	Result.Insert(Metadata.Constants.UseAccountingOfOtherIncomeExpenses.Name, 	     Not BaseVersion);
	Result.Insert(Metadata.Constants.GenerateFinancialResult.Name, 			 Not BaseVersion);
	Result.Insert(Metadata.Constants.UseBalanceSheetStatement.Name, 			 Not BaseVersion);
	Result.Insert(Metadata.Constants.UseBusinessUnits.Name,					 Not BaseVersion);
	Result.Insert(Metadata.Constants.UseCashPaymentJournal.Name,				  	 BaseVersion);
	Result.Insert(Metadata.Constants.NotUseCashPaymentJournal.Name,				 Not BaseVersion);
	Result.Insert(Metadata.Constants.KeepRecordsOfInventoryCostByAssignments.Name, True);
	Result.Insert(Metadata.Constants.AllocationOfAdditionalExpensesByDisposedGoods.Name,   True);
	Result.Insert(Metadata.Constants.UseFinancialAccountingGroups.Name, True);
#EndRegion
	
#Region FormationOf_consumed_orders
	Result.Insert(Metadata.Constants.ProcedureOfInvoiceAndGoodsIssueNoteRegistration.Name, Enums.ProcedureOfInvoiceAndGoodsIssueNoteRegistration.OrdersFirst);
	Result.Insert(Metadata.Constants.GoodsIssueNoteGenerationMode.Name, Enums.GoodsIssueNoteGenerationModes.Automatically);
	Result.Insert(Metadata.Constants.GoodsIssueNotesAreGeneratedByManager.Name, False);
#EndRegion
	
#Region Batch_Accounting
	Result.Insert(Metadata.Constants.UseCostAccounting.Name, 		True);
	Result.Insert(Metadata.Constants.NumberOfJobForCalculatingCost.Name,	1);
#EndRegion

#Region ARAPAccounting
	
	Result.Insert(Metadata.Constants.NumberOfJobForAllocatingCustomersARAP.Name, 1);
	Result.Insert(Metadata.Constants.NumberOfJobForAllocatingVendorsARAPAccounting.Name, 1);
	
	Result.Insert(Metadata.Constants.NewOnlineARAPAccounting.Name, True);
	Result.Insert(Metadata.Constants.OffsetOrderOfPaymentsAndInvoices.Name, Enums.OffsetOrdersOfPaymentsAndInvoices.ByDocumentDateAndType);
	
#EndRegion
	
#Region Demand_fulfillment
	Result.Insert(Metadata.Constants.UseAdvancedDemandFulfillment.Name, Not BaseVersion);
	Result.Insert(Metadata.Constants.NotUseAdvancedDemandFulfillment.Name, BaseVersion);
#EndRegion

#Region OrderList_
	Result.Insert(Metadata.Constants.GoodsReceiptOption.Name, Enums.GoodsReceiptOptions.SplitByInvoicesOnly);
#EndRegion
		
#Region UsedMaterials
	Result.Insert(Metadata.Constants.UseInventoryConsumption.Name, True);
#EndRegion

#Region NonCurrent_Assets
	Result.Insert(Metadata.Constants.UseNonCurrentAssets2_2.Name, False);
	Result.Insert(Metadata.Constants.UseNonCurrentAssets2_4.Name, True);
	Result.Insert(Metadata.Constants.UseAccountingOfOtherIncomeExpensesInLocalAccounting.Name, Not BaseVersion);
#EndRegion

#Region SupportPBU18UT

	Result.Insert(Metadata.Constants.CalculationOfPermanentAndTemporaryDifferencesIsKeptCommon.Name, False);

#EndRegion

#Region Marketing_and_CRM
	Result.Insert(Metadata.Constants.UsePriceManagementSystem25.Name,    True);
	Result.Insert(Metadata.Constants.UsePriceManagementSystem20.Name,    False);
#EndRegion
#Region InternationalFinancialAccounting
	Result.Insert(Metadata.Constants.UseFinancialAccounting.Name, True);
	Result.Insert(Metadata.Constants.FinancialAccountingEntriesBasedOnOperationalAccountingData.Name, True);
	Result.Insert(Metadata.Constants.SettingOfPostingByAccountingObjects.Name, True);
#EndRegion
#Region UseSummaryDebtAdjustmentOperations
	Result.Insert(Metadata.Constants.UseConsolidatedDebtAdjustmentTransactionsForAcquisition.Name, True);
	Result.Insert(Metadata.Constants.UseConsolidatedDebtAdjustmentOperationsForSales.Name, True);
#EndRegion

	#Region InventoryInOperation
	Result.Insert(Metadata.Constants.AccountForInventoryInERP2AndCAOperation.Name, False);
	Result.Insert(Metadata.Constants.AccountForInventoryInOperationWE.Name, True);
	#EndRegion
	
#Region GoodsAccounting
	Result.Insert(Metadata.Constants.ControlCompanyStockBalance.Name, True);
#EndRegion

#Region TreasuryAndARAPAccounting

	Result.Insert(Metadata.Constants.UseCashDepositToListEmployees.Name, True);
	Result.Insert(Metadata.Constants.InternationalBankAccountDetails.Name, True);
#EndRegion

#Region Performance
	
	Result.Insert(Metadata.Constants.TimeLimitForUpdatingListOfDocuments.Name, 2);
	Result.Insert(Metadata.Constants.PerformedInitialRegistrationOfBackdateAdditionalDocumentPostingJobs.Name, True);
	
#EndRegion
#Region Budgeting
	Result.Insert(Metadata.Constants.SetUpRulesForObtainingActualDataByAssetAndLiabilityItems.Name, True);
	Result.Insert(Metadata.Constants.SettingUpRulesForObtainingFactsFromCorrespondingRegisters.Name, False);
#EndRegion
#Region Delivery
	Result.Insert(Metadata.Constants.DeliveryPlanning.Name, Enums.DeliveryPlanningKinds.ByCurrentDocument);
#EndRegion

#Region UserNotificationsOfEvents
	Result.Insert(Metadata.Constants.UseUserNotificationsOfSystemEvents.Name, False);
	Result.Insert(Metadata.Constants.UseUserNotificationsViaTelegram.Name, False);
	Result.Insert(Metadata.Constants.UseUserNotificationsByEmail.Name, False);
#EndRegion
	
	SystemSettingsLocalization.AddDefaultValuesToConstants(Result);
	
	// Let's add constants to the structure that have subordinate constants.
	TableOfConstants = SystemSettingsCached.GetTableOfConstantDependencies();
	
	TableOfDependentConstants = TableOfConstants.Copy();
	TableOfDependentConstants.GroupBy("NameOfParentConstant", "");
	
	DataModel = New Map();
	If Common.SubsystemExists("CloudTechnology.Core") Then
		ModuleSaaSOperations = Common.CommonModule("SaaSOperations");
		DataModel = ModuleSaaSOperations.GetAreaDataModel();
	EndIf;
	For Each String In TableOfDependentConstants Do
		If Not Result.Property(String.NameOfParentConstant) 
			And (Not Common.DataSeparationEnabled() 
			And Not String.NameOfParentConstant = "DoNotUseSeparationByDataAreas"
			Or DataModel.Get("Constant."+String.NameOfParentConstant) <> Undefined) Then
			Result.Insert(
				String.NameOfParentConstant,
				Metadata.Constants[String.NameOfParentConstant].Type.AdjustValue());
		EndIf;
	EndDo;
	
	Return Result;
	
EndFunction

// Returns the values of constants controlled in the base version.
//
//	Returns:
//		Structure
//			The key is the name of the constant.
Function ValuesOfConstantsControlledInBaseVersion() Export 
	
	Result = New Structure;
	
	SystemSettingsLocalization.SupplementValuesOfConstantsControlledInBasicVersion(Result);
	
	Return Result;
	
EndFunction

// Returns a list of constants that are available for modification in the base version.
//
//	Returns:
//		Structure
//			The key is the name of the constant.
Function ConstantsAvailableInBasicVersion() Export 

	Result = New Structure;
	SystemSettingsLocalization.SupplementConstantsAvailableInBasicVersion(Result);
	
	Return Result;
	
EndFunction

// Returns the values of constants controlled in a NON-basic version.
//
//	Returns:
//		Structure
//			Key - name of the subordinate constant.
Function ValuesOfConstantsControlledInNonBaseVersion() Export 
	
	Result = New Structure;
	Result.Insert(Metadata.Constants.CalculationOfPermanentAndTemporaryDifferencesIsKeptCommon.Name, False);
	SystemSettingsLocalization.SupplementValuesOfConstantsControlledInNonBaseVersion(Result);
	
	Return Result;
	
EndFunction

// Returns a table describing the dependency of constants in the configuration.
// Each row in the table means:
// for a parent constant with the value X, only the value Y for the subordinate constant is allowed.
//
// Returns:
//	See SystemSettings.InitializeTableOfConstantValues
//
Function GetTableOfConstantDependencies() Export
	
	BaseVersion = StandardSubsystemsServer.IsBaseConfigurationVersion();
	
	Result = SystemSettings.InitializeTableOfConstantValues();
	
#Region Business_Processes_And_Tasks
	SystemSettings.AddRowToConstantDependencyTable(Result,
		Metadata.Constants.UseSalesOrderApproval.Name, True,
		Metadata.Constants.UseBusinessProcessesAndTasks.Name, True);
	SystemSettings.AddRowToConstantDependencyTable(Result,
		Metadata.Constants.UsePurchaseOrderApproval.Name, True,
		Metadata.Constants.UseBusinessProcessesAndTasks.Name, True);
	SystemSettings.AddRowToConstantDependencyTable(Result,
		Metadata.Constants.UseApprovalOfRequestsForReturnOfGoodsFromCustomers.Name, True,
		Metadata.Constants.UseBusinessProcessesAndTasks.Name, True);
	SystemSettings.AddRowToConstantDependencyTable(Result,
		Metadata.Constants.UseApprovalOfTermsOfSales.Name, True,
		Metadata.Constants.UseBusinessProcessesAndTasks.Name, True);
	SystemSettings.AddRowToConstantDependencyTable(Result,
		Metadata.Constants.UseApprovalOfItemPrices.Name, True,
		Metadata.Constants.UseBusinessProcessesAndTasks.Name, True);
	SystemSettings.AddRowToConstantDependencyTable(Result,
		Metadata.Constants.UseApprovalOfInventoryConsumptionOrders.Name, True,
		Metadata.Constants.UseBusinessProcessesAndTasks.Name, True);
	SystemSettings.AddRowToConstantDependencyTable(Result,
		Metadata.Constants.UseApprovalOfEngineeringChangeOrders.Name, True,
		Metadata.Constants.UseBusinessProcessesAndTasks.Name, True);
	SystemSettings.AddRowToConstantDependencyTable(Result,
		Metadata.Constants.UseBusinessProcessesAndTasks.Name, False,
		Metadata.Constants.UseSubordinateBusinessProcesses.Name, False);
	SystemSettings.AddRowToConstantDependencyTable(Result,
		Metadata.Constants.UseBusinessProcessesAndTasks.Name, False,
		Metadata.Constants.ChangeJobsBackdated.Name, False);
	SystemSettings.AddRowToConstantDependencyTable(Result,
		Metadata.Constants.UseBusinessProcessesAndTasks.Name, False,
		Metadata.Constants.UseTaskStartDate.Name, False);
	SystemSettings.AddRowToConstantDependencyTable(Result,
		Metadata.Constants.UseBusinessProcessesAndTasks.Name, False,
		Metadata.Constants.UseDateAndTimeInTaskDeadlines.Name, False);
#EndRegion
	
#Region Mail
	SystemSettings.AddRowToConstantDependencyTable(Result,
		Metadata.Constants.UseEmailClient.Name, False,
		Metadata.Constants.UseReviewedFlag.Name, False);
	SystemSettings.AddRowToConstantDependencyTable(Result,
		Metadata.Constants.UseEmailClient.Name, False,
		Metadata.Constants.UseOtherInteractions.Name, False);
	SystemSettings.AddRowToConstantDependencyTable(Result,
		Metadata.Constants.UseEmailClient.Name, False,
		Metadata.Constants.SendEmailsInHTMLFormat.Name, False);
#EndRegion
	
#Region Managing_Access
	SystemSettings.AddRowToConstantDependencyTable(Result,
		Metadata.Constants.LimitAccessAtRecordLevel.Name, False,
		Metadata.Constants.UsePartnerAccessGroups.Name, False);
	SystemSettings.AddRowToConstantDependencyTable(Result,
		Metadata.Constants.LimitAccessAtRecordLevel.Name, False,
		Metadata.Constants.UseItemAccessGroups.Name, False);
	SystemSettings.AddRowToConstantDependencyTable(Result,
		Metadata.Constants.LimitAccessAtRecordLevel.Name, False,
		Metadata.Constants.UseAccessGroupsOfItemKindsAndBudgetBalanceItems.Name, False);
#EndRegion

#Region FullText_research
	SystemSettings.AddRowToConstantDependencyTable(Result,
		Metadata.Constants.UseFullTextSearch.Name, False,
		Metadata.Constants.UseFullTextSearchWhenSelectingGoods.Name, False);
#EndRegion

#Region Weight_tower
	SystemSettings.AddRowToConstantDependencyTable(Result,
		Metadata.Constants.UsePackingOfGoodsSoldByWeight.Name, True,
		Metadata.Constants.WeightBarcodePrefix.Name, 2);
	SystemSettings.AddRowToConstantDependencyTable(Result,
		Metadata.Constants.UsePackingOfGoodsSoldByWeight.Name, False,
		Metadata.Constants.WeightBarcodePrefix.Name, 1);
#EndRegion
	
#Region Organizations_and_finances
	SystemSettings.AddRowToConstantDependencyTable(Result,
		Metadata.Constants.UseSalesOpportunitiesToCustomer.Name, False,
		Metadata.Constants.GenerateInventoryOwnerAttributesBySalesOpportunities.Name, False);
		
	SystemSettings.AddRowToConstantDependencyTable(Result,
		Metadata.Constants.UseBusinessUnits.Name, False,
		Metadata.Constants.GenerateInventoryOwnerAttributesByBusinessUnitsAndManagers.Name, False);
	SystemSettings.AddRowToConstantDependencyTable(Result,
		Metadata.Constants.UseBusinessUnits.Name, False,
		Metadata.Constants.UseCashFlowLimitsByBusinessUnit.Name,False);
	SystemSettings.AddRowToConstantDependencyTable(Result,
		Metadata.Constants.UseBusinessUnits.Name, False,
		Metadata.Constants.UseBranchOfficesWithSeparateBalanceSheets.Name, False);
		
	SystemSettings.AddRowToConstantDependencyTable(Result,
		Metadata.Constants.UseAccountingOfOtherIncomeExpenses.Name, False,
		Metadata.Constants.GenerateFinancialResult.Name, False);
	SystemSettings.AddRowToConstantDependencyTable(Result,
		Metadata.Constants.UseAccountingOfOtherIncomeExpenses.Name, False,
		Metadata.Constants.GenerateFutureExpenseCommitments.Name, False);
	SystemSettings.AddRowToConstantDependencyTable(Result,
		Metadata.Constants.UseMultipleCompanies.Name, True,
		Metadata.Constants.UseMultipleCashAccounts.Name, True);
	SystemSettings.AddRowToConstantDependencyTable(Result,
		Metadata.Constants.UseMultipleCompanies.Name, True,
		Metadata.Constants.UseSeveralCashRegisters.Name, True);
	SystemSettings.AddRowToConstantDependencyTable(Result,
		Metadata.Constants.UseMultipleCompanies.Name, True,
		Metadata.Constants.UseMultipleBankAccounts.Name, True);
	SystemSettings.AddRowToConstantDependencyTable(Result,
		Metadata.Constants.UseMultipleCompanies.Name, False,
		Metadata.Constants.UseBranchOfficesWithSeparateBalanceSheets.Name, False);
	SystemSettings.AddRowToConstantDependencyTable(Result,
		Metadata.Constants.UseMultipleCompanies.Name, False,
		Metadata.Constants.UseCustomerInvoiceIntercompany.Name, False);
	SystemSettings.AddRowToConstantDependencyTable(Result,
		Metadata.Constants.UseMultipleCompanies.Name, False,
		Metadata.Constants.UseInternalSubcontracting.Name, False);
	SystemSettings.AddRowToConstantDependencyTable(Result,
		Metadata.Constants.UseMultipleCompanies.Name, False,
		Metadata.Constants.UseManagementCompany.Name, False);
	SystemSettings.AddRowToConstantDependencyTable(Result,
		Metadata.Constants.UseMultipleCompanies.Name, False,
		Metadata.Constants.UseCashFlowLimitsByCompanies.Name, False);
	SystemSettings.AddRowToConstantDependencyTable(Result,
		Metadata.Constants.UseMultipleCompanies.Name, False,
		Metadata.Constants.UseIntercompanyContracts.Name, False);
	
	SystemSettings.AddRowToConstantDependencyTable(Result,
		Metadata.Constants.UseCustomerInvoiceIntercompany.Name, False,
		Metadata.Constants.TransferGoodsOfOtherCompanies.Name, False);
	
	SystemSettings.AddRowToConstantDependencyTable(Result,
		Metadata.Constants.UsePaymentRequests.Name, False,
		Metadata.Constants.UseCashFlowLimits.Name, False);
	SystemSettings.AddRowToConstantDependencyTable(Result,
		Metadata.Constants.UsePaymentRequests.Name, False,
		Metadata.Constants.UseCashFlowLimitsByCompanies.Name, False);
	SystemSettings.AddRowToConstantDependencyTable(Result,
		Metadata.Constants.UsePaymentRequests.Name, False,
		Metadata.Constants.UseCashFlowLimitsByBusinessUnit.Name, False);
	SystemSettings.AddRowToConstantDependencyTable(Result,
		Metadata.Constants.UsePaymentRequests.Name, False,
		Metadata.Constants.ControlExcessOfCashFlowLimits.Name, False);
	SystemSettings.AddRowToConstantDependencyTable(Result,
		Metadata.Constants.UsePaymentRequests.Name, False,
		Metadata.Constants.UseBudgetingCashFlowLimits.Name, False);
	SystemSettings.AddRowToConstantDependencyTable(Result,
		Metadata.Constants.UseCashFlowLimits.Name, True,
		Metadata.Constants.ControlExcessOfCashFlowLimits.Name, True);
	SystemSettings.AddRowToConstantDependencyTable(Result,
		Metadata.Constants.UseCashFlowLimits.Name, True,
		Metadata.Constants.UseBudgetingCashFlowLimits.Name, False);
	SystemSettings.AddRowToConstantDependencyTable(Result,
		Metadata.Constants.UseCashFlowLimits.Name, False,
		Metadata.Constants.UseCashFlowLimitsByCompanies.Name, False);
	SystemSettings.AddRowToConstantDependencyTable(Result,
		Metadata.Constants.UseCashFlowLimits.Name, False,
		Metadata.Constants.UseCashFlowLimitsByBusinessUnit.Name, False);
	SystemSettings.AddRowToConstantDependencyTable(Result,
		Metadata.Constants.UseCashFlowLimits.Name, False,
		Metadata.Constants.ControlExcessOfCashFlowLimits.Name, False);
		
	SystemSettings.AddRowToConstantDependencyTable(Result,
		Metadata.Constants.UsePaymentRequests.Name, True,
		Metadata.Constants.UseCashPaymentJournal.Name, False);
	
	SystemSettings.AddRowToConstantDependencyTable(Result,
		Metadata.Constants.UseCurrencyPayments.Name, True,
		Metadata.Constants.UseMultipleCurrencies.Name, True);
	
	SystemSettings.AddRowToConstantDependencyTable(Result,
		Metadata.Constants.UseCurrencyPayments.Name, True,
		Metadata.Constants.UseContractsWithVendors.Name, True);
	
	SystemSettings.AddRowToConstantDependencyTable(Result,
		Metadata.Constants.UseAccountingOfOtherIncomeExpenses.Name, False,
		Metadata.Constants.UseAccountingOfOtherIncomeExpensesInLocalAccounting.Name, False);
	SystemSettings.AddRowToConstantDependencyTable(Result,
		Metadata.Constants.UseAccountingOfOtherIncomeExpenses.Name, True,
		Metadata.Constants.UseAccountingOfOtherIncomeExpensesInLocalAccounting.Name, True);
		
	SystemSettings.AddRowToConstantDependencyTable(Result,
		Metadata.Constants.UseFinancialAccountingGroups.Name, True,
		Metadata.Constants.GenerateInventoryOwnerAttributesByFinancialAccountingGroups.Name, True);
	SystemSettings.AddRowToConstantDependencyTable(Result,
		Metadata.Constants.UseFinancialAccountingGroups.Name, False,
		Metadata.Constants.GenerateInventoryOwnerAttributesByFinancialAccountingGroups.Name, False);
#EndRegion
	
#Region New_Architecture_OfCalculations
	
	SystemSettings.AddRowToConstantDependencyTable(Result,
		Metadata.Constants.NewOnlineARAPAccounting.Name, True,
		Metadata.Constants.UpdateARAPAccountingWhilePostingDocuments.Name, False);
	
	SystemSettings.AddRowToConstantDependencyTable(Result,
		Metadata.Constants.NewOnlineARAPAccounting.Name, True,
		Metadata.Constants.UpdateARAPAccountingWhileGeneratingReports.Name, False);
	
	SystemSettings.AddRowToConstantDependencyTable(Result,
		Metadata.Constants.NewOnlineARAPAccounting.Name, False, 
		Metadata.Constants.AllocateARAPInBackgroundJob.Name, False);
	
	SystemSettings.AddRowToConstantDependencyTable(Result,
		Metadata.Constants.NewOnlineARAPAccounting.Name, False, 
		Metadata.Constants.UseDocumentCorrection.Name, False);
	
#EndRegion
	
#Region Warehouse_and_distribution
	SystemSettings.AddRowToConstantDependencyTable(Result,
		Metadata.Constants.UseWarehouseManagementSystem.Name, False,
		Metadata.Constants.UsePackingLists.Name, False);
	SystemSettings.AddRowToConstantDependencyTable(Result,
		Metadata.Constants.UseSeveralWarehouses.Name, False,
		Metadata.Constants.UseGoodsTransfer.Name, False);
	SystemSettings.AddRowToConstantDependencyTable(Result,
		Metadata.Constants.UseSeveralWarehouses.Name, False,
		Metadata.Constants.UseWarehousesInTabularSectionsOfSalesDocuments.Name, False);
	SystemSettings.AddRowToConstantDependencyTable(Result,
		Metadata.Constants.UseSeveralWarehouses.Name, False,
		Metadata.Constants.UseWarehousesInTabularSectionsOfPurchaseDocuments.Name, False);
	
	SystemSettings.AddRowToConstantDependencyTable(Result,
		Metadata.Constants.UseGoodsTransfer.Name, False,
		Metadata.Constants.UseTransferOrders.Name, False);
	SystemSettings.AddRowToConstantDependencyTable(Result,
		Metadata.Constants.UseGoodsTransfer.Name, False,
		Metadata.Constants.UseGoodsTransferStatuses.Name, False);
	SystemSettings.AddRowToConstantDependencyTable(Result,
		Metadata.Constants.UseGoodsTransfer.Name, False,
		Metadata.Constants.TransferGoodsOfOtherCompanies.Name, False);
	SystemSettings.AddRowToConstantDependencyTable(Result,
		Metadata.Constants.UseGoodsTransfer.Name, False,
		Metadata.Constants.UseNonConformanceCertificatesFollowingTransfer.Name, False);
		
	SystemSettings.AddRowToConstantDependencyTable(Result,
		Metadata.Constants.UseTransferOrders.Name, False,
		Metadata.Constants.UseTransferAgainstSeveralOrders.Name, False);
	SystemSettings.AddRowToConstantDependencyTable(Result,
		Metadata.Constants.UseTransferOrders.Name, False,
		Metadata.Constants.UseStatusesOfTransferOrders.Name, False);
	SystemSettings.AddRowToConstantDependencyTable(Result,
		Metadata.Constants.UseTransferOrders.Name, False,
		Metadata.Constants.DoNotCloseTransferOrdersWithoutCompleteShipment.Name, False);
		
	SystemSettings.AddRowToConstantDependencyTable(Result,
		Metadata.Constants.UseStatusesOfTransferOrders.Name, False,
		Metadata.Constants.DoNotCloseTransferOrdersWithoutCompleteShipment.Name,False);
	
	SystemSettings.AddRowToConstantDependencyTable(Result,
		Metadata.Constants.UseDeliveryManagement.Name, False,
		Metadata.Constants.EditDeliveryAddressesOnlyInDialogBox.Name, False);
	
	SystemSettings.AddRowToConstantDependencyTable(Result,
		Metadata.Constants.UseDeliveryManagement.Name, False,
		Metadata.Constants.NotUseDeliveryManagement20.Name, False);
	
	SystemSettings.AddRowToConstantDependencyTable(Result,
		Metadata.Constants.UseDeliveryManagement.Name, False,
		Metadata.Constants.NotUseDeliveryManagement25.Name, False);
	
	SystemSettings.AddRowToConstantDependencyTable(Result,
		Metadata.Constants.NotUseDeliveryManagement20.Name, True,
		Metadata.Constants.UseTransportationJobsForDeliveryAccountingByCarriers.Name, False);
	
	SystemSettings.AddRowToConstantDependencyTable(Result,
		Metadata.Constants.UseInventoryConsumptionOrders.Name, False,
		Metadata.Constants.UseApprovalOfInventoryConsumptionOrders.Name, False);
	SystemSettings.AddRowToConstantDependencyTable(Result,
		Metadata.Constants.UseGoodsQualityControl.Name, False,
		Metadata.Constants.UseGoodsQualityResearch.Name, False);
	SystemSettings.AddRowToConstantDependencyTable(Result,
		Metadata.Constants.UsePurchaseRequests.Name, False,
		Metadata.Constants.UseIEBLimitsOnPurchases.Name, False);
		
	SystemSettings.AddRowToConstantDependencyTable(Result,
		Metadata.Constants.UseProvisionRequests.Name, False,
		Metadata.Constants.UseIEBLimitsOnConsumption.Name, False);
#EndRegion

#Region NomenclatureSettings
	SystemSettings.AddRowToConstantDependencyTable(Result,
		Metadata.Constants.UseMultipleKindsOfProducts.Name, False,
		Metadata.Constants.UseSets.Name, False);
		
	SystemSettings.AddRowToConstantDependencyTable(Result,
		Metadata.Constants.UseMultipleKindsOfProducts.Name, False,
		Metadata.Constants.UseReusablePackage.Name, False);
		
	SystemSettings.AddRowToConstantDependencyTable(Result,
		Metadata.Constants.UseGoodsQuality.Name, False,
		Metadata.Constants.UseSummaryAccountingOfLowQualityGoods.Name, False);
	
	SystemSettings.AddRowToConstantDependencyTable(Result,
		Metadata.Constants.UseReusablePackage.Name, False,
		Metadata.Constants.OfferToSupplementReusablePackageDocuments.Name, False);
		
	SystemSettings.AddRowToConstantDependencyTable(Result,
		Metadata.Constants.UseItemsBatch.Name, False,
		Metadata.Constants.DisplayBatchInPrintForms.Name, False);
		
#EndRegion
	
#Region Marketing_and_CRM
	SystemSettings.AddRowToConstantDependencyTable(Result,
		Metadata.Constants.UseSeveralPriceTypes.Name, False,
		Metadata.Constants.GoodsCostWhenEvaluatingSalesProfitability.Name, Enums.GoodsCostWhenEvaluatingSalesProfitability.ByEstimatedCost);
	SystemSettings.AddRowToConstantDependencyTable(Result,
		Metadata.Constants.UseDiscountAdjustmentsInSales.Name, False,
		Metadata.Constants.UseLimitsForDiscountAdjustmentsInSalesByTermsOfSales.Name, False);
	SystemSettings.AddRowToConstantDependencyTable(Result,
		Metadata.Constants.UseDiscountAdjustmentsInSales.Name, False,
		Metadata.Constants.UseLimitsForDiscountAdjustmentsInSalesByUsers.Name, False);

	SystemSettings.AddRowToConstantDependencyTable(Result,
		Metadata.Constants.UseDiscountsMarkupsInSales.Name, False,
		Metadata.Constants.UseLoyaltyCards.Name, False);
	SystemSettings.AddRowToConstantDependencyTable(Result,
		Metadata.Constants.UseDiscountsMarkupsInSales.Name, False,
		Metadata.Constants.UseLoyaltyPrograms.Name, False);
	
	SystemSettings.AddRowToConstantDependencyTable(Result,
		Metadata.Constants.UseCustomerRebates.Name, False,
		Metadata.Constants.UseApprovalOfCustomerRebatesWriteOffs.Name, False);
	
	SystemSettings.AddRowToConstantDependencyTable(Result,
		Metadata.Constants.UseCustomerRebates.Name, False,
		Metadata.Constants.DisplayFullNamesOfCustomerRebates.Name, False);
#EndRegion

#Region Sales
	SystemSettings.AddRowToConstantDependencyTable(Result,
		Metadata.Constants.UseTermsOfSales.Name, Enums.UseTermsOfSales.StandardAndIndividualTermsOfSales,
		Metadata.Constants.UseStandardAndIndividualTermsOfSalesWithCustomers.Name, True);
	SystemSettings.AddRowToConstantDependencyTable(Result,
		Metadata.Constants.UseTermsOfSales.Name, Enums.UseTermsOfSales.StandardAndIndividualTermsOfSales,
		Metadata.Constants.UseStandardTermsOfSalesWithCustomers.Name, True);
	SystemSettings.AddRowToConstantDependencyTable(Result,
		Metadata.Constants.UseTermsOfSales.Name, Enums.UseTermsOfSales.StandardAndIndividualTermsOfSales,
		Metadata.Constants.UseCustomerTermsOfSales.Name, True);
	SystemSettings.AddRowToConstantDependencyTable(Result,
		Metadata.Constants.UseTermsOfSales.Name, Enums.UseTermsOfSales.StandardAndIndividualTermsOfSales,
		Metadata.Constants.ToUseTermsOfSales.Name, True);
	SystemSettings.AddRowToConstantDependencyTable(Result,
		Metadata.Constants.UseTermsOfSales.Name, Enums.UseTermsOfSales.OnlyStandardTermsOfSales,
		Metadata.Constants.UseStandardAndIndividualTermsOfSalesWithCustomers.Name, False);
	SystemSettings.AddRowToConstantDependencyTable(Result,
		Metadata.Constants.UseTermsOfSales.Name, Enums.UseTermsOfSales.OnlyStandardTermsOfSales,
		Metadata.Constants.UseStandardTermsOfSalesWithCustomers.Name, True);
	SystemSettings.AddRowToConstantDependencyTable(Result,
		Metadata.Constants.UseTermsOfSales.Name, Enums.UseTermsOfSales.OnlyStandardTermsOfSales,
		Metadata.Constants.UseCustomerTermsOfSales.Name, False);
	SystemSettings.AddRowToConstantDependencyTable(Result,
		Metadata.Constants.UseTermsOfSales.Name, Enums.UseTermsOfSales.OnlyStandardTermsOfSales,
		Metadata.Constants.ToUseTermsOfSales.Name, True);
	SystemSettings.AddRowToConstantDependencyTable(Result,
		Metadata.Constants.UseTermsOfSales.Name, Enums.UseTermsOfSales.OnlySpecialTermsOfSales,
		Metadata.Constants.UseStandardAndIndividualTermsOfSalesWithCustomers.Name, False);
	SystemSettings.AddRowToConstantDependencyTable(Result,
		Metadata.Constants.UseTermsOfSales.Name, Enums.UseTermsOfSales.OnlySpecialTermsOfSales,
		Metadata.Constants.UseStandardTermsOfSalesWithCustomers.Name, False);
	SystemSettings.AddRowToConstantDependencyTable(Result,
		Metadata.Constants.UseTermsOfSales.Name, Enums.UseTermsOfSales.OnlySpecialTermsOfSales,
		Metadata.Constants.UseCustomerTermsOfSales.Name, True);
	SystemSettings.AddRowToConstantDependencyTable(Result,
		Metadata.Constants.UseTermsOfSales.Name, Enums.UseTermsOfSales.OnlySpecialTermsOfSales,
		Metadata.Constants.ToUseTermsOfSales.Name, True);
	SystemSettings.AddRowToConstantDependencyTable(Result,
		Metadata.Constants.UseTermsOfSales.Name, Enums.UseTermsOfSales.DontUse,
		Metadata.Constants.UseStandardAndIndividualTermsOfSalesWithCustomers.Name, False);
	SystemSettings.AddRowToConstantDependencyTable(Result,
		Metadata.Constants.UseTermsOfSales.Name, Enums.UseTermsOfSales.DontUse,
		Metadata.Constants.UseStandardTermsOfSalesWithCustomers.Name, False);
	SystemSettings.AddRowToConstantDependencyTable(Result,
		Metadata.Constants.UseTermsOfSales.Name, Enums.UseTermsOfSales.DontUse,
		Metadata.Constants.UseCustomerTermsOfSales.Name, False);
	SystemSettings.AddRowToConstantDependencyTable(Result,
		Metadata.Constants.UseTermsOfSales.Name, Enums.UseTermsOfSales.DontUse,
		Metadata.Constants.ToUseTermsOfSales.Name, False);
	SystemSettings.AddRowToConstantDependencyTable(Result,
		Metadata.Constants.UseTermsOfSales.Name, Enums.UseTermsOfSales.DontUse,
		Metadata.Constants.UseApprovalOfTermsOfSales.Name, False);
	SystemSettings.AddRowToConstantDependencyTable(Result,
		Metadata.Constants.UseTermsOfSales.Name, Enums.UseTermsOfSales.DontUse,
		Metadata.Constants.UseLimitsForDiscountAdjustmentsInSalesByTermsOfSales.Name, False);
	
	SystemSettings.AddRowToConstantDependencyTable(Result,
		Metadata.Constants.WorkIsExecutedViaSalesRepresentatives.Name, True,
		Metadata.Constants.UseSalesOrders.Name, True);
		
	SystemSettings.AddRowToConstantDependencyTable(Result,
		Metadata.Constants.UseSalesOrders.Name, False,
		Metadata.Constants.UseCustomerInvoicesForSeveralOrders.Name, False);
	SystemSettings.AddRowToConstantDependencyTable(Result,
		Metadata.Constants.UseSalesOrders.Name, False,
		Metadata.Constants.UseSaleByMultipleOrders.Name, False);
	SystemSettings.AddRowToConstantDependencyTable(Result,
		Metadata.Constants.UseSalesOrders.Name, False,
		Metadata.Constants.UseSalesOrderApproval.Name, False);
	SystemSettings.AddRowToConstantDependencyTable(Result,
		Metadata.Constants.UseAdvancedFeaturesOfSalesOrder.Name, False,
		Metadata.Constants.UseShipmentByRowsInSalesOrder.Name, False);
	SystemSettings.AddRowToConstantDependencyTable(Result,
		Metadata.Constants.UseAdvancedFeaturesOfSalesOrder.Name, False,
		Metadata.Constants.UseReasonsForSalesOrderCancellations.Name, False);
		
	SystemSettings.AddRowToConstantDependencyTable(Result,
		Metadata.Constants.UseAdvancedFeaturesOfSalesOrder.Name, False,
		Metadata.Constants.UseOrderMovementReport.Name, False);
		
	SystemSettings.AddRowToConstantDependencyTable(Result,
		Metadata.Constants.UseRequestsForReturnOfGoodsFromCustomers.Name, False,
		Metadata.Constants.UseApprovalOfRequestsForReturnOfGoodsFromCustomers.Name, False);
	
	SystemSettings.AddRowToConstantDependencyTable(Result,
		Metadata.Constants.GoodsCostWhenEvaluatingSalesProfitability.Name, Enums.GoodsCostWhenEvaluatingSalesProfitability.ByEstimatedCost, 
		Metadata.Constants.StandardPriceType.Name, Catalogs.TypesOfPrices.EmptyRef());
	SystemSettings.AddRowToConstantDependencyTable(Result,
		Metadata.Constants.UseAdvancedFeaturesOfSalesOrder.Name, False,
		Metadata.Constants.UseSalesOrderApproval.Name, False);
	
	SystemSettings.AddRowToConstantDependencyTable(Result,
		Metadata.Constants.UseAdvancedFeaturesOfSalesOrder.Name, False,
		Metadata.Constants.UseApprovalOfRequestsForReturnOfGoodsFromCustomers.Name, False);
		
	SystemSettings.AddRowToConstantDependencyTable(Result,
		Metadata.Constants.UseStatusesOfGoodsServicesSales.Name, False,
		Metadata.Constants.UseShipmentWithDeferredTransferOfTitle2_0.Name, False);
		
	SystemSettings.AddRowToConstantDependencyTable(Result,
		Metadata.Constants.UseShipmentWithDeferredTransferOfTitle.Name, False,
		Metadata.Constants.UseShipmentWithDeferredTransferOfTitle2_0.Name, False);
		
	SystemSettings.AddRowToConstantDependencyTable(Result,
		Metadata.Constants.UseShipmentWithDeferredTransferOfTitle.Name, False,
		Metadata.Constants.UseShipmentWithDeferredTransferOfTitle2_5.Name, False);
		
	SystemSettings.AddRowToConstantDependencyTable(Result,
		Metadata.Constants.UsePaymentStepsInSales.Name, Enums.UsePaymentSteps.SimplifiedScheme,
		Metadata.Constants.UseSimplifiedPaymentSchemeInSales.Name, True);
	SystemSettings.AddRowToConstantDependencyTable(Result,
		Metadata.Constants.UsePaymentStepsInSales.Name, Enums.UsePaymentSteps.SimplifiedScheme,
		Metadata.Constants.UsePaymentSchedules.Name, False);
	SystemSettings.AddRowToConstantDependencyTable(Result,
		Metadata.Constants.UsePaymentStepsInSales.Name, Enums.UsePaymentSteps.CustomSettings,
		Metadata.Constants.UseSimplifiedPaymentSchemeInSales.Name, False);
	SystemSettings.AddRowToConstantDependencyTable(Result,
		Metadata.Constants.UsePaymentStepsInSales.Name, Enums.UsePaymentSteps.CustomSettings,
		Metadata.Constants.UsePaymentSchedules.Name, False);
	SystemSettings.AddRowToConstantDependencyTable(Result,
		Metadata.Constants.UsePaymentStepsInSales.Name, Enums.UsePaymentSteps.PaymentSchedules,
		Metadata.Constants.UseSimplifiedPaymentSchemeInSales.Name, False);
	SystemSettings.AddRowToConstantDependencyTable(Result,
		Metadata.Constants.UsePaymentStepsInSales.Name, Enums.UsePaymentSteps.PaymentSchedules,
		Metadata.Constants.UsePaymentSchedules.Name, True);
	
	SystemSettings.AddRowToConstantDependencyTable(Result,
		Metadata.Constants.UseShipmentProhibition.Name, True,
		Metadata.Constants.UsePartnersSegments.Name, True);
	
	SystemSettings.AddRowToConstantDependencyTable(Result,
		Metadata.Constants.UseTransferToCustodyWithRightOfSale.Name, True,
		Metadata.Constants.UseCustomerContracts.Name, True);
	
	SystemSettings.AddRowToConstantDependencyTable(Result,
		Metadata.Constants.UseRetailSales.Name, False,
		Metadata.Constants.UseGiftCards.Name, False);
		
	SystemSettings.AddRowToConstantDependencyTable(Result,
		Metadata.Constants.UseAllowableDeviationOfMeasuringGoodsShipmentReceiving.Name, False,
		Metadata.Constants.AllowableDeviationOfMeasuringGoodsShipmentAndReceiving.Name, 0);
		
#EndRegion

#Region Trade_representatives
	SystemSettings.AddRowToConstantDependencyTable(Result,
		Metadata.Constants.WorkIsExecutedViaSalesRepresentatives.Name, False,
		Metadata.Constants.UseJobsToSalesRepresentatives.Name, Enums.UseJobsToSalesRepresentatives.NotUsed_);
	
	SystemSettings.AddRowToConstantDependencyTable(Result,
		Metadata.Constants.UseJobsToSalesRepresentatives.Name, Enums.UseJobsToSalesRepresentatives.NotUsed_,
		Metadata.Constants.ItemizeJobsForSalesRepresentatives.Name, False);
	SystemSettings.AddRowToConstantDependencyTable(Result,
		Metadata.Constants.UseJobsToSalesRepresentatives.Name, Enums.UseJobsToSalesRepresentatives.NotUsed_,
		Metadata.Constants.NotItemizeJobsForSalesRepresentatives.Name, False);
	
	SystemSettings.AddRowToConstantDependencyTable(Result,
		Metadata.Constants.UseJobsToSalesRepresentatives.Name, Enums.UseJobsToSalesRepresentatives.UsedForManagementBySalesRepresentatives,
		Metadata.Constants.UseJobsToManageSalesRepresentatives.Name, True);
	SystemSettings.AddRowToConstantDependencyTable(Result,
		Metadata.Constants.UseJobsToSalesRepresentatives.Name, Enums.UseJobsToSalesRepresentatives.UsedBySalesRepresentativesForPlanning,
		Metadata.Constants.UseJobsToManageSalesRepresentatives.Name, False);
	SystemSettings.AddRowToConstantDependencyTable(Result,
		Metadata.Constants.UseJobsToSalesRepresentatives.Name, Enums.UseJobsToSalesRepresentatives.NotUsed_,
		Metadata.Constants.UseJobsToManageSalesRepresentatives.Name, False);
	
	SystemSettings.AddRowToConstantDependencyTable(Result,
		Metadata.Constants.UseJobsToSalesRepresentatives.Name, Enums.UseJobsToSalesRepresentatives.UsedBySalesRepresentativesForPlanning,
		Metadata.Constants.UseJobsToSalesRepresentativesForPlanning.Name, True);
	SystemSettings.AddRowToConstantDependencyTable(Result,
		Metadata.Constants.UseJobsToSalesRepresentatives.Name, Enums.UseJobsToSalesRepresentatives.UsedForManagementBySalesRepresentatives,
		Metadata.Constants.UseJobsToSalesRepresentativesForPlanning.Name, False);
	SystemSettings.AddRowToConstantDependencyTable(Result,
		Metadata.Constants.UseJobsToSalesRepresentatives.Name, Enums.UseJobsToSalesRepresentatives.NotUsed_,
		Metadata.Constants.UseJobsToSalesRepresentativesForPlanning.Name, False);
#EndRegion

#Region Inventory_and_Purchases
	SystemSettings.AddRowToConstantDependencyTable(Result,
		Metadata.Constants.UsePurchaseOrders.Name, False,
		Metadata.Constants.UsePurchaseOrderApproval.Name, False);
	SystemSettings.AddRowToConstantDependencyTable(Result,
		Metadata.Constants.UsePurchaseOrders.Name, False,
		Metadata.Constants.UseReceiptForMultipleOrders.Name, False);
	SystemSettings.AddRowToConstantDependencyTable(Result,
		Metadata.Constants.UsePurchaseOrders.Name, False,
		Metadata.Constants.DoNotClosePurchaseOrdersBeforeAllGoodsAreReceived.Name, False);
	SystemSettings.AddRowToConstantDependencyTable(Result,
		Metadata.Constants.UsePurchaseOrders.Name, False,
		Metadata.Constants.DoNotClosePurchaseOrdersWithoutCompletePayment.Name, False);
	SystemSettings.AddRowToConstantDependencyTable(Result,
		Metadata.Constants.UsePurchaseOrders.Name, False,
		Metadata.Constants.UsePurchaseOrderStatuses.Name, False);
	SystemSettings.AddRowToConstantDependencyTable(Result,
		Metadata.Constants.UsePurchaseOrders.Name, False,
		Metadata.Constants.UseReasonsForPurchaseOrderCancellations.Name, False);
	
	SystemSettings.AddRowToConstantDependencyTable(Result,
		Metadata.Constants.UseInventoryConsumptionOrders.Name, False,
		Metadata.Constants.UseInventoryConsumptionForMultipleOrders.Name, False);
	SystemSettings.AddRowToConstantDependencyTable(Result,
		Metadata.Constants.UseInventoryConsumptionOrders.Name, False,
		Metadata.Constants.UseStatusesOfInventoryConsumptionOrders.Name, False);
	SystemSettings.AddRowToConstantDependencyTable(Result,
		Metadata.Constants.UseInventoryConsumptionOrders.Name, False,
		Metadata.Constants.DoNotCloseInventoryConsumptionOrdersWithoutCompleteShipment.Name, False);
	
	SystemSettings.AddRowToConstantDependencyTable(Result,
		Metadata.Constants.UseUninvoicedDeliveries.Name, True,
		Metadata.Constants.UseContractsWithVendors.Name, True);
	
	SystemSettings.AddRowToConstantDependencyTable(Result,
		Metadata.Constants.UseCustodyDuringPurchase.Name, True,
		Metadata.Constants.UseContractsWithVendors.Name, True);
	
	SystemSettings.AddRowToConstantDependencyTable(Result,
		Metadata.Constants.UseUninvoicedDeliveries.Name, False,
		Metadata.Constants.UseImportOfGoodsFromCustomsUnionUninvoicedDeliveries.Name, False);
	
	SystemSettings.AddRowToConstantDependencyTable(Result,
		Metadata.Constants.UseUninvoicedDeliveries.Name, True,
		Metadata.Constants.AllocationOfAdditionalExpensesByDisposedGoods.Name, True);
		
	SystemSettings.AddRowToConstantDependencyTable(Result,
		Metadata.Constants.UseStatusesOfInventoryConsumptionOrders.Name, False,
		Metadata.Constants.DoNotCloseInventoryConsumptionOrdersWithoutCompleteShipment.Name, False);
	
	SystemSettings.AddRowToConstantDependencyTable(Result,
		Metadata.Constants.UseGoodsInTransitFromVendors.Name, True,
		Metadata.Constants.UseContractsWithVendors.Name, True);
	
	SystemSettings.AddRowToConstantDependencyTable(Result,
		Metadata.Constants.UseGoodsInTransitFromVendors.Name, False,
		Metadata.Constants.UseImportedPurchasesOfGoodsInTransit.Name, False);
		
	SystemSettings.AddRowToConstantDependencyTable(Result,
		Metadata.Constants.UseGoodsInTransitFromVendors.Name, False,
		Metadata.Constants.AllocationOfAdditionalExpensesOnGoodsInTransitFromVendors.Name, False);
	
	SystemSettings.AddRowToConstantDependencyTable(Result,
		Metadata.Constants.UseInventoryConsumption.Name, False,
		Metadata.Constants.UseInventoryConsumptionOrders.Name, False);
	SystemSettings.AddRowToConstantDependencyTable(Result,
		Metadata.Constants.UseInventoryConsumption.Name, False,
		Metadata.Constants.UseInventoryConsumptionForMultipleOrders.Name, False);
		
	SystemSettings.AddRowToConstantDependencyTable(Result,
		Metadata.Constants.UseInventoryConsumption.Name, False,
		Metadata.Constants.UseInventoryConsumptionStatuses.Name, False);
	
	SystemSettings.AddRowToConstantDependencyTable(Result,
		Metadata.Constants.UseAssemblyDisassembly.Name, False,
		Metadata.Constants.UseAssemblyDisassemblyOrders.Name, False);
	SystemSettings.AddRowToConstantDependencyTable(Result,
		Metadata.Constants.UseAssemblyDisassembly.Name, False,
		Metadata.Constants.UseGoodsAssemblyStatuses.Name, False);
	SystemSettings.AddRowToConstantDependencyTable(Result,
		Metadata.Constants.UseAssemblyDisassembly.Name, False,
		Metadata.Constants.UseAssemblyDisassemblyPlanning.Name, False);
	
	SystemSettings.AddRowToConstantDependencyTable(Result,
		Metadata.Constants.UseAssemblyDisassemblyOrders.Name, False,
		Metadata.Constants.UseStatusesOfAssemblyOrders.Name, False);
	SystemSettings.AddRowToConstantDependencyTable(Result,
		Metadata.Constants.UseAssemblyDisassemblyOrders.Name, False,
		Metadata.Constants.DoNotCloseAssemblyOrdersWithoutCompleteShipment.Name, False);
		
	SystemSettings.AddRowToConstantDependencyTable(Result,
		Metadata.Constants.UseStatusesOfAssemblyOrders.Name, False,
		Metadata.Constants.DoNotCloseAssemblyOrdersWithoutCompleteShipment.Name, False);
	
	SystemSettings.AddRowToConstantDependencyTable(Result,
		Metadata.Constants.UsePurchaseOrderStatuses.Name, False,
		Metadata.Constants.UsePurchaseOrderApproval.Name, False);
	SystemSettings.AddRowToConstantDependencyTable(Result,
		Metadata.Constants.UsePurchaseOrderStatuses.Name, False,
		Metadata.Constants.DoNotClosePurchaseOrdersBeforeAllGoodsAreReceived.Name, False);
	SystemSettings.AddRowToConstantDependencyTable(Result,
		Metadata.Constants.UsePurchaseOrderStatuses.Name, False,
		Metadata.Constants.DoNotClosePurchaseOrdersWithoutCompletePayment.Name, False);
		
	SystemSettings.AddRowToConstantDependencyTable(Result,
		Metadata.Constants.UsePaymentStepsInPurchases.Name, Enums.UsePaymentSteps.SimplifiedScheme,
		Metadata.Constants.UseSimplifiedPaymentSchemeInPurchasing.Name, True);
	SystemSettings.AddRowToConstantDependencyTable(Result,
		Metadata.Constants.UsePaymentStepsInPurchases.Name, Enums.UsePaymentSteps.CustomSettings,
		Metadata.Constants.UseSimplifiedPaymentSchemeInPurchasing.Name, False);
		
	SystemSettings.AddRowToConstantDependencyTable(Result,
		Metadata.Constants.UsePurchaseCommission.Name, True,
			Metadata.Constants.UseBasePurchaseCommission.Name, True And BaseVersion);
	SystemSettings.AddRowToConstantDependencyTable(Result,
		Metadata.Constants.UsePurchaseCommission.Name, True,
			Metadata.Constants.UseNonBasePurchaseCommission.Name, True And Not BaseVersion);
	SystemSettings.AddRowToConstantDependencyTable(Result,
		Metadata.Constants.UsePurchaseCommission.Name, False,
			Metadata.Constants.UseBasePurchaseCommission.Name, False);
	SystemSettings.AddRowToConstantDependencyTable(Result,
		Metadata.Constants.UsePurchaseCommission.Name, False,
		Metadata.Constants.UseNonBasePurchaseCommission.Name, False);
	
	SystemSettings.AddRowToConstantDependencyTable(Result,
		Metadata.Constants.OnlyConsignmentSales25.Name, True,
		Metadata.Constants.ConsignmentSaleIsUsed20.Name, False);
	
	SystemSettings.AddRowToConstantDependencyTable(Result,
		Metadata.Constants.UseOrderSupplyWithAssignment.Name, False,
		Metadata.Constants.AllowAssignmentOfGoodsBeyondDemand.Name, False);
	
	SystemSettings.AddRowToConstantDependencyTable(Result,
		Metadata.Constants.UseVendorRebates.Name, False,
		Metadata.Constants.UseApprovalOfVendorRebateWriteOffs.Name, False);
	
	SystemSettings.AddRowToConstantDependencyTable(Result,
		Metadata.Constants.UseVendorRebates.Name, False,
		Metadata.Constants.DisplayFullNamesOfVendorRebates.Name, False);
	
	SystemSettings.AddRowToConstantDependencyTable(Result,
		Metadata.Constants.UsePurchaseOrders.Name, False,
		Metadata.Constants.UsePurchaseRequests.Name, False);
	
#EndRegion

#Region Printed_forms_reports_and_processing
	SystemSettings.AddRowToConstantDependencyTable(Result,
		Metadata.Constants.DisplayDiscountsInPrintFormsOfSalesDocuments.Name, Enums.OptionsOfDiscountsDisplayingInPrintForms.DisplayDiscounts,
		Metadata.Constants.SelectAnOptionOfDiscountDisplayWhilePrintingSalesDocuments.Name, False);
	SystemSettings.AddRowToConstantDependencyTable(Result,
		Metadata.Constants.DisplayDiscountsInPrintFormsOfSalesDocuments.Name, Enums.OptionsOfDiscountsDisplayingInPrintForms.NotDisplayDiscounts,
		Metadata.Constants.SelectAnOptionOfDiscountDisplayWhilePrintingSalesDocuments.Name, False);
	SystemSettings.AddRowToConstantDependencyTable(Result,
		Metadata.Constants.DisplayDiscountsInPrintFormsOfSalesDocuments.Name, Enums.OptionsOfDiscountsDisplayingInPrintForms.SelectWhilePrinting,
		Metadata.Constants.SelectAnOptionOfDiscountDisplayWhilePrintingSalesDocuments.Name, True);
	SystemSettings.AddRowToConstantDependencyTable(Result,
		Metadata.Constants.UseVATAccounting.Name, False,
		Metadata.Constants.DisplayAdditionalVATColumns.Name, False);
#EndRegion
	
#Region Mobile_application_1S_Orders
	SystemSettings.AddRowToConstantDependencyTable(Result,
		Metadata.Constants.Use1COrdersMobileApplication.Name, True,
		Metadata.Constants.UseSalesOrders.Name, True);
#EndRegion
	#Region TransferToRecycling
	
	SystemSettings.AddRowToConstantDependencyTable(Result,
		Metadata.Constants.NewOnlineARAPAccounting.Name, False,
		Metadata.Constants.UseProductionByThirdParty2_5.Name, False);
	
	SystemSettings.AddRowToConstantDependencyTable(Result,
		Metadata.Constants.UseProductionByThirdParty2_5.Name, True,
		Metadata.Constants.UseContractsWithVendors.Name, True);
	
	SystemSettings.AddRowToConstantDependencyTable(Result,
		Metadata.Constants.UseProductionByThirdParty2_5.Name, True,
		Metadata.Constants.UseBusinessUnits.Name, True);
	
	SystemSettings.AddRowToConstantDependencyTable(Result,
		Metadata.Constants.UseProductionByThirdParty2_5.Name, True,
		Metadata.Constants.UseMultipleKindsOfProducts.Name, True);
	
	SystemSettings.AddRowToConstantDependencyTable(Result,
		Metadata.Constants.UseProductionByThirdParty2_5.Name, False,
		Metadata.Constants.UseDiscrepancyReportFollowingShipmentByTransfersToSubcontractor2_5.Name, False);
	
	SystemSettings.AddRowToConstantDependencyTable(Result,
		Metadata.Constants.UseProductionByThirdParty2_5.Name, False,
		Metadata.Constants.UseDiscrepancyReportFollowingReceiptFromSubcontractor2_5.Name, False);
	
	SystemSettings.AddRowToConstantDependencyTable(Result,
		Metadata.Constants.UseProductionByThirdParty2_5.Name, False,
		Metadata.Constants.UseSubcontractOrders2_5.Name, False);
	
	SystemSettings.AddRowToConstantDependencyTable(Result,
		Metadata.Constants.UseProductionByThirdParty2_5.Name, False,
		Metadata.Constants.UseTollingOrderStatuses2_5.Name, False);
	
	SystemSettings.AddRowToConstantDependencyTable(Result,
		Metadata.Constants.UseSubcontractOrders2_5.Name, False,
		Metadata.Constants.UseTollingOrderStatuses2_5.Name, False);
	
	SystemSettings.AddRowToConstantDependencyTable(Result,
		Metadata.Constants.UseTollingOrderStatuses2_5.Name, False,
		Metadata.Constants.DoNotCloseTollingOrdersWithoutCompletePayment2_5.Name, False);
	
	SystemSettings.AddRowToConstantDependencyTable(Result,
		Metadata.Constants.UseTollingOrderStatuses2_5.Name, False,
		Metadata.Constants.DoNotCloseTollingOrdersWithoutCompleteFulfillment2_5.Name, False);
	
	#EndRegion
	#Region AcceptanceForProcessing
	
	SystemSettings.AddRowToConstantDependencyTable(Result,
		Metadata.Constants.UseProduction.Name, False,
		Metadata.Constants.UseTollManufacturing2_5.Name, False);
	
	SystemSettings.AddRowToConstantDependencyTable(Result,
		Metadata.Constants.NewOnlineARAPAccounting.Name, False,
		Metadata.Constants.UseTollManufacturing2_5.Name, False);
	
	SystemSettings.AddRowToConstantDependencyTable(Result,
		Metadata.Constants.UseTollManufacturing2_5.Name, True,
		Metadata.Constants.UseCustomerContracts.Name, True);
	
	SystemSettings.AddRowToConstantDependencyTable(Result,
		Metadata.Constants.UseTollManufacturing2_5.Name, True,
		Metadata.Constants.UseBusinessUnits.Name, True);
		
	SystemSettings.AddRowToConstantDependencyTable(Result,
		Metadata.Constants.UseTollManufacturing2_5.Name, True,
		Metadata.Constants.UseMultipleKindsOfProducts.Name, True);
		
	SystemSettings.AddRowToConstantDependencyTable(Result,
		Metadata.Constants.UseTollManufacturing2_5.Name, True,
		Metadata.Constants.UseOrderSupplyWithAssignment.Name, True);
	
	SystemSettings.AddRowToConstantDependencyTable(Result,
		Metadata.Constants.UseTollManufacturing2_5.Name, True,
		Metadata.Constants.OptionOfMaterialAssignmentUponSubcontractingServicesDelivered.Name, Enums.AssignmentAtSubcontractingServicesDelivered.ContractWithMaterialProviderForProcessing);
		
	SystemSettings.AddRowToConstantDependencyTable(Result,
		Metadata.Constants.UseTollManufacturing2_5.Name, True,
		Metadata.Constants.OptionOfManufacturedProductAssignmentUponSubcontractingServicesDelivered.Name, Enums.AssignmentAtSubcontractingServicesDelivered.ContractWithMaterialProviderForProcessing);
		
	SystemSettings.AddRowToConstantDependencyTable(Result,
		Metadata.Constants.UseTollManufacturing2_5.Name, False,
		Metadata.Constants.UseCertificatesOfDiscrepanciesAfterShipmentForShipmentsOfGoodsToGiver2_5.Name, False);
		
	SystemSettings.AddRowToConstantDependencyTable(Result,
		Metadata.Constants.UseTollManufacturing2_5.Name, False,
		Metadata.Constants.UseCertificatesOfDiscrepanciesAfterAcceptanceForAcceptanceOfGiverSGoods2_5.Name, False);
		
	SystemSettings.AddRowToConstantDependencyTable(Result,
		Metadata.Constants.UseTollManufacturing2_5.Name, False,
		Metadata.Constants.UseMaterialProviderOrder2_5.Name, False);
		
	SystemSettings.AddRowToConstantDependencyTable(Result,
		Metadata.Constants.UseTollManufacturing2_5.Name, False,
		Metadata.Constants.UseStatusesOfMaterialProviderOrders2_5.Name, False);
		
	SystemSettings.AddRowToConstantDependencyTable(Result,
		Metadata.Constants.UseTollManufacturing2_5.Name, False,
		Metadata.Constants.OptionOfMaterialAssignmentUponSubcontractingServicesDelivered.Name, Enums.AssignmentAtSubcontractingServicesDelivered.ContractWithMaterialProviderForProcessing);
		
	SystemSettings.AddRowToConstantDependencyTable(Result,
		Metadata.Constants.UseTollManufacturing2_5.Name, False,
		Metadata.Constants.OptionOfManufacturedProductAssignmentUponSubcontractingServicesDelivered.Name, Enums.AssignmentAtSubcontractingServicesDelivered.ContractWithMaterialProviderForProcessing);
		
	SystemSettings.AddRowToConstantDependencyTable(Result,
		Metadata.Constants.UseMaterialProviderOrder2_5.Name, False,
		Metadata.Constants.UseReportToMaterialProviderBySeveralOrders2_5.Name, False);
	
	SystemSettings.AddRowToConstantDependencyTable(Result,
		Metadata.Constants.UseMaterialProviderOrder2_5.Name, False,
		Metadata.Constants.OptionOfMaterialAssignmentUponSubcontractingServicesDelivered.Name, Enums.AssignmentAtSubcontractingServicesDelivered.ContractWithMaterialProviderForProcessing);
		
	SystemSettings.AddRowToConstantDependencyTable(Result,
		Metadata.Constants.UseMaterialProviderOrder2_5.Name, False,
		Metadata.Constants.OptionOfManufacturedProductAssignmentUponSubcontractingServicesDelivered.Name, Enums.AssignmentAtSubcontractingServicesDelivered.ContractWithMaterialProviderForProcessing);
		
	SystemSettings.AddRowToConstantDependencyTable(Result,
		Metadata.Constants.UseMaterialProviderOrder2_5.Name, False,
		Metadata.Constants.UseStatusesOfMaterialProviderOrders2_5.Name, False);
		
	SystemSettings.AddRowToConstantDependencyTable(Result,
		Metadata.Constants.UseStatusesOfMaterialProviderOrders2_5.Name, False,
		Metadata.Constants.DoNotCloseMaterialProviderOrdersWithoutCompleteFulfillment2_5.Name, False);
		
	SystemSettings.AddRowToConstantDependencyTable(Result,
		Metadata.Constants.UseStatusesOfMaterialProviderOrders2_5.Name, False,
		Metadata.Constants.DoNotCloseMaterialProviderOrdersWithoutCompletePayment2_5.Name, False);
	
	SystemSettings.AddRowToConstantDependencyTable(Result,
		Metadata.Constants.OptionOfMaterialAssignmentUponSubcontractingServicesDelivered.Name, Enums.AssignmentAtSubcontractingServicesDelivered.MaterialProviderOrder,
		Metadata.Constants.OptionOfManufacturedProductAssignmentUponSubcontractingServicesDelivered.Name, Enums.AssignmentAtSubcontractingServicesDelivered.MaterialProviderOrder);
	
	#EndRegion
	#Region Production
	SystemSettings.AddRowToConstantDependencyTable(Result,
		Metadata.Constants.UseProduction.Name, True,
		Metadata.Constants.UseBusinessUnits.Name, True);
	SystemSettings.AddRowToConstantDependencyTable(Result,
		Metadata.Constants.UseProduction.Name, True,
		Metadata.Constants.UseMultipleKindsOfProducts.Name, True);
	SystemSettings.AddRowToConstantDependencyTable(Result,
		Metadata.Constants.UseProduction.Name, False,
		Metadata.Constants.AnalyticalAccountingByProductsGroups.Name, False);
	SystemSettings.AddRowToConstantDependencyTable(Result,
		Metadata.Constants.AnalyticalAccountingByProductsGroups.Name, True,
		Metadata.Constants.UseAnalyticalInventoryGroups.Name, True);
	SystemSettings.AddRowToConstantDependencyTable(Result,
		Metadata.Constants.UseProductionManagement2_2.Name, False,
		Metadata.Constants.UseStatusesOfInternalWorksAcceptance.Name, False);
	SystemSettings.AddRowToConstantDependencyTable(Result,
		Metadata.Constants.UseProduction.Name, False,
		Metadata.Constants.UseStatusesOfInternalWorksAcceptance.Name, False);
	SystemSettings.AddRowToConstantDependencyTable(Result,
		Metadata.Constants.UseProductionManagement2_2.Name, False,
		Metadata.Constants.UseStatusesOfProductsAndMaterialsMovements.Name, False);
	SystemSettings.AddRowToConstantDependencyTable(Result,
		Metadata.Constants.UseProduction.Name, False,
		Metadata.Constants.UseStatusesOfProductsAndMaterialsMovements.Name, False);
	SystemSettings.AddRowToConstantDependencyTable(Result,
		Metadata.Constants.UseProduction.Name, True,
		Metadata.Constants.ProductionManagementMethod.Name, Enums.ProductionManagementMethod.WithoutCalculationOfProductionSchedule);
	SystemSettings.AddRowToConstantDependencyTable(Result,
		Metadata.Constants.UseProduction.Name, False,
		Metadata.Constants.UseProductionPlanning.Name, False);
	SystemSettings.AddRowToConstantDependencyTable(Result,
		Metadata.Constants.UseProduction.Name, False,
		Metadata.Constants.UsePlanningIntervalHour.Name, False);
	SystemSettings.AddRowToConstantDependencyTable(Result,
		Metadata.Constants.UseProduction.Name, False,
		Metadata.Constants.DoNotCloseProductionOrdersWithoutFullProcessing.Name, False);
	SystemSettings.AddRowToConstantDependencyTable(Result,
		Metadata.Constants.UseProduction.Name, True,
		Metadata.Constants.UseOrderSupplyWithAssignment.Name, True);
	SystemSettings.AddRowToConstantDependencyTable(Result,
		Metadata.Constants.UseProduction.Name, True,
		Metadata.Constants.UseBillOfMaterialsParameterization.Name, True);
	SystemSettings.AddRowToConstantDependencyTable(Result,
		Metadata.Constants.UseProduction.Name, False,
		Metadata.Constants.UseBillOfMaterialsParameterization.Name, False);
	SystemSettings.AddRowToConstantDependencyTable(Result,
		Metadata.Constants.UseProduction.Name, False,
		Metadata.Constants.UseAlternativeMaterials.Name, False);
	SystemSettings.AddRowToConstantDependencyTable(Result,
		Metadata.Constants.UseProductionManagement2_2.Name, False,
		Metadata.Constants.UseKindsOfSpecificTechnologicalOperations.Name, False);
	SystemSettings.AddRowToConstantDependencyTable(Result,
		Metadata.Constants.UseAdditionalAttributesAndInfo.Name, False,
		Metadata.Constants.UseKindsOfSpecificTechnologicalOperations.Name, False);
	SystemSettings.AddRowToConstantDependencyTable(Result,
		Metadata.Constants.UseProductionManagement2_2.Name, False,
		Metadata.Constants.ControlOperationCompletionWhenClosingProductionStages.Name, False);
	
	SystemSettings.AddRowToConstantDependencyTable(Result,
		Metadata.Constants.UseProductionManagement2_2.Name, False,
		Metadata.Constants.UseInternalSubcontracting.Name, False);
		
	SystemSettings.AddRowToConstantDependencyTable(Result,
		Metadata.Constants.UseAlternativeMaterials.Name, False,
		Metadata.Constants.UseApprovalOfEngineeringChangeOrders.Name, False);
	
	SystemSettings.AddRowToConstantDependencyTable(Result,
		Metadata.Constants.DynamicStructureOfProductionOrders.Name, False,
		Metadata.Constants.UseManufacturingExecutionSystem.Name, False);
	#EndRegion
	
	#Region NonCurrentAssets
		
	SystemSettings.AddRowToConstantDependencyTable(Result,
		Metadata.Constants.UseNonCurrentAssets2_4.Name, False,
		Metadata.Constants.LocalFAAccounting.Name, False);
		
	SystemSettings.AddRowToConstantDependencyTable(Result,
		Metadata.Constants.UseNonCurrentAssets2_4.Name, True,
		Metadata.Constants.UseBusinessUnits.Name, True);
	
	#EndRegion
	
	#Region RM
	SystemSettings.AddRowToConstantDependencyTable(Result,
		Metadata.Constants.UseRMManagement.Name, False,
		Metadata.Constants.UseSubAssets.Name, False);
	#EndRegion

	#Region Budgeting
	SystemSettings.AddRowToConstantDependencyTable(Result, 
		Metadata.Constants.UseBudgeting.Name, False, 
		Metadata.Constants.UpdateStoredActualBudgetingDataWhenPostingDocuments.Name, False);
	
	SystemSettings.AddRowToConstantDependencyTable(Result, 
		Metadata.Constants.UseBudgeting.Name, False, 
		Metadata.Constants.UpdateStoredActualBudgetingDataWhenGeneratingReports.Name, False);
	
	SystemSettings.AddRowToConstantDependencyTable(Result, 
		Metadata.Constants.UseBudgeting.Name, False, 
		Metadata.Constants.SettingUpRulesForObtainingFactsFromCorrespondingRegisters.Name, False);
	
	// Control of limits based on budgeting data
	SystemSettings.AddRowToConstantDependencyTable(Result, 
		Metadata.Constants.UseBudgeting.Name, False, 
		Metadata.Constants.UseBudgetingCashFlowLimits.Name, False);
	
	SystemSettings.AddRowToConstantDependencyTable(Result, 
		Metadata.Constants.UseBudgeting.Name, False, 
		Metadata.Constants.UseIEBLimitsOnPurchases.Name, False);
	
	SystemSettings.AddRowToConstantDependencyTable(Result, 
		Metadata.Constants.UseBudgeting.Name, False, 
		Metadata.Constants.UseIEBLimitsOnConsumption.Name, False);
	
	SystemSettings.AddRowToConstantDependencyTable(Result,
		Metadata.Constants.UseBudgetingCashFlowLimits.Name, True,
		Metadata.Constants.UseCashFlowLimits.Name, False);
	
	SystemSettings.AddRowToConstantDependencyTable(Result,
		Metadata.Constants.UseBudgetingCashFlowLimits.Name, True,
		Metadata.Constants.UseCashFlowLimitsByCompanies.Name, False);
		
	SystemSettings.AddRowToConstantDependencyTable(Result,
		Metadata.Constants.UseBudgetingCashFlowLimits.Name, True,
		Metadata.Constants.UseCashFlowLimitsByBusinessUnit.Name, False);

	SystemSettings.AddRowToConstantDependencyTable(Result,
		Metadata.Constants.UseBudgetingCashFlowLimits.Name, True,
		Metadata.Constants.ControlExcessOfCashFlowLimits.Name, False);

	SystemSettings.AddRowToConstantDependencyTable(Result,
		Metadata.Constants.UseBudgetingCashFlowLimits.Name, False,
		Metadata.Constants.ControllingLimitsBasedOnBudgetingData2_4.Name, False);
	SystemSettings.AddRowToConstantDependencyTable(Result, 
		Metadata.Constants.UseBudgeting.Name, False, 
		Metadata.Constants.UseBudgetProcess.Name, False);
	
	SystemSettings.AddRowToConstantDependencyTable(Result, 
		Metadata.Constants.UseBudgetProcess.Name, False, 
		Metadata.Constants.UseNotificationsForBudgetingTasks.Name, False);
	#EndRegion
	#Region InternationalAccounting
	SystemSettings.AddRowToConstantDependencyTable(Result, 
		Metadata.Constants.UseFinancialAccounting.Name, True,
		Metadata.Constants.FinancialAccountingEntriesBasedOnOperationalAccountingData.Name, True);
	SystemSettings.AddRowToConstantDependencyTable(Result, 
		Metadata.Constants.UseFinancialAccounting.Name, True,
		Metadata.Constants.UseAccountingOfOtherIncomeExpenses.Name, True);
	SystemSettings.AddRowToConstantDependencyTable(Result, 
		Metadata.Constants.UseFinancialAccounting.Name, True,
		Metadata.Constants.UseFinancialAccountingGroups.Name, True);
	SystemSettings.AddRowToConstantDependencyTable(Result, 
		Metadata.Constants.UseFinancialAccounting.Name, False,
		Metadata.Constants.FinancialAccountingEntriesBasedOnOperationalAccountingData.Name, False);
	
	SystemSettings.AddRowToConstantDependencyTable(Result, 
		Metadata.Constants.FinancialAccountingEntriesBasedOnOperationalAccountingData.Name, True,
		Metadata.Constants.SettingOfPostingByAccountingObjects.Name, True);
	SystemSettings.AddRowToConstantDependencyTable(Result, 
		Metadata.Constants.FinancialAccountingEntriesBasedOnOperationalAccountingData.Name, True,
		Metadata.Constants.ConfigurePostingsForBusinessTransactions.Name, False);
		
	SystemSettings.AddRowToConstantDependencyTable(Result, 
		Metadata.Constants.FinancialAccountingEntriesBasedOnOperationalAccountingData.Name, False,
		Metadata.Constants.SettingOfPostingByAccountingObjects.Name, False);
	SystemSettings.AddRowToConstantDependencyTable(Result, 
		Metadata.Constants.FinancialAccountingEntriesBasedOnOperationalAccountingData.Name, False,
		Metadata.Constants.ConfigurePostingsForBusinessTransactions.Name, False);

	SystemSettings.AddRowToConstantDependencyTable(Result,
		Metadata.Constants.UseFinancialDocumentVerification.Name, False,
		Metadata.Constants.ReflectOnlyVerifiedDocumentsInInternationalAccounting.Name, False);
	SystemSettings.AddRowToConstantDependencyTable(Result, 
		Metadata.Constants.UseVATAccounting.Name, False, 
		Metadata.Constants.UseVATReverseCharge.Name, False);
	#EndRegion
	#Region VATAccountingImportExport
	
	SystemSettings.AddRowToConstantDependencyTable(Result, 
		Metadata.Constants.UseVATAccounting.Name, False, 
		Metadata.Constants.UseSalesForExport.Name, False);
	
	SystemSettings.AddRowToConstantDependencyTable(Result,
		Metadata.Constants.UseImports.Name, True,
		Metadata.Constants.ControlCompanyStockBalanceForRegistrationByReceipts.Name, True And Not BaseVersion);
		
	SystemSettings.AddRowToConstantDependencyTable(Result,
		Metadata.Constants.UseImportOfGoodsFromCustomsUnion.Name, True,
		Metadata.Constants.ControlCompanyStockBalanceForRegistrationByReceipts.Name, True);
	
	SystemSettings.AddRowToConstantDependencyTable(Result,
		Metadata.Constants.ControlCompanyStockBalanceForRegistrationByReceipts.Name, False,
		Metadata.Constants.UseImportOfGoodsFromCustomsUnion.Name, False);
	#EndRegion
	
	#Region UserNotificationsOfEvents
	SystemSettings.AddRowToConstantDependencyTable(Result,
		Metadata.Constants.UseUserNotificationsOfSystemEvents.Name, False,
		Metadata.Constants.UseUserNotificationsViaTelegram.Name, False);
		
	SystemSettings.AddRowToConstantDependencyTable(Result,
		Metadata.Constants.UseUserNotificationsOfSystemEvents.Name, False,
		Metadata.Constants.UseUserNotificationsByEmail.Name, False);
	#EndRegion
	
	#Region Inverted_constants
	// Invertible constants (having a "double" with the opposite value)
	SystemSettings.AddStringOfInvertibleConstants(Result, Metadata.Constants.UseBusinessRegions.Name);
	SystemSettings.AddStringOfInvertibleConstants(Result, Metadata.Constants.UseMultipleCurrencies.Name);
	SystemSettings.AddStringOfInvertibleConstants(Result, Metadata.Constants.UseMultipleCompanies.Name);
	SystemSettings.AddStringOfInvertibleConstants(Result, Metadata.Constants.UseSeveralWarehouses.Name);
	SystemSettings.AddStringOfInvertibleConstants(Result, Metadata.Constants.UsePartnersAndCounterparties.Name, Metadata.Constants.UsePartnersAsCounterparties.Name);
	SystemSettings.AddStringOfInvertibleConstants(Result, Metadata.Constants.UsePaymentRequests.Name);
	SystemSettings.AddStringOfInvertibleConstants(Result, Metadata.Constants.UsePriceGroups.Name);
	SystemSettings.AddStringOfInvertibleConstants(Result, Metadata.Constants.SelectAnOptionOfDiscountDisplayWhilePrintingSalesDocuments.Name);
	SystemSettings.AddStringOfInvertibleConstants(Result, Metadata.Constants.GenerateFinancialResult.Name);
	SystemSettings.AddStringOfInvertibleConstants(Result, Metadata.Constants.UseAdvancedDemandFulfillment.Name);
	SystemSettings.AddStringOfInvertibleConstants(Result, Metadata.Constants.UseCashPaymentJournal.Name);
	SystemSettings.AddStringOfInvertibleConstants(Result, Metadata.Constants.UsePriceManagementSystem25.Name, Metadata.Constants.UsePriceManagementSystem20.Name);
	SystemSettings.AddStringOfInvertibleConstants(Result, Metadata.Constants.UsePriceManagementSystem20.Name, Metadata.Constants.UsePriceManagementSystem25.Name);
	#EndRegion
	
	#Region Controlled_b__
	// Constants controlled in the Basic version
	ConstantValues = SystemSettingsCached.ValuesOfConstantsControlledInBaseVersion();
	For Each ConstantValue In ConstantValues Do
		
		If ConstantValue.Key = "BaseVersion" Then
			Continue;
		EndIf;
		
		NewRow = Result.Add();
		NewRow.NameOfParentConstant 	  = "BaseVersion";
		NewRow.ValueOfParentConstant = True;
		NewRow.NameOfSubordinateConstant 	  = ConstantValue.Key;
		NewRow.ValueOfSubordinateConstant  = ConstantValue.Value;
	
	EndDo;
	#EndRegion

	#Region Controlled_b_NOT_B
	// Constants controlled in a NON-Basic version
	ConstantValues = SystemSettingsCached.ValuesOfConstantsControlledInNonBaseVersion();
	For Each ConstantValue In ConstantValues Do
		
		If ConstantValue.Key = "BaseVersion" Then
			Continue;
		EndIf;
		
		NewRow = Result.Add();
		NewRow.NameOfParentConstant 	  = "BaseVersion";
		NewRow.ValueOfParentConstant = False;
		NewRow.NameOfSubordinateConstant 	  = ConstantValue.Key;
		NewRow.ValueOfSubordinateConstant  = ConstantValue.Value;
	
	EndDo;
	#EndRegion	

	SystemSettingsLocalization.SupplementTableOfDependenceOfConstants(Result);
	
	Return Result;
	
EndFunction

#EndRegion

#Region GlobalSearch

// Valid parameters for warehouses.
// 
// Returns:
//  See Catalogs.Warehouses.CurrentAccountingParameters
Function ValidParametersForWarehouses() Export
	
	Return Catalogs.Warehouses.CurrentAccountingParameters(Undefined);
	
EndFunction

// Describes the existing parameters of the warehouse by the deadline.
// 
// Returns:
//  See Catalogs.Warehouses.DescriptionOfActiveParameters
Function DescriptionOfDefaultWarehouseParameters() Export
	
	Result = "";
	
	If AccessRight("View", Metadata.Catalogs.Warehouses) Then
		DefaultValues = Catalogs.Warehouses.DefaultValues();
		Result = Catalogs.Warehouses.DescriptionOfActiveParameters(Undefined, , DefaultValues);
	EndIf;
	
	Return Result
	
EndFunction

// Valid parameters by division.
// 
// Returns:
//  See Catalogs.BusinessStructure.CurrentAccountingParameters
Function ValidParametersByDivision() Export
	
	Return Catalogs.BusinessStructure.CurrentAccountingParameters(Undefined);
	
EndFunction

// Describes the existing parameters of the time division.
// 
// Returns:
//  See Catalogs.BusinessStructure.DescriptionOfActiveParameters
Function DescriptionOfDefaultDivisionParameters() Export
	
	Result = "";
	
	If GetFunctionalOption("UseBusinessUnits")
		And AccessRight("View", Metadata.Catalogs.BusinessStructure) Then
		
		DefaultValues = Catalogs.BusinessStructure.DefaultValues();
		Result = Catalogs.BusinessStructure.DescriptionOfActiveParameters(Undefined, , DefaultValues);
		
	EndIf;
	
	Return Result
	
EndFunction

#EndRegion

#EndRegion