
////////////////////////////////////////////////////////////////////////////////
// The CODE OF PROCEDURES AND FUNCTIONS of the data-change module is defined
// to support the library approach of development.
//
////////////////////////////////////////////////////////////////////////////////
//

#Region Public

// See PeriodClosingDatesOverridable.InterfaceSetup
Procedure InterfaceSetup(Val InterfaceSettings5) Export
	
	InterfaceSettings5.UseExternalUsers = True;
	
EndProcedure

// See PeriodClosingDatesOverridable.FillDataSourcesForPeriodClosingCheck
Procedure FillDataSourcesForPeriodClosingCheck(Val DataSources) Export
	RMManagement.FillDataSourcesForPeriodClosingCheck(DataSources);
	NonCurrentAssets.FillDataSourcesForPeriodClosingCheck(DataSources);
	InventoryInOperationServer.FillDataSourcesForPeriodClosingCheck(DataSources);
	
	// Data(Table, Data fields, Section, Object fields)

	PeriodClosingDates.AddRow(DataSources,
										Metadata.Documents.AccrueAndDeductionOfBonusPoints.FullName(),
										"Date");

#Region ExpenseReports
	PeriodClosingDates.AddRow(DataSources,
										Metadata.Documents.ExpenseReport.FullName(),
										"Date",
										"ExpenseReports",
										"Organization");
#EndRegion

#Region Bank
	PeriodClosingDates.AddRow(DataSources,
										Metadata.Documents.BankReportOnAcquiringTransactions.FullName(),
										"Date",
										"Bank",
										"AcquiringContract.BankAccount");
	PeriodClosingDates.AddRow(DataSources,
										Metadata.Documents.BankAccountReceiptNote.FullName(),
										"BankPostingDate",
										"Bank",
										"BankAccount");
	PeriodClosingDates.AddRow(DataSources,
										Metadata.Documents.BankAccountIssue.FullName(),
										"BankPostingDate",
										"Bank",
										"BankAccount");
#EndRegion
#Region Budgeting
	PeriodClosingDates.AddRow(DataSources,
										Metadata.Documents.SalesPlanByCategories.FullName(),
										"BeginOfPeriod",
										"Budgeting",
										"BudgetingScenario");
	PeriodClosingDates.AddRow(DataSources,
										Metadata.Documents.PlanOfGoodsStock.FullName(),
										"BeginOfPeriod",
										"Budgeting",
										"BudgetingScenario");
	PeriodClosingDates.AddRow(DataSources,
										Metadata.Documents.PurchasePlan.FullName(),
										"BeginOfPeriod",
										"Budgeting",
										"BudgetingScenario");
	PeriodClosingDates.AddRow(DataSources,
										Metadata.Documents.SalesPlan.FullName(),
										"BeginOfPeriod",
										"Budgeting",
										"BudgetingScenario");
	PeriodClosingDates.AddRow(DataSources,
										Metadata.Documents.AssemblyDisassemblyPlan.FullName(),
										"BeginOfPeriod",
										"Budgeting",
										"BudgetingScenario");
	PeriodClosingDates.AddRow(DataSources,
										Metadata.Documents.InventoryConsumptionPlan.FullName(),
										"BeginOfPeriod",
										"Budgeting",
										"BudgetingScenario");
	PeriodClosingDates.AddRow(DataSources,
										Metadata.Documents.ProductionPlan.FullName(),
										"BeginOfPeriod",
										"Budgeting",
										"BudgetingScenario");
	PeriodClosingDates.AddRow(DataSources,
										Metadata.Documents.BudgetEntryForm.FullName(),
										"BeginOfPeriod",
										"Budgeting",
										"Scenario");
	PeriodClosingDates.AddRow(DataSources,
										Metadata.Documents.SetValuesForNonFinancialItems.FullName(),
										"BeginOfPeriod",
										"Budgeting",
										"Scenario");
	PeriodClosingDates.AddRow(DataSources,
										Metadata.Documents.SettingOfEstimatesOpeningBalance.FullName(),
										"DateOfRemainingGoods",
										"Budgeting",
										"Scenario");
	PeriodClosingDates.AddRow(DataSources,
										Metadata.Documents.RegistrarOfBudgetTurnover.FullName(),
										"PlanningPeriod",
										"Budgeting",
										"Scenario");
#EndRegion
#Region OBEntry
	PeriodClosingDates.AddRow(DataSources,
										Metadata.Documents.OBEntry.FullName(),
										"Date",
										"OBEntry",
										"Organization");
	PeriodClosingDates.AddRow(DataSources,
										Metadata.Documents.OBEntryARAP.FullName(),
										"Date",
										"OBEntry",
										"Organization");
	PeriodClosingDates.AddRow(DataSources,
										Metadata.Documents.OBEntryCash.FullName(),
										"Date",
										"OBEntry",
										"Organization");
	PeriodClosingDates.AddRow(DataSources,
										Metadata.Documents.OBEntrySalesForPastPeriods.FullName(),
										"Date",
										"OBEntry",
										"Organization");
	PeriodClosingDates.AddRow(DataSources,
										Metadata.Documents.OBEntryFinancialInstruments.FullName(),
										"Date",
										"OBEntry",
										"Organization");
	PeriodClosingDates.AddRow(DataSources,
										Metadata.Documents.OBEntryOtherExpenses.FullName(),
										"Date",
										"OBEntry",
										"Organization");
	PeriodClosingDates.AddRow(DataSources,
										Metadata.Documents.OBEntryOtherAssetsAndLiabilities.FullName(),
										"Date",
										"OBEntry",
										"Organization");
	PeriodClosingDates.AddRow(DataSources,
										Metadata.Documents.OBEntryAcquiringContractARAP.FullName(),
										"Date",
										"OBEntry",
										"Organization");
	PeriodClosingDates.AddRow(DataSources,
										Metadata.Documents.OBEntryARAPAdvanceHolders.FullName(),
										"Date",
										"OBEntry",
										"Organization");
	PeriodClosingDates.AddRow(DataSources,
										Metadata.Documents.OBEntryGoods.FullName(),
										"Date",
										"OBEntry",
										"Organization");
	PeriodClosingDates.AddRow(DataSources,
										Metadata.Documents.SourceDocument.FullName(),
										"Date",
										"OBEntry",
										"Organization");
	PeriodClosingDates.AddRow(DataSources,
										Metadata.Documents.WIPOpeningBalancesByProductionLots.FullName(),
										"Date",
										"OBEntry",
										"Organization");
	PeriodClosingDates.AddRow(DataSources,
										Metadata.Documents.InitialWIPBalancesByBusinessUnits.FullName(),
										"Date",
										"OBEntry",
										"Organization");
#EndRegion

#Region InternalInventoryTransfers
	PeriodClosingDates.AddRow(DataSources,
										Metadata.Documents.DiscrepancyReportFollowingTransfer.FullName(),
										"Date",
										"InternalInventoryTransfers",
										"Organization");
	PeriodClosingDates.AddRow(DataSources,
										Metadata.Documents.MovementOfProductsAndMaterials.FullName(),
										"Date",
										"InternalInventoryTransfers",
										"Organization");
	PeriodClosingDates.AddRow(DataSources,
										Metadata.Documents.InventoryAssignmentAdjustment.FullName(),
										"Date",
										"InternalInventoryTransfers",
										"Organization");

	PeriodClosingDates.AddRow(DataSources,
										Metadata.Documents.AssemblyFromComponents.FullName(),
										"Date",
										"InternalInventoryTransfers",
										"Organization");
	PeriodClosingDates.AddRow(DataSources,
										Metadata.Documents.InventoryConsumption.FullName(),
										"Date",
										"InternalInventoryTransfers",
										"Organization");
	PeriodClosingDates.AddRow(DataSources,
										Metadata.Documents.InventorySurplusRecognition.FullName(),
										"Date",
										"InternalInventoryTransfers",
										"Organization");
	PeriodClosingDates.AddRow(DataSources,
										Metadata.Documents.InventoryTransfer.FullName(),
										"Date",
										"InternalInventoryTransfers",
										"Organization");
	PeriodClosingDates.AddRow(DataSources,
										Metadata.Documents.GoodsMisgrading.FullName(),
										"Date",
										"InternalInventoryTransfers",
										"Organization");
	PeriodClosingDates.AddRow(DataSources,
										Metadata.Documents.GoodsDamage.FullName(),
										"Date",
										"InternalInventoryTransfers",
										"Organization");
	PeriodClosingDates.AddRow(DataSources,
										Metadata.Documents.OtherGoodsRecordingAsReceived.FullName(),
										"Date",
										"InternalInventoryTransfers",
										"Organization");
	PeriodClosingDates.AddRow(DataSources,
										Metadata.Documents.WriteOffOfGoodsShortages.FullName(),
										"Date",
										"InternalInventoryTransfers",
										"Organization");
#EndRegion

#Region Purchases
	PeriodClosingDates.AddRow(DataSources,
										Metadata.Documents.DiscrepancyReportFollowingReceipt.FullName(),
										"Date",
										"Purchases",
										"Organization");
	PeriodClosingDates.AddRow(DataSources,
										Metadata.Documents.ReturnOfGoodsToVendor.FullName(),
										"Date",
										"Purchases",
										"Organization");
	PeriodClosingDates.AddRow(DataSources,
										Metadata.Documents.RedemptionOfReturnablePackagingFromVendor.FullName(),
										"Date",
										"Purchases",
										"Organization");
	PeriodClosingDates.AddRow(DataSources,
										Metadata.Documents.PurchaseAdjustment.FullName(),
										"Date",
										"Purchases",
										"Organization");
	PeriodClosingDates.AddRow(DataSources,
										Metadata.Documents.ConsignmentReportToVendor.FullName(),
										"Date",
										"Purchases",
										"Organization");
	PeriodClosingDates.AddRow(DataSources,
										Metadata.Documents.PurchaseInvoiceConsignmentStockLost.FullName(),
										"Date",
										"Purchases",
										"Organization");
	PeriodClosingDates.AddRow(DataSources,
										Metadata.Documents.VendorInvoice.FullName(),
										"Date",
										"Purchases",
										"Organization");
	PeriodClosingDates.AddRow(DataSources,
										Metadata.Documents.VendorInvoiceServicesAndAssets.FullName(),
										"Date",
										"Purchases",
										"Organization");
	PeriodClosingDates.AddRow(DataSources,
										Metadata.Documents.ReceiptOfGoodsToWarehouse.FullName(),
										"Date",
										"Purchases",
										"Organization");
	PeriodClosingDates.AddRow(DataSources,
										Metadata.Documents.ReceiptOfServicesToBusinessUnit.FullName(),
										"Date",
										"Purchases",
										"Organization");
	PeriodClosingDates.AddRow(DataSources,
										Metadata.Documents.ReceivingLeaseServices.FullName(),
										"Date",
										"Purchases",
										"Organization");
	PeriodClosingDates.AddRow(DataSources,
 										Metadata.Documents.CalculationOfInventoryImpairmentProvision.FullName(),
										"Date",
 										"RoutineOperations",
 										"Organization");
	PeriodClosingDates.AddRow(DataSources,
										Metadata.Documents.CCDImport.FullName(),
										"Date",
										"Purchases",
										"Organization");
	PeriodClosingDates.AddRow(DataSources,
										Metadata.Documents.RedemptionOfGoodsFromStorage.FullName(),
										"Date",
										"Purchases",
										"Organization");
	PeriodClosingDates.AddRow(DataSources,
										Metadata.Documents.GoodsShipmentFromStorage.FullName(),
										"Date",
										"Purchases",
										"Organization");
	PeriodClosingDates.AddRow(DataSources,
										Metadata.Documents.GoodsReceiptForStorage.FullName(),
										"Date",
										"Purchases",
										"Organization");
	PeriodClosingDates.AddRow(DataSources,
										Metadata.Documents.ReceiptOfGoodsToWarehouse.FullName(),
										"Date",
										"Purchases",
										"Organization");
	PeriodClosingDates.AddRow(DataSources,
										Metadata.Documents.ReportOnVMIAdjustment.FullName(),
										"Date",
										"Purchases",
										"Organization");
	
	PeriodClosingDates.AddRow(DataSources,
										Metadata.Documents.SubcontractorReport2_5.FullName(),
										"Date",
										"Purchases",
										"Organization");
	PeriodClosingDates.AddRow(DataSources,
										Metadata.Documents.WriteOffDiscrepanciesBetweenReceiptAndPurchase.FullName(),
										"Date",
										"Purchases",
										"Organization");
#EndRegion

#Region CashAccount
	PeriodClosingDates.AddRow(DataSources,
										Metadata.Documents.PaymentCardTransaction.FullName(),
										"Date",
										"CashAccount",
										"Organization");
	PeriodClosingDates.AddRow(DataSources,
										Metadata.Documents.CashAccountReceiptNote.FullName(),
										"Date",
										"CashAccount",
										"CashAccount");
	PeriodClosingDates.AddRow(DataSources,
										Metadata.Documents.CashVoucher.FullName(),
										"Date",
										"CashAccount",
										"CashAccount");
	PeriodClosingDates.AddRow(DataSources,
										Metadata.Documents.PhysicalCountOfCashAccounts.FullName(),
										"Date",
										"CashAccount",
										"Organization");
	PeriodClosingDates.AddRow(DataSources,
										Metadata.Documents.CashDepositWithdrawalDiscrepancies.FullName(),
										"Date",
										"CashAccount",
										"Organization");
#EndRegion
#Region FinancialAccounting
	FinancialAccountingOfGeneralPurpose.FillDataSourcesForPeriodClosingCheck(DataSources);
#EndRegion
#Region Planning
	PeriodClosingDates.AddRow(DataSources,
										Metadata.Documents.SalesPlanByCategories.FullName(),
										"BeginOfPeriod",
										"Planning",
										"Scenario");
	PeriodClosingDates.AddRow(DataSources,
										Metadata.Documents.SalesPlansAllocationBaseByCategories.FullName(),
										"ValidityStartDate",
										"Planning",
										"");
	PeriodClosingDates.AddRow(DataSources,
										Metadata.Documents.PlanOfGoodsStock.FullName(),
										"BeginOfPeriod",
										"Planning",
										"Scenario");
	PeriodClosingDates.AddRow(DataSources,
										Metadata.Documents.PurchasePlan.FullName(),
										"BeginOfPeriod",
										"Planning",
										"Scenario");
	PeriodClosingDates.AddRow(DataSources,
										Metadata.Documents.SalesPlan.FullName(),
										"BeginOfPeriod",
										"Planning",
										"Scenario");
	PeriodClosingDates.AddRow(DataSources,
										Metadata.Documents.AssemblyDisassemblyPlan.FullName(),
										"BeginOfPeriod",
										"Planning",
										"Scenario");
	PeriodClosingDates.AddRow(DataSources,
										Metadata.Documents.AdjustmentOfPlannedDemand.FullName(),
										"Period",
										"Planning",
										"Scenario");
	PeriodClosingDates.AddRow(DataSources,
										Metadata.Documents.InventoryConsumptionPlan.FullName(),
										"BeginOfPeriod",
										"Planning",
										"Scenario");
	PeriodClosingDates.AddRow(DataSources,
										Metadata.Documents.ProductionPlan.FullName(),
										"BeginOfPeriod",
										"Planning",
										"Scenario");
#EndRegion

#Region Sales
	PeriodClosingDates.AddRow(DataSources,
										Metadata.Documents.CustomerInvoiceServices.FullName(),
										"Date",
										"Sales",
										"Organization");
	PeriodClosingDates.AddRow(DataSources,
										Metadata.Documents.DiscrepancyReportFollowingShipment.FullName(),
										"Date",
										"Sales",
										"Organization");
	PeriodClosingDates.AddRow(DataSources,
										Metadata.Documents.ReturnOfGoodsFromCustomer.FullName(),
										"Date",
										"Sales",
										"Organization");
	PeriodClosingDates.AddRow(DataSources,
										Metadata.Documents.SaleAdjustment.FullName(),
										"Date",
										"Sales",
										"Organization");
	PeriodClosingDates.AddRow(DataSources,
										Metadata.Documents.ConsignmentReportFromCustomer.FullName(),
										"Date",
										"Sales",
										"Organization");
	PeriodClosingDates.AddRow(DataSources,
										Metadata.Documents.WriteOffReportFromCommissionAgent.FullName(),
										"Date",
										"Sales",
										"Organization");
	PeriodClosingDates.AddRow(DataSources,
										Metadata.Documents.GoodsShipmentToCustomer.FullName(),
										"Date",
										"Sales",
										"Organization");
	PeriodClosingDates.AddRow(DataSources,
										Metadata.Documents.CustomerInvoice.FullName(),
										"Date",
										"Sales",
										"Organization");
	PeriodClosingDates.AddRow(DataSources,
										Metadata.Documents.CustomerInvoiceServicesAndAssets.FullName(),
										"Date",
										"Sales",
										"Organization");
	PeriodClosingDates.AddRow(DataSources,
										Metadata.Documents.ReturnablePackagingRedemptionByCustomer.FullName(),
										"Date",
										"Sales",
										"Organization");
	PeriodClosingDates.AddRow(DataSources,
										Metadata.Documents.RedemptionOfGoodsByCustodian.FullName(),
										"Date",
										"Sales",
										"Organization");
	PeriodClosingDates.AddRow(DataSources,
										Metadata.Documents.TransferOfGoodsToBailee.FullName(),
										"Date",
										"Sales",
										"Organization");
	PeriodClosingDates.AddRow(DataSources,
										Metadata.Documents.ReceiptOfGoodsFromCustodian.FullName(),
										"Date",
										"Sales",
										"Organization");
	PeriodClosingDates.AddRow(DataSources,
										Metadata.Documents.GoodsReceiptFromCustomer.FullName(),
										"Date",
										"Sales",
										"Organization");
	PeriodClosingDates.AddRow(DataSources,
										Metadata.Documents.WriteOffOfShippedGoods.FullName(),
										"Date",
										"Sales",
										"Organization");
	
	PeriodClosingDates.AddRow(DataSources,
										Metadata.Documents.MisgradingOfGoodsAtCustodian.FullName(),
										"Date",
										"Sales",
										"Organization");
	
	PeriodClosingDates.AddRow(DataSources,
										Metadata.Documents.DamageAtCustodian.FullName(),
										"Date",
										"Sales",
										"Organization");
	PeriodClosingDates.AddRow(DataSources,
										Metadata.Documents.RecognitionOfStockSurplusShippedToCustomer.FullName(),
										"Date",
										"Sales",
										"Organization");
	PeriodClosingDates.AddRow(DataSources,
										Metadata.Documents.ReportToMaterialProvider2_5.FullName(),
										"Date",
										"Sales",
										"Organization");
	PeriodClosingDates.AddRow(DataSources,
										Metadata.Documents.PurchasingReportToConsignorPrincipal.FullName(),
										"Date",
										"Sales",
										"Organization");
										
	PeriodClosingDates.AddRow(DataSources,
										Metadata.Documents.PriceSetup.FullName(),
										"Date",
										"Sales");
#EndRegion

#Region IntercompanySales
	PeriodClosingDates.AddRow(DataSources,
										Metadata.Documents.IntercompanyGoodsReturn.FullName(),
										"Date",
										"IntercompanySales",
										"Organization");
	PeriodClosingDates.AddRow(DataSources,
										Metadata.Documents.IntercompanyGoodsReturn.FullName(),
										"Date",
										"IntercompanySales",
										"CompanyRecipient");
	PeriodClosingDates.AddRow(DataSources,
										Metadata.Documents.CustomerInvoiceIntercompany.FullName(),
										"Date",
										"IntercompanySales",
										"Organization");
	PeriodClosingDates.AddRow(DataSources,
										Metadata.Documents.CustomerInvoiceIntercompany.FullName(),
										"Date",
										"IntercompanySales",
										"CompanyRecipient");
	PeriodClosingDates.AddRow(DataSources,
										Metadata.Documents.CommissionReportIntercompany.FullName(),
										"Date",
										"IntercompanySales",
										"Organization");
	PeriodClosingDates.AddRow(DataSources,
										Metadata.Documents.CommissionReportIntercompany.FullName(),
										"Date",
										"IntercompanySales",
										"Consignee");
	PeriodClosingDates.AddRow(DataSources,
										Metadata.Documents.CommissionWriteOffReportIntercompany.FullName(),
										"Date",
										"IntercompanySales",
										"Organization");
	PeriodClosingDates.AddRow(DataSources,
										Metadata.Documents.CommissionWriteOffReportIntercompany.FullName(),
										"Date",
										"IntercompanySales",
										"Consignee");
	PeriodClosingDates.AddRow(DataSources,
										Metadata.Documents.ConsumptionReportSubcontractingServicesDeliveredIntercompany.FullName(),
										"Date",
										"IntercompanySales",
										"Organization");
	PeriodClosingDates.AddRow(DataSources,
										Metadata.Documents.ConsumptionReportSubcontractingServicesDeliveredIntercompany.FullName(),
										"Date",
										"IntercompanySales",
										"MaterialProvider");
#EndRegion

#Region Production
	
	PeriodClosingDates.AddRow(DataSources,
										Metadata.Documents.WorkOutput.FullName(),
										"Date",
										"Production",
										"Organization");
	PeriodClosingDates.AddRow(DataSources,
										Metadata.Documents.InternalAcceptanceCertificate.FullName(),
										"Date",
										"Production",
										"Organization");
	PeriodClosingDates.AddRow(DataSources,
										Metadata.Documents.BackflushProduction.FullName(),
										"Date",
										"Production",
										"Organization");
	PeriodClosingDates.AddRow(DataSources,
										Metadata.Documents.RecyclableWasteAllocation.FullName(),
										"Date",
										"Production",
										"Organization");
	PeriodClosingDates.AddRow(DataSources,
										Metadata.Documents.ProductionOperation2_2.FullName(),
										"ExecutionEnd",
										"Production",
										"Stage.Organization");
	PeriodClosingDates.AddRow(DataSources,
										Metadata.Documents.ShiftTask.FullName(),
										"Date",
										"Production",
										"");
	PeriodClosingDates.AddRow(DataSources,
										Metadata.Documents.StandardCosting2_2.FullName(),
										"Date",
										"Production",
										"Organization");
	PeriodClosingDates.AddRow(DataSources,
										Metadata.Documents.ProductionCostAllocation.FullName(),
										"Date",
										"Production",
										"Organization");
#EndRegion

#Region RoutineOperations
	PeriodClosingDates.AddRow(DataSources,
										Metadata.Documents.DepositsWithdrawalsByLineOfBusiness.FullName(),
										"Date",
										"RoutineOperations",
										"Organization");
	PeriodClosingDates.AddRow(DataSources,
										Metadata.Documents.AllocationOfIncomeByLinesOfBusiness.FullName(),
										"Date",
										"RoutineOperations",
										"Organization");
	PeriodClosingDates.AddRow(DataSources,
										Metadata.Documents.AllocationOfOtherCosts.FullName(),
										"Date",
										"RoutineOperations",
										"Organization");
	PeriodClosingDates.AddRow(DataSources,
										Metadata.Documents.DeferredExpensesAllocation.FullName(),
										"CostAllocation.Date",
										"RoutineOperations",
										"Organization");
	PeriodClosingDates.AddRow(DataSources,
										Metadata.Documents.InventoryCostCalculation.FullName(),
										"Date",
										"RoutineOperations",
										"Organization");
	PeriodClosingDates.AddRow(DataSources,
										Metadata.Documents.OtherIncomeExpenses.FullName(),
										"Date",
										"RoutineOperations",
										"Organization");
	PeriodClosingDates.AddRow(DataSources,
										Metadata.Documents.OtherIncomeExpenses.FullName(),
										"OtherExpenses.DateRecord",
										"RoutineOperations",
										"OtherExpenses.DateRecord");
	PeriodClosingDates.AddRow(DataSources,
										Metadata.Documents.OtherIncomeExpenses.FullName(),
										"OtherIncome.DateRecord",
										"RoutineOperations",
										"OtherExpenses.DateRecord");
	PeriodClosingDates.AddRow(DataSources,
										Metadata.Documents.MovementOfOtherAssetsAndLiabilities.FullName(),
										"Date",
										"RoutineOperations",
										"Organization");
	PeriodClosingDates.AddRow(DataSources,
										Metadata.Documents.LoanAndDepositInterestCharge.FullName(),
										"Date",
										"RoutineOperations",
										"Organization");
	PeriodClosingDates.AddRow(DataSources,
										Metadata.Documents.ExchangeDifferenceCalculation.FullName(),
										"Date",
										"RoutineOperations",
										"Organization");
	PeriodClosingDates.AddRow(DataSources,
										Metadata.Documents.CalculationOfDiscountInterestExpenses.FullName(),
										"Date",
										"RoutineOperations",
										"Organization");
	PeriodClosingDates.AddRow(DataSources,
										Metadata.Documents.ReversingEntry.FullName(),
										"Date",
										"RoutineOperations",
										"Organization");
	PeriodClosingDates.AddRow(DataSources,
										Metadata.Documents.AccrualAndWriteOffOfBadDebtAlowances.FullName(),
										"Date",
										"RoutineOperations",
										"Organization");
	PeriodClosingDates.AddRow(DataSources,
										Metadata.Documents.FutureExpenseCommitmentsAccrualWriteOff.FullName(),
										"Date",
										"RoutineOperations",
										"Organization");
	PeriodClosingDates.AddRow(DataSources,
										Metadata.Documents.PostingPayrollExpensesInFinancialAccounting2_5.FullName(),
										"CalculationsPeriod",
										"RoutineOperations",
										"");
#EndRegion

//++ WE
#Region PayrollAndPersonnelWE
	
	PeriodClosingDates.AddRow(DataSources,
										Metadata.Documents.PayrollStatementHR.FullName(),
										"DateOfPayment",
										"RoutineOperations",
										"");
	PeriodClosingDates.AddRow(DataSources,
										Metadata.Documents.ChangeInBasicEarnings.FullName(),
										"ChangeDate",
										"RoutineOperations",
										"");
	PeriodClosingDates.AddRow(DataSources,
										Metadata.Documents.ChangeInPermanentAccruals.FullName(),
										"ChangeDate",
										"RoutineOperations",
										"");
	PeriodClosingDates.AddRow(DataSources,
										Metadata.Documents.ChangeInPermanentDeductions.FullName(),
										"ChangeDate",
										"RoutineOperations",
										"");
	PeriodClosingDates.AddRow(DataSources,
										Metadata.Documents.EmployeeTransferHR.FullName(),
										"DateOfTransition",
										"RoutineOperations",
										"");
	PeriodClosingDates.AddRow(DataSources,
										Metadata.Documents.TaxSettings.FullName(),
										"RegistrationMonth",
										"RoutineOperations",
										"");
	PeriodClosingDates.AddRow(DataSources,
										Metadata.Documents.StandardWorkingHours.FullName(),
										"RegistrationMonth",
										"RoutineOperations",
										"");
	PeriodClosingDates.AddRow(DataSources,
										Metadata.Documents.HiringHR.FullName(),
										"DateOfAdmission",
										"RoutineOperations",
										"");
	PeriodClosingDates.AddRow(DataSources,
										Metadata.Documents.ApplyDeductions.FullName(),
										"RegistrationMonth",
										"RoutineOperations",
										"");
	PeriodClosingDates.AddRow(DataSources,
										Metadata.Documents.OneTimeAccrualsHR.FullName(),
										"RegistrationMonth",
										"RoutineOperations",
										"");
	PeriodClosingDates.AddRow(DataSources,
										Metadata.Documents.OneTimeDeductions.FullName(),
										"RegistrationMonth",
										"RoutineOperations",
										"");
	PeriodClosingDates.AddRow(DataSources,
										Metadata.Documents.RegisterPayrollCalculation.FullName(),
										"Date",
										"RoutineOperations",
										"");
	PeriodClosingDates.AddRow(DataSources,
										Metadata.Documents.ManualTaxCalculation.FullName(),
										"RegistrationMonth",
										"RoutineOperations",
										"");
	PeriodClosingDates.AddRow(DataSources,
										Metadata.Documents.ShiftScheduleHR.FullName(),
										"BeginningDateOfPeriod",
										"RoutineOperations",
										"");
	PeriodClosingDates.AddRow(DataSources,
										Metadata.Documents.TimesheetHR.FullName(),
										"BeginningDateOfPeriod",
										"RoutineOperations",
										"");
	PeriodClosingDates.AddRow(DataSources,
										Metadata.Documents.DismissalHR.FullName(),
										"DateOfDismissal",
										"RoutineOperations",
										"");
#EndRegion
//-- WE

#Region RetailSales
	PeriodClosingDates.AddRow(DataSources,
										Metadata.Documents.GiftCertificateCancellation.FullName(),
										"Date",
										"RetailSales",
										"Organization");
	PeriodClosingDates.AddRow(DataSources,
										Metadata.Documents.DepositCashIntoCashRegister.FullName(),
										"Date",
										"RetailSales",
										"Organization");
	PeriodClosingDates.AddRow(DataSources,
										Metadata.Documents.ReturnOfGiftCards.FullName(),
										"Date",
										"RetailSales",
										"Organization");
	PeriodClosingDates.AddRow(DataSources,
										Metadata.Documents.CashWithdrawalFromCashRegister.FullName(),
										"Date",
										"RetailSales",
										"Organization");
	PeriodClosingDates.AddRow(DataSources,
										Metadata.Documents.RetailReturnsReport.FullName(),
										"Date",
										"RetailSales",
										"Organization");
	PeriodClosingDates.AddRow(DataSources,
										Metadata.Documents.RetailSalesReport.FullName(),
										"Date",
										"RetailSales",
										"Organization");
	PeriodClosingDates.AddRow(DataSources,
										Metadata.Documents.GiftCertificateSale.FullName(),
										"Date",
										"RetailSales",
										"Organization");
#EndRegion

#Region DebtReconciliationsAndAdjustments
	PeriodClosingDates.AddRow(DataSources,
										Metadata.Documents.ARAPSettlement.FullName(),
										"Date",
										"DebtReconciliationsAndAdjustments",
										"Organization");
	PeriodClosingDates.AddRow(DataSources,
										Metadata.Documents.ARAPSettlement.FullName(),
										"Date",
										"DebtReconciliationsAndAdjustments",
										"CompanyCreditor");
	PeriodClosingDates.AddRow(DataSources,
										Metadata.Documents.ARAPSettlement.FullName(),
										"Date",
										"DebtReconciliationsAndAdjustments",
										"CounterpartyDebtor");
	PeriodClosingDates.AddRow(DataSources,
										Metadata.Documents.ARAPSettlement.FullName(),
										"Date",
										"DebtReconciliationsAndAdjustments",
										"Creditor");
	PeriodClosingDates.AddRow(DataSources,
										Metadata.Documents.ARAPAdjustment.FullName(),
										"Date",
										"DebtReconciliationsAndAdjustments",
										"Organization");
	PeriodClosingDates.AddRow(DataSources,
										Metadata.Documents.ARAPAdjustment.FullName(),
										"Date",
										"DebtReconciliationsAndAdjustments",
										"Counterparty");
	PeriodClosingDates.AddRow(DataSources,
										Metadata.Documents.ARAPReconciliation2_4.FullName(),
										"Date",
										"DebtReconciliationsAndAdjustments",
										"Organization");
	PeriodClosingDates.AddRow(DataSources,
										Metadata.Documents.ARAPReconciliation2_4.FullName(),
										"Date",
										"DebtReconciliationsAndAdjustments",
										"Counterparty");
	PeriodClosingDates.AddRow(DataSources,
										Metadata.Documents.ARAPReconciliation2_5_11.FullName(),
										"Date",
										"DebtReconciliationsAndAdjustments",
										"Organization");
	PeriodClosingDates.AddRow(DataSources,
										Metadata.Documents.ARAPReconciliation2_5_11.FullName(),
										"Date",
										"DebtReconciliationsAndAdjustments",
										"Counterparty");
	PeriodClosingDates.AddRow(DataSources,
										Metadata.Documents.ARAPAdjustmentFinancialInstruments.FullName(),
										"Date",
										"DebtReconciliationsAndAdjustments",
										"Organization");
	PeriodClosingDates.AddRow(DataSources,
										Metadata.Documents.ARAPAccountingScheduleAdjustment.FullName(),
										"Date",
										"DebtReconciliationsAndAdjustments",
										"Organization");
	PeriodClosingDates.AddRow(DataSources,
										Metadata.Documents.ARAPAccountingScheduleAdjustment.FullName(),
										"Date",
										"DebtReconciliationsAndAdjustments",
										"CompanyRecipient");
	PeriodClosingDates.AddRow(DataSources,
										Metadata.Documents.AdjustmentOfARAPAccountingForAdvanceHolders.FullName(),
										"Date",
										"DebtReconciliationsAndAdjustments",
										"Organization");
#EndRegion

#Region WarehouseTransactions
	PeriodClosingDates.AddRow(DataSources,
										Metadata.Documents.GoodsSurplusesNote.FullName(),
										"Date",
										"WarehouseTransactions",
										"Warehouse");
	PeriodClosingDates.AddRow(DataSources,
										Metadata.Documents.GoodsShortageNote.FullName(),
										"Date",
										"WarehouseTransactions",
										"Warehouse");
	PeriodClosingDates.AddRow(DataSources,
										Metadata.Documents.GoodsMisgradingNote.FullName(),
										"Date",
										"WarehouseTransactions",
										"Warehouse");
	PeriodClosingDates.AddRow(DataSources,
										Metadata.Documents.DamageNote.FullName(),
										"Date",
										"WarehouseTransactions",
										"Warehouse");
	PeriodClosingDates.AddRow(DataSources,
										Metadata.Documents.GoodsTransferNote.FullName(),
										"Date",
										"WarehouseTransactions",
										"Warehouse");
	PeriodClosingDates.AddRow(DataSources,
										Metadata.Documents.GoodsPickingPlacement.FullName(),
										"Date",
										"WarehouseTransactions",
										"Warehouse");
	PeriodClosingDates.AddRow(DataSources,
										Metadata.Documents.InventoryAdjustmentGoodsShipmentOrder.FullName(),
										"Date",
										"WarehouseTransactions",
										"Warehouse");
	PeriodClosingDates.AddRow(DataSources,
										Metadata.Documents.InventoryAdjustmentSurplusesAndShortages.FullName(),
										"Date",
										"WarehouseTransactions",
										"Warehouse");
	PeriodClosingDates.AddRow(DataSources,
										Metadata.Documents.InventoryRecount.FullName(),
										"Date",
										"WarehouseTransactions",
										"Warehouse");
	PeriodClosingDates.AddRow(DataSources,
										Metadata.Documents.GoodsReceiptNote.FullName(),
										"Date",
										"WarehouseTransactions",
										"Warehouse");
	PeriodClosingDates.AddRow(DataSources,
										Metadata.Documents.GoodsIssueNote.FullName(),
										"DateOfShipment",
										"WarehouseTransactions",
										"Warehouse");
	PeriodClosingDates.AddRow(DataSources,
										Metadata.Documents.ReconcileOpeningBalancesByWarehouses.FullName(),
										"Date",
										"WarehouseTransactions",
										"Organization");
	PeriodClosingDates.AddRow(DataSources,
										Metadata.Documents.Trip.FullName(),
										"DateOfDeparture",
										"WarehouseTransactions",
										"DepartureWarehouse");
#EndRegion

#Region FinancialOutline
	PeriodClosingDates.AddRow(DataSources,
										Metadata.AccumulationRegisters.TransferredReturnablePackaging.FullName(),
										"Period",
										"FinancialOutline");
	PeriodClosingDates.AddRow(DataSources,
										Metadata.AccumulationRegisters.GiftCertificates.FullName(),
										"Period",
										"FinancialOutline");
	PeriodClosingDates.AddRow(DataSources,
										Metadata.AccumulationRegisters.ReceivedReturnablePackaging.FullName(),
										"Period",
										"FinancialOutline");
	PeriodClosingDates.AddRow(DataSources,
										Metadata.AccumulationRegisters.OtherAssetsAndLiabilitiesRecords.FullName(),
										"Period",
										"FinancialOutline",
										"Organization");
	PeriodClosingDates.AddRow(DataSources,
										Metadata.AccumulationRegisters.OtherIncome.FullName(),
										"Period",
										"FinancialOutline",
										"Organization");
	PeriodClosingDates.AddRow(DataSources,
										Metadata.AccumulationRegisters.LossAllowance.FullName(),
										"Period",
										"FinancialOutline");
	PeriodClosingDates.AddRow(DataSources,
										Metadata.AccumulationRegisters.GoodsAndServicesToRegisterPurchasingReportsToConsignor.FullName(),
										"Period",
										"FinancialOutline",
										"Organization");
	PeriodClosingDates.AddRow(DataSources,
										Metadata.AccumulationRegisters.ServicesForRegistrationOfReportsToPrincipal.FullName(),
										"Period",
										"FinancialOutline",
										"Organization");
	PeriodClosingDates.AddRow(DataSources,
										Metadata.Documents.ElectronicTicketTransaction.FullName(),
										"Date",
										"FinancialOutline",
										"Organization");
	PeriodClosingDates.AddRow(DataSources,
										Metadata.AccumulationRegisters.RegisterRecordsByExcises.FullName(),
										"Period",
										"FinancialOutline",
										"Organization");
	
#EndRegion

#Region CustomerRebates
	
	PeriodClosingDates.AddRow(DataSources,
										Metadata.Documents.ConditionsOfCustomerRebates.FullName(),
										"Date",
										"CustomerRebates",
										"Organization");
	PeriodClosingDates.AddRow(DataSources,
										Metadata.Documents.DebitCustomerRebates.FullName(),
										"Date",
										"CustomerRebates",
										"Organization");
	PeriodClosingDates.AddRow(DataSources,
										Metadata.Documents.CustomerBonusCertificate.FullName(),
										"AccountingRecognitionDate",
										"CustomerRebates",
										"Organization");
	PeriodClosingDates.AddRow(DataSources,
										Metadata.Documents.AccrualOfCustomerRebates.FullName(),
										"Date",
										"CustomerRebates",
										"Organization");
	
#EndRegion

#Region VendorRebates
	
	PeriodClosingDates.AddRow(DataSources,
										Metadata.Documents.AccrualOfVendorRebates.FullName(),
										"Date",
										"VendorRebates",
										"Organization");
	
	PeriodClosingDates.AddRow(DataSources,
										Metadata.Documents.WriteOffVendorRebates.FullName(),
										"Date",
										"VendorRebates",
										"Organization");
	
	PeriodClosingDates.AddRow(DataSources,
										Metadata.Documents.ConditionsOfVendorRebates.FullName(),
										"Date",
										"VendorRebates",
										"Organization");
	
	PeriodClosingDates.AddRow(DataSources,
										Metadata.Documents.VendorBonusCertificate.FullName(),
										"Date",
										"VendorRebates",
										"Organization");
	
#EndRegion

	InformationRegisters.JobsForMonthEndClosing.DescriptionOfRegistersForControlOfDatesOfProhibitionOfChange(DataSources);
	InformationRegisters.JobsForCalculatingCost.DescriptionOfRegistersForControlOfDatesOfProhibitionOfChange(DataSources);
	InformationRegisters.JobsForAllocatingCustomersARAP.DescriptionOfRegistersForControlOfDatesOfProhibitionOfChange(DataSources);
	InformationRegisters.JobsForAllocatingVendorsARAP.DescriptionOfRegistersForControlOfDatesOfProhibitionOfChange(DataSources);

	VATAccountingERP.FillDataSourcesForPeriodClosingCheck(DataSources);
	PeriodClosingDates.AddRow(DataSources,
										Metadata.InformationRegisters.IndicatorValuesToAllocateCosts.FullName(),
										"Period", "FinancialOutline","Factor.Organization");
										
	PeriodClosingDates.AddRow(DataSources,
										Metadata.InformationRegisters.IndicatorValuesForAllocatingExpensesBetweenExpenseObjects.FullName(),
										"Period", "FinancialOutline","CONSTCENTER.Organization");
EndProcedure

// See PeriodClosingDatesOverridable.BeforeCheckPeriodClosing
Procedure BeforeCheckPeriodClosing(Object, PeriodClosingCheck, ImportRestrictionCheckNode, ObjectVersion) Export
	
	If Common.IsRegister(Object.Metadata())
	 And Object.Filter.Find("Recorder") <> Undefined Then
		TypeOfRegistrar = TypeOf(Object.Filter.Recorder.Value); // this is a set of records of the registrar document
		Recorder = Object.Filter.Recorder.Value;
	Else
		TypeOfRegistrar = Undefined;
		Recorder = Undefined;
	EndIf;
	
	ObjectType = TypeOf(Object);
		
	If ObjectType = Type("DocumentObject.BankAccountIssue")
	 Or ObjectType = Type("DocumentObject.BankAccountReceiptNote") Then
		
		// Refusal of verification, taking into account the fact that the date of verification by the Bank used in the verification is not indicated
		// if the document is not carried out by the bank, but is indicated later, after the document is carried out by the bank.
		ProcessedByBankNewVersion  = Object.ProcessedByBank;
		ProcessedByBankOldVersion = Common.ObjectAttributeValue(
			Object.Ref, "ProcessedByBank") = True;
		
		If Not ProcessedByBankNewVersion And Not ProcessedByBankOldVersion Then
			PeriodClosingCheck = False;
			ImportRestrictionCheckNode = Undefined;
			
		ElsIf Not ProcessedByBankNewVersion Then
			ObjectVersion = "OldVersion"; // Check only the new version of the object.
			
		ElsIf Not ProcessedByBankOldVersion Then
			ObjectVersion = "NewVersion"; // Check only the old version of the object.
		EndIf;
		
	EndIf;
	
	ThereIsPropertyCheckingDateWhenChangesWereBanned = False;
	CheckCheckModificationBanDateProperty(Object, PeriodClosingCheck, ThereIsPropertyCheckingDateWhenChangesWereBanned);
	
	// For the distribution of RBP, the verification of the prohibition of changes is implemented in the form of a document.
	If Not ThereIsPropertyCheckingDateWhenChangesWereBanned
	 And (ObjectType = Type("DocumentObject.DeferredExpensesAllocation")
	 Or TypeOfRegistrar = Type("DocumentRef.DeferredExpensesAllocation")) Then
		PeriodClosingCheck = False;
	EndIf;
	
	// For plans, the change ban check is implemented in the object module.
	If ObjectType = Type("DocumentObject.PurchasePlan")
	 Or TypeOfRegistrar = Type("DocumentRef.PurchasePlan")
	 Or ObjectType = Type("DocumentObject.PlanOfGoodsStock")
	 Or TypeOfRegistrar = Type("DocumentRef.PlanOfGoodsStock") 
	 Or ObjectType = Type("DocumentObject.SalesPlan")
	 Or TypeOfRegistrar = Type("DocumentRef.SalesPlan")
	 Or ObjectType = Type("DocumentObject.SalesPlanByCategories")
	 Or TypeOfRegistrar = Type("DocumentRef.SalesPlanByCategories")
	 Or ObjectType = Type("DocumentObject.ProductionPlan")
	 Or TypeOfRegistrar = Type("DocumentRef.ProductionPlan")
	 Or ObjectType = Type("DocumentObject.AssemblyDisassemblyPlan")
	 Or TypeOfRegistrar = Type("DocumentRef.AssemblyDisassemblyPlan")
	 Or ObjectType = Type("DocumentObject.InventoryConsumptionPlan")
	 Or TypeOfRegistrar = Type("DocumentRef.InventoryConsumptionPlan") Then
		PeriodClosingCheck = False;
	EndIf;
	
	// For production stages, the change prohibition check is implemented in the object module.
	If ObjectType = Type("DocumentObject.ProductionStage2_2")
	 Or TypeOfRegistrar = Type("DocumentRef.ProductionStage2_2") Then
		PeriodClosingCheck = False;
	EndIf;
	
	
	// Production operations are checked only in the final statuses.
	If ObjectType = Type("DocumentObject.ProductionOperation2_2") Then
		
		CheckNewVersion  = Object.Status = Enums.ProductionOperationStatuses.Executed;
		OldStatus 		  = Common.ObjectAttributeValue(Object.Ref, "Status");
		CheckOldVersion = OldStatus = Enums.ProductionOperationStatuses.Executed;
		
		If Not CheckNewVersion And Not CheckOldVersion Then
			PeriodClosingCheck = False;
		ElsIf Not CheckNewVersion Then
			ObjectVersion = "OldVersion";
		ElsIf Not CheckOldVersion Then
			ObjectVersion = "NewVersion"; 
		EndIf;
		
	EndIf;
	//Budgeting
	If ObjectType = Type("DocumentObject.BudgetEntryForm") 
		Or ObjectType = Type("DocumentObject.SetValuesForNonFinancialItems")
		Or ObjectType = Type("DocumentObject.SettingOfEstimatesOpeningBalance") Then
			
		If IsInRole("EditingBudgetingDataOutsideClosingDates") Then
			PeriodClosingCheck = False;
		EndIf;
		
	EndIf;
	// There is no need to check the movements of orders and requests for the consumption of DS according to the calculation registers.
	If ObjectType = Type("AccumulationRegisterRecordSet.CustomersARAPAccounting")
	 And (TypeOfRegistrar = Type("DocumentRef.SalesOrder")
		Or TypeOfRegistrar = Type("DocumentRef.ContractSchedule")
		Or TypeOfRegistrar = Type("DocumentRef.RequestForReturnOfGoodsFromCustomer")
		 Or TypeOfRegistrar = Type("DocumentRef.MaterialProviderOrder2_5")
		) Then
		
		PeriodClosingCheck = False;
		
	ElsIf ObjectType = Type("AccumulationRegisterRecordSet.VendorsARAPAccounting")
	 And (TypeOfRegistrar = Type("DocumentRef.PurchaseOrder")
		Or TypeOfRegistrar = Type("DocumentRef.ContractSchedule")
		 Or TypeOfRegistrar = Type("DocumentRef.SubcontractOrder2_5")
		) Then
		
		PeriodClosingCheck = False;
		
	ElsIf TypeOfRegistrar = Type("DocumentRef.PaymentRequest") Then
		
		PeriodClosingCheck = False;
		
	EndIf;
	
	// For shipment without transfer of ownership in the closed period
	If (ObjectType = Type("DocumentObject.CustomerInvoice")
	 Or ObjectType = Type("DocumentObject.CustomerInvoiceServicesAndAssets"))
		And Object.AdditionalProperties.Property("OnlyStateOfTransferOfOwnershipHasChanged")
		And Object.AdditionalProperties.OnlyStateOfTransferOfOwnershipHasChanged Then
		
		ObjectVersion = "NewVersion"; // Check only the new version of the object.
		
	EndIf;
	
	// To change the status of Reconciliation of settlements in the closed period
	If (ObjectType = Type("DocumentObject.ARAPReconciliation2_4")
			Or ObjectType = Type("DocumentObject.ARAPReconciliation2_5_11")) 
		And Object.AdditionalProperties.Property("OnlyVerifiedOnReconciliationStatusHasChanged")
		And Object.AdditionalProperties.OnlyVerifiedOnReconciliationStatusHasChanged Then 
		
		PeriodClosingCheck = False;		
				
	EndIf;
	
	If TypeOfRegistrar = Type("DocumentRef.ElectronicTicketTransaction") Then
		PeriodClosingCheck = False;
	EndIf;
	
	If ObjectType = Type("DocumentObject.CustomerBonusCertificate") Then
		
		PerformNewVersionCheck = False;
		PerformVerificationOfOldVersion = False;
		
		If Object.Status = Enums.CustomerBonusCertificateStatuses.Received
		   And Object.AccountingRecognitionDate <> Date(1, 1, 1) Then
			
			PerformNewVersionCheck = True;
			
		EndIf;
		
		Attributes = "Status, AccountingRecognitionDate";
		AttributesValues = Common.ObjectAttributesValues(Object.Ref, Attributes);
		
		If AttributesValues.Status = Enums.CustomerBonusCertificateStatuses.Received
		   And AttributesValues.AccountingRecognitionDate <> Date(1, 1, 1) Then
			
			PerformVerificationOfOldVersion = True;
			
		EndIf;
		
		If Not PerformNewVersionCheck
		   And Not PerformVerificationOfOldVersion Then
			
			PeriodClosingCheck = False;
			ImportRestrictionCheckNode = Undefined;
			
		ElsIf PerformNewVersionCheck Then
			
			ObjectVersion = "NewVersion";
			
		Else
			
			ObjectVersion = "OldVersion";
			
		EndIf;
		
	EndIf;
	
	If ObjectType = Type("DocumentObject.ConditionsOfVendorRebates")
	 Or ObjectType = Type("DocumentObject.ConditionsOfCustomerRebates") Then
		
		CheckNewVersion = Object.AccrueImmediately;
		CheckOldVersion = False;
		
		If ValueIsFilled(Object.Ref) Then
			CheckOldVersion = Common.ObjectAttributeValue(Object.Ref, "AccrueImmediately");
		EndIf;
		
		If Not CheckNewVersion
		   And Not CheckOldVersion Then
			PeriodClosingCheck = False;
		ElsIf Not CheckNewVersion Then
			ObjectVersion = "OldVersion";
		ElsIf Not CheckOldVersion Then
			ObjectVersion = "NewVersion";
		EndIf;
		
	EndIf;
	
	If ObjectType = Type("DocumentObject.Trip") Then
		
		CheckOldVersion = False;
		CheckNewVersion = (Object.DateOfDeparture <> Date(1, 1, 1));
		
		If ValueIsFilled(Object.Ref) Then
			
			DateOfOldVersion = Common.ObjectAttributeValue(Object.Ref, "DateOfDeparture");
			If DateOfOldVersion <> Date(1, 1, 1) Then
				
				CheckOldVersion = True;
				
			EndIf;
			
		EndIf;
		
		If Not CheckOldVersion
		   And Not CheckNewVersion Then
			
			PeriodClosingCheck = False;
			
		ElsIf Not CheckNewVersion Then
			
			ObjectVersion = "OldVersion";
			
		ElsIf Not CheckOldVersion Then
			
			ObjectVersion = "NewVersion";
			
		EndIf;
	EndIf;

		
	If CostCalculationAppliedAlgorithms.ThisIsServiceDocumentForConvertingBalances(Object)
	 Or CostCalculationAppliedAlgorithms.ThisIsServiceDocumentForConvertingBalances(Recorder) Then
		PeriodClosingCheck = False;
	EndIf;
	
EndProcedure

// The procedure adds a parameter to the additional properties that disables checking the date when changes were forbidden.
//
// Parameters:
//  Object       - CatalogObject,
//                 Document object,
//                 Provideopportunities,
//                 Planscontact,
//                 Providesdetailed,
//                 Business processobject,
//                 Taskobject,
//                 Planobmenaobject - a data object (before Writing or adding to the Server).
//                 Register
//                 Of Leadingset Of Records, Register Of Listingset Of Records, Register Of Bookgalteryinabor Of
//                 Records.
//
Procedure DisableVerificationOfDateWhenChangesWereBanned(Object) Export
	
	Object.AdditionalProperties.Insert("CheckingDateWhenChangesWereBanned", False);
	
EndProcedure

// The procedure adds a parameter to the additional properties that forcibly enables checking the date when changes were forbidden.
//
// Parameters:
//  Object       - CatalogObject,
//                 Document object,
//                 Provideopportunities,
//                 Planscontact,
//                 Providesdetailed,
//                 Business processobject,
//                 Taskobject,
//                 Planobmenaobject - a data object (before Writing or adding to the Server).
//                 Register
//                 Of Leadingset Of Records, Register Of Listingset Of Records, Register Of Bookgalteryinabor Of
//                 Records.
//
Procedure EnableVerificationOfDateWhenChangesWereBanned(Object) Export
	
	Object.AdditionalProperties.Insert("CheckingDateWhenChangesWereBanned", True);
	
EndProcedure

// See PeriodClosingDatesOverridable.BeforeCheckOldDataVersion
Procedure BeforeCheckOldDataVersion(MetadataObject, DataID, ImportRestrictionCheckNode, DataToCheck) Export
	
	If TypeOf(DataID) = Type("DocumentRef.ReversingEntry") Then
		
		Data = Common.ObjectAttributesValues(DataID, "ReversedDocument, Date");
		TypeOfFoundationDocument = Data.ReversedDocument.Metadata().FullName();
		BanDatesAreValid = PeriodClosingDatesInternal.DataSourcesForPeriodClosingCheck();
		DatesOfProhibitionOnGrounds = BanDatesAreValid.Get(TypeOfFoundationDocument);
		
		For Each Prohibition In DatesOfProhibitionOnGrounds.Content Do
			Section = Prohibition.Section;
			PathToObjectField = Prohibition.ObjectField.Name;
			
			NewRow			= DataToCheck.Add();
			NewRow.Date	= Data.Date;
			NewRow.Section	= Section;
			If ValueIsFilled(PathToObjectField) Then
				NewRow.Object	= Common.ObjectAttributeValue(Data.ReversedDocument, PathToObjectField);
			EndIf;
		EndDo; 
	ElsIf TypeOf(DataID) = Type("DocumentRef.BankAccountIssue") Then
		
		AttributesValues = Common.ObjectAttributesValues(DataID, "Date, Patch, BankAccount"); 
		If AttributesValues.Patch Then
			NewRow			= DataToCheck.Add();
			NewRow.Date	= AttributesValues.Date; 
			NewRow.Section	= "Bank";
			NewRow.Object  = AttributesValues.BankAccount;
		EndIf;
	ElsIf TypeOf(DataID) = Type("DocumentRef.BankAccountReceiptNote") Then
		
		AttributesValues = Common.ObjectAttributesValues(DataID, "Date, Patch, BankAccount"); 
		If AttributesValues.Patch Then
			NewRow			= DataToCheck.Add();
			NewRow.Date	= AttributesValues.Date;
			NewRow.Section	= "Bank";
			NewRow.Object  = AttributesValues.BankAccount;
		EndIf;
	ElsIf TypeOf(DataID) = Type("DocumentRef.TransferOfGoodsToBailee")
		Or TypeOf(DataID) = Type("DocumentRef.GoodsReceiptForStorage")
		Or TypeOf(DataID) = Type("DocumentRef.GoodsShipmentFromStorage")
		Or TypeOf(DataID) = Type("DocumentRef.ReportOnVMIAdjustment")
		Or TypeOf(DataID) = Type("DocumentRef.ReceiptOfGoodsFromCustodian")
		Or TypeOf(DataID) = Type("DocumentRef.MisgradingOfGoodsAtCustodian")
		Or TypeOf(DataID) = Type("DocumentRef.DamageAtCustodian") Then
		
		AttributesValues = Common.ObjectAttributesValues(DataID, "Date, Organization, BusinessOperation");
		If AttributesValues.BusinessOperation = Enums.BusinessTransactions.TransferToToller2_5
			Or AttributesValues.BusinessOperation = Enums.BusinessTransactions.ReceiptFromMaterialProvider2_5
			Or AttributesValues.BusinessOperation = Enums.BusinessTransactions.TransferToMaterialProvider2_5
			Or AttributesValues.BusinessOperation = Enums.BusinessTransactions.ReturnToMaterialProvider2_5
			Or AttributesValues.BusinessOperation = Enums.BusinessTransactions.ProviderGoodsWriteOffAtTheExpenseOfProvider
			Or AttributesValues.BusinessOperation = Enums.BusinessTransactions.ReceiptFromToller2_5
			Or AttributesValues.BusinessOperation = Enums.BusinessTransactions.ReturnFromProcessingCompany2_5
			Or AttributesValues.BusinessOperation = Enums.BusinessTransactions.MisgradingOfGoodsAtToller
			Or AttributesValues.BusinessOperation = Enums.BusinessTransactions.DamageAtToller Then
			NewRow			= DataToCheck.Add();
			NewRow.Date	= AttributesValues.Date;
			NewRow.Section	= "Production";
			NewRow.Object  = AttributesValues.Organization;
		EndIf;
	ElsIf TypeOf(DataID) = Type("DocumentRef.RedemptionOfGoodsFromStorage")
		Or TypeOf(DataID) = Type("DocumentRef.ReportOnVMIAdjustment") Then
		
		AttributesValues = Common.ObjectAttributesValues(DataID, "Date, Organization, BusinessOperation");
		If AttributesValues.BusinessOperation = Enums.BusinessTransactions.RedemptionOfProviderGoods
			Or AttributesValues.BusinessOperation = Enums.BusinessTransactions.ProviderGoodsWriteOffAsExpenses Then
			NewRow			= DataToCheck.Add();
			NewRow.Date	= AttributesValues.Date;
			NewRow.Section	= "Purchases";
			NewRow.Object  = AttributesValues.Organization;
		EndIf;
	ElsIf TypeOf(DataID) = Type("DocumentRef.RedemptionOfGoodsByCustodian")
		Or TypeOf(DataID) = Type("DocumentRef.WriteOffOfShippedGoods") Then
		
		AttributesValues = Common.ObjectAttributesValues(DataID, "Date, Organization, BusinessOperation");
		If AttributesValues.BusinessOperation = Enums.BusinessTransactions.RedemptionOfGoodsByToller
			Or AttributesValues.BusinessOperation = Enums.BusinessTransactions.GoodsWriteOffAtToller Then
			NewRow			= DataToCheck.Add();
			NewRow.Date	= AttributesValues.Date;
			NewRow.Section	= "Sales";
			NewRow.Object  = AttributesValues.Organization;
		EndIf;
	EndIf;
	
EndProcedure

// See PeriodClosingDatesOverridable.BeforeCheckNewDataVersion
Procedure BeforeCheckNewDataVersion(MetadataObject, Data, ImportRestrictionCheckNode, DataToCheck) Export

	If TypeOf(Data) = Type("DocumentObject.ReversingEntry") Then
		
		TypeOfFoundationDocument = Data.ReversedDocument.Metadata().FullName();
		BanDatesAreValid = PeriodClosingDatesInternal.DataSourcesForPeriodClosingCheck();
		DatesOfProhibitionOnGrounds = BanDatesAreValid.Get(TypeOfFoundationDocument);
		
		For Each Prohibition In DatesOfProhibitionOnGrounds.Content Do
			Section = Prohibition.Section;
			PathToObjectField = Prohibition.ObjectField.Name;
			
			NewRow			= DataToCheck.Add();
			NewRow.Date	= Data.Date;
			NewRow.Section	= Section;
			If ValueIsFilled(PathToObjectField) Then
				NewRow.Object	= Common.ObjectAttributeValue(Data.ReversedDocument, PathToObjectField);
			EndIf;
		EndDo; 
	ElsIf TypeOf(Data) = Type("DocumentObject.BankAccountIssue") And Data.Patch Then
		
		NewRow			= DataToCheck.Add();
		NewRow.Date	= Data.Date;
		NewRow.Section	= "Bank";
		NewRow.Object	= Data.BankAccount;
		
	ElsIf TypeOf(Data) = Type("DocumentObject.BankAccountReceiptNote") And Data.Patch Then
		
		NewRow			= DataToCheck.Add();
		NewRow.Date	= Data.Date;
		NewRow.Section	= "Bank";
		NewRow.Object	= Data.BankAccount;
		
	ElsIf (TypeOf(Data) = Type("DocumentObject.CustomerInvoice")
				Or TypeOf(Data) = Type("DocumentObject.CustomerInvoiceServicesAndAssets"))
		And Data.AdditionalProperties.Property("OnlyStateOfTransferOfOwnershipHasChanged")
		And Data.AdditionalProperties.OnlyStateOfTransferOfOwnershipHasChanged
		And ValueIsFilled(Data.DateOfTransferOfTitleToGoods) Then
		
		NewRow			= DataToCheck.Add();
		NewRow.Date	= Data.DateOfTransferOfTitleToGoods;
		NewRow.Section	= "Sales";
	ElsIf TypeOf(Data) = Type("DocumentObject.TransferOfGoodsToBailee")
		Or TypeOf(Data) = Type("DocumentObject.GoodsReceiptForStorage")
		Or TypeOf(Data) = Type("DocumentObject.GoodsShipmentFromStorage")
		Or TypeOf(Data) = Type("DocumentObject.ReportOnVMIAdjustment")
		Or TypeOf(Data) = Type("DocumentObject.ReceiptOfGoodsFromCustodian")
		Or TypeOf(Data) = Type("DocumentObject.MisgradingOfGoodsAtCustodian")
		Or TypeOf(Data) = Type("DocumentObject.DamageAtCustodian") Then
		
		If Data.BusinessOperation = Enums.BusinessTransactions.TransferToToller2_5
			Or Data.BusinessOperation = Enums.BusinessTransactions.ReceiptFromMaterialProvider2_5
			Or Data.BusinessOperation = Enums.BusinessTransactions.TransferToMaterialProvider2_5
			Or Data.BusinessOperation = Enums.BusinessTransactions.ReturnToMaterialProvider2_5
			Or Data.BusinessOperation = Enums.BusinessTransactions.ProviderGoodsWriteOffAtTheExpenseOfProvider
			Or Data.BusinessOperation = Enums.BusinessTransactions.ReceiptFromToller2_5
			Or Data.BusinessOperation = Enums.BusinessTransactions.ReturnFromProcessingCompany2_5
			Or Data.BusinessOperation = Enums.BusinessTransactions.MisgradingOfGoodsAtToller
			Or Data.BusinessOperation = Enums.BusinessTransactions.DamageAtToller Then
			NewRow			= DataToCheck.Add();
			NewRow.Date	= Data.Date;
			NewRow.Section	= "Production";
			NewRow.Object  = Data.Organization;
		EndIf;
	ElsIf TypeOf(Data) = Type("DocumentObject.RedemptionOfGoodsFromStorage")
		Or TypeOf(Data) = Type("DocumentObject.ReportOnVMIAdjustment") Then
		
		If Data.BusinessOperation = Enums.BusinessTransactions.RedemptionOfProviderGoods
			Or Data.BusinessOperation = Enums.BusinessTransactions.ProviderGoodsWriteOffAsExpenses Then
			NewRow			= DataToCheck.Add();
			NewRow.Date	= Data.Date;
			NewRow.Section	= "Purchases";
			NewRow.Object  = Data.Organization;
		EndIf;
	ElsIf TypeOf(Data) = Type("DocumentObject.RedemptionOfGoodsByCustodian")
		Or TypeOf(Data) = Type("DocumentObject.WriteOffOfShippedGoods") Then
		
		If Data.BusinessOperation = Enums.BusinessTransactions.RedemptionOfGoodsByToller
			Or Data.BusinessOperation = Enums.BusinessTransactions.GoodsWriteOffAtToller Then
			NewRow			= DataToCheck.Add();
			NewRow.Date	= Data.Date;
			NewRow.Section	= "Sales";
			NewRow.Object  = Data.Organization;
		EndIf;
	EndIf;
	
EndProcedure

#EndRegion

#Region Private

Procedure CheckCheckModificationBanDateProperty(Object, ExecuteCheck1, ThereIsPropertyCheckingDateWhenChangesWereBanned)
	
	ThereIsPropertyCheckingDateWhenChangesWereBanned = Object.AdditionalProperties.Property("CheckingDateWhenChangesWereBanned");
	If ThereIsPropertyCheckingDateWhenChangesWereBanned Then
		ExecuteCheck1 = Object.AdditionalProperties.CheckingDateWhenChangesWereBanned;
	EndIf;
	
EndProcedure

#EndRegion