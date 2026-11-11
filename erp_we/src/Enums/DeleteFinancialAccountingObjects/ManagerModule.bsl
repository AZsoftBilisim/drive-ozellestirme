#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region Internal

// Returns the compliance of financial accounting items with asset and liability items.
// Returns:
//  Map of KeyAndValue:
//  * Key - EnumRef.DeleteFinancialAccountingObjects
//  * Value - ChartOfCharacteristicTypesRef.AssetLiabilityItems
//
Function ComplianceOfFinancialAccountingObjectsWithItemsOfAssetsLiabilities() Export
	
	ComplianceOfObjectsWithArticles = New Map();
	AssetLiabilityItems = ChartsOfCharacteristicTypes.AssetLiabilityItems;
	
	ComplianceOfObjectsWithArticles.Insert(PrepaymentLeaseBuyoutValue, AssetLiabilityItems.AdvancePaymentForPurchaseOfRentalItem);
	ComplianceOfObjectsWithArticles.Insert(PrepaymentsToVendors, AssetLiabilityItems.PrepaymentsToVendors);
	ComplianceOfObjectsWithArticles.Insert(PrepaymentsFromCustomers, AssetLiabilityItems.PrepaymentsFromCustomers);
	ComplianceOfObjectsWithArticles.Insert(IntangibleAssetsAmortizationCharge, AssetLiabilityItems.IntangibleAssetsAmortizationCharge);
	ComplianceOfObjectsWithArticles.Insert(FixedAssetsDepreciationCharge, AssetLiabilityItems.FixedAssetsDepreciationCharge);
	ComplianceOfObjectsWithArticles.Insert(LeaseObligations, AssetLiabilityItems.LeaseObligations);
	ComplianceOfObjectsWithArticles.Insert(RentalPayments, AssetLiabilityItems.RentalPayments);
	ComplianceOfObjectsWithArticles.Insert(TicketsAndBooking, AssetLiabilityItems.TicketsBooking);
	ComplianceOfObjectsWithArticles.Insert(OBEntry, AssetLiabilityItems.OBEntry);
	ComplianceOfObjectsWithArticles.Insert(BranchOfficeAccounting, AssetLiabilityItems.BranchOfficeARAPAccounting);
	ComplianceOfObjectsWithArticles.Insert(BranchOfficeAssetsAccounting, AssetLiabilityItems.BranchOfficeAssetsARAPAccounting);
	ComplianceOfObjectsWithArticles.Insert(IncomingVAT, AssetLiabilityItems.VATOnPurchasedCommodities);
	ComplianceOfObjectsWithArticles.Insert(LeaseBuyoutValue, AssetLiabilityItems.RedemptionOfRentalItem);
	ComplianceOfObjectsWithArticles.Insert(ProductsRelease, AssetLiabilityItems.ProductsRelease);
	ComplianceOfObjectsWithArticles.Insert(SalesRevenue, AssetLiabilityItems.RevenueFromSalesWithVAT);
	ComplianceOfObjectsWithArticles.Insert(SalesRevenueExcludingVAT, AssetLiabilityItems.SalesRevenue);
	ComplianceOfObjectsWithArticles.Insert(CashInCashRegisters, AssetLiabilityItems.CashInCashRegisters);
	ComplianceOfObjectsWithArticles.Insert(CashInCashRegistersCR, AssetLiabilityItems.CashInCashRegistersCR);
	ComplianceOfObjectsWithArticles.Insert(CashInTransit, AssetLiabilityItems.CashInTransit);
	ComplianceOfObjectsWithArticles.Insert(BankAccountBalance, AssetLiabilityItems.BankAccountBalance);
	ComplianceOfObjectsWithArticles.Insert(CustomersAccountsReceivable, AssetLiabilityItems.CustomersAccountsReceivable);
	ComplianceOfObjectsWithArticles.Insert(VendorAccountsReceivable, AssetLiabilityItems.VendorAccountsReceivable);
	ComplianceOfObjectsWithArticles.Insert(ContinuingOperationIncomeClosing, AssetLiabilityItems.ContinuingOperationIncomeClosing);
	ComplianceOfObjectsWithArticles.Insert(ContinuingOperationExpenseClosing, AssetLiabilityItems.ContinuingOperationExpenseClosing);
	ComplianceOfObjectsWithArticles.Insert(LoansAndBorrowingsIssuedDebt, AssetLiabilityItems.DepositsLoansLoansIssuedDebt);
	ComplianceOfObjectsWithArticles.Insert(LoansAndBorrowingsIssuedFee, AssetLiabilityItems.DepositsLoansLoansIssuedFee);
	ComplianceOfObjectsWithArticles.Insert(LoansAndBorrowingsIssuedInterest, AssetLiabilityItems.DepositsLoansLoansIssuedInterest);
	ComplianceOfObjectsWithArticles.Insert(LoansAndBorrowingsReceivedDebt, AssetLiabilityItems.LoansAndBorrowingsReceivedDebt);
	ComplianceOfObjectsWithArticles.Insert(LoansAndBorrowingsReceivedFee, AssetLiabilityItems.LoansAndBorrowingsReceivedFee);
	ComplianceOfObjectsWithArticles.Insert(LoansAndBorrowingsInterestReceived, AssetLiabilityItems.LoansAndBorrowingsInterestReceived);
	ComplianceOfObjectsWithArticles.Insert(MaterialsAndWorksInProgress, AssetLiabilityItems.MaterialsOfWorkInProgress);
	ComplianceOfObjectsWithArticles.Insert(VATForLease, AssetLiabilityItems.VATForLease);
	ComplianceOfObjectsWithArticles.Insert(VATForShipmentsWithDeferredTransferOfTitle, AssetLiabilityItems.VATForShipmentsWithDeferredTransferOfTitle);
	ComplianceOfObjectsWithArticles.Insert(VATFromPrepaymentsToVendor, AssetLiabilityItems.VATFromPrepaymentsToVendor);
	ComplianceOfObjectsWithArticles.Insert(VATFromPrepaymentsFromCustomer, AssetLiabilityItems.VATFromPrepaymentsFromCustomer);
	ComplianceOfObjectsWithArticles.Insert(VATFromSales, AssetLiabilityItems.VATFromSales);
	ComplianceOfObjectsWithArticles.Insert(VATFromOtherIncome, AssetLiabilityItems.NDSSOfOtherSales);
	ComplianceOfObjectsWithArticles.Insert(NonGuaranteedResidualValueFinancialLease, AssetLiabilityItems.NonGuaranteedResidualValueFinancialLease);
	ComplianceOfObjectsWithArticles.Insert(ItemInTransit, AssetLiabilityItems.GoodsAndMaterialsInTransitFromSuppliers);
	ComplianceOfObjectsWithArticles.Insert(ItemsInShopStoreroom, AssetLiabilityItems.MaterialsInShopStorerooms);
	ComplianceOfObjectsWithArticles.Insert(InventoryItemsInStock, AssetLiabilityItems.GoodsAndMaterialsInWarehouses);
	ComplianceOfObjectsWithArticles.Insert(ItemShipped, AssetLiabilityItems.ShippedGoods_);
	ComplianceOfObjectsWithArticles.Insert(ItemTransferredForProcessing, AssetLiabilityItems.MaterialsTransferredForRecycling);
	ComplianceOfObjectsWithArticles.Insert(ItemsSubmittedForCommission, AssetLiabilityItems.GoodsTransferredToCommissionAgent);
	ComplianceOfObjectsWithArticles.Insert(ItemHandedOverToSubConsignment, AssetLiabilityItems.GoodsSubmittedToSubCommission);
	ComplianceOfObjectsWithArticles.Insert(ItemTransferredForStorage, AssetLiabilityItems.GoodsMaterialsTransferredForStorage);
	ComplianceOfObjectsWithArticles.Insert(ItemReceivedForSubcontractingInProduction, AssetLiabilityItems.MaterialsAcceptedForProcessingInProduction);
	ComplianceOfObjectsWithArticles.Insert(ItemReceivedForSubcontractingInAShopFloorStockroom, AssetLiabilityItems.MaterialsAcceptedForProcessingInShopStorerooms);
	ComplianceOfObjectsWithArticles.Insert(ProductsReceivedForSubcontractingToWriteOff, AssetLiabilityItems.MaterialsAcceptedForProcessingInWarehouses);
	ComplianceOfObjectsWithArticles.Insert(ItemReceivedForSubcontractingAtAWarehouse, AssetLiabilityItems.MaterialsAcceptedForProcessingInWarehouses);
	ComplianceOfObjectsWithArticles.Insert(ProductsReceivedForSubcontractingTransferredToPartners, AssetLiabilityItems.MaterialsReceivedForSubcontractingTransferredToPartners);
	ComplianceOfObjectsWithArticles.Insert(ConsignedItemReceived, AssetLiabilityItems.GoodsReceivedByCommissionAgent);
	ComplianceOfObjectsWithArticles.Insert(ItemReceivedForStorageInProduction, AssetLiabilityItems.GoodsMaterialsAcceptedForStorageInProduction);
	ComplianceOfObjectsWithArticles.Insert(ItemReceivedForStorageInAShopFloorStockroom, AssetLiabilityItems.GoodsMaterialsAcceptedForStorageInShopStorerooms);
	ComplianceOfObjectsWithArticles.Insert(VMIToWriteOff, AssetLiabilityItems.GoodsMaterialsAcceptedForStorageInWarehouses);
	ComplianceOfObjectsWithArticles.Insert(ItemReceivedForStorageAtAWarehouse, AssetLiabilityItems.GoodsMaterialsAcceptedForStorageInWarehouses);
	ComplianceOfObjectsWithArticles.Insert(VMITransferredToPartners, AssetLiabilityItems.GoodsMaterialsAcceptedForStorageTransferredToPartners);
	ComplianceOfObjectsWithArticles.Insert(SecurityPaymentForLease, AssetLiabilityItems.SecurityPaymentForLease);
	ComplianceOfObjectsWithArticles.Insert(ImpairmentIA, AssetLiabilityItems.ImpairmentIA);
	ComplianceOfObjectsWithArticles.Insert(FAImpairment, AssetLiabilityItems.FAImpairment);
	ComplianceOfObjectsWithArticles.Insert(ObligationsToProcurementCommittee, AssetLiabilityItems.ObligationsToProcurementCommittee);
	ComplianceOfObjectsWithArticles.Insert(ObligationsToCommiteeForGoodsSold, AssetLiabilityItems.ObligationsToCommiteeForGoodsSold);
	ComplianceOfObjectsWithArticles.Insert(ObligationsToPrincipalForServicesProvided, AssetLiabilityItems.ObligationsToPrincipalForServicesProvided);
	ComplianceOfObjectsWithArticles.Insert(LiabilitiesForGoodsReceivedNotInvoiced, AssetLiabilityItems.LiabilitiesForGoodsReceivedNotInvoiced);
	ComplianceOfObjectsWithArticles.Insert(ItemCostVariances, AssetLiabilityItems.DeviationsInValueOfInventory);
	ComplianceOfObjectsWithArticles.Insert(TransferredReturnablePackaging, AssetLiabilityItems.TransferredReturnablePackaging);
	ComplianceOfObjectsWithArticles.Insert(FixedAssetsProvided, AssetLiabilityItems.FixedAssetSaleWithDeferredTransferOfTitleIs);
	ComplianceOfObjectsWithArticles.Insert(GiftCertificates, AssetLiabilityItems.GiftCertificates);
	ComplianceOfObjectsWithArticles.Insert(ItemizedCostsInWorkInProgress, AssetLiabilityItems.ItemizedCostsInWorkInProgress);
	ComplianceOfObjectsWithArticles.Insert(ReceivedReturnablePackaging, AssetLiabilityItems.ReceivedReturnablePackaging);
	ComplianceOfObjectsWithArticles.Insert(DiscountInterestExpense, AssetLiabilityItems.PercentagesOfDiscountingSettlements);
	ComplianceOfObjectsWithArticles.Insert(InterestOnDiscountingRentalPaymentsFinancialLease, AssetLiabilityItems.InterestOnDiscountingRentalPaymentsFinancialLease);
	ComplianceOfObjectsWithArticles.Insert(ProvisionDiscountingInterest, AssetLiabilityItems.ProvisionDiscountingInterest);
	ComplianceOfObjectsWithArticles.Insert(RentalInterest, AssetLiabilityItems.RentalInterest);
	ComplianceOfObjectsWithArticles.Insert(RevenueServicesAndAssets, AssetLiabilityItems.OtherRevenueWithVAT);
	ComplianceOfObjectsWithArticles.Insert(RevenueServicesAndAssetsExcludingVAT, AssetLiabilityItems.RevenueServicesAndAssets);
	ComplianceOfObjectsWithArticles.Insert(OtherIncome, AssetLiabilityItems.OtherIncome);
	ComplianceOfObjectsWithArticles.Insert(Expenses, AssetLiabilityItems.OtherExpenses);
	ComplianceOfObjectsWithArticles.Insert(ARAPSettlements, AssetLiabilityItems.ARAPSettlements);
	ComplianceOfObjectsWithArticles.Insert(EmployeeARAPAccounting, AssetLiabilityItems.IssuedBorrowings);
	ComplianceOfObjectsWithArticles.Insert(PayrollAccountsPayable, AssetLiabilityItems.Payroll);
	ComplianceOfObjectsWithArticles.Insert(TaxesAndContributionsAccountsPayable, AssetLiabilityItems.Taxes);
	ComplianceOfObjectsWithArticles.Insert(VATAccountsPayable, AssetLiabilityItems.VATAccountsPayable);
	ComplianceOfObjectsWithArticles.Insert(AdvanceHoldersARAPAccounting, AssetLiabilityItems.AdvanceHoldersARAPAccounting);
	ComplianceOfObjectsWithArticles.Insert(RetailCustomerAccountsReceivables, AssetLiabilityItems.RetailCustomerAccountsReceivables);
	ComplianceOfObjectsWithArticles.Insert(RevaluationReserveForIA, AssetLiabilityItems.RevaluationReserveForIA);
	ComplianceOfObjectsWithArticles.Insert(RevaluationReserveForFixedAssets, AssetLiabilityItems.RevaluationReserveForFixedAssets);
	ComplianceOfObjectsWithArticles.Insert(ProvisionsEstimatedLiabilities, AssetLiabilityItems.ProvisionsEstimatedLiabilities);
	ComplianceOfObjectsWithArticles.Insert(ProvisionsForImpairmentOfInventory, AssetLiabilityItems.ProvisionsForImpairmentOfInventory);
	ComplianceOfObjectsWithArticles.Insert(ProvisionsForImpairmentOfInventoryInShopPantry, AssetLiabilityItems.ProvisionsForImpairmentOfInventoryInShopPantry);
	ComplianceOfObjectsWithArticles.Insert(ProvisionsForImpairmentOfInventoriesTransferred, AssetLiabilityItems.ProvisionsForImpairmentOfInventoriesTransferred);
	ComplianceOfObjectsWithArticles.Insert(ProvisionsForImpairmentOfWorkInProgress, AssetLiabilityItems.ProvisionsForImpairmentOfWorkInProgress);
	ComplianceOfObjectsWithArticles.Insert(LossAllowance, AssetLiabilityItems.LossAllowance);
	ComplianceOfObjectsWithArticles.Insert(SaleCost, AssetLiabilityItems.SaleCost);
	ComplianceOfObjectsWithArticles.Insert(InternalNotOwnedValues, AssetLiabilityItems.ImproperValues);
	ComplianceOfObjectsWithArticles.Insert(IACost,AssetLiabilityItems.IACost);
	ComplianceOfObjectsWithArticles.Insert(FACost, AssetLiabilityItems.FACost);
	ComplianceOfObjectsWithArticles.Insert(LaborCostsInWorkInProgress, AssetLiabilityItems.LaborCostsInWorkInProgress);
	ComplianceOfObjectsWithArticles.Insert(RentalServices, AssetLiabilityItems.RentalServices);
	
	FinancialAccountingByFinancialRegisterDataLocalization.ToSupplementComplianceOfFinancialAccountingObjectsWithItemsOfAssetsLiabilities(ComplianceOfObjectsWithArticles);
	
	Return ComplianceOfObjectsWithArticles;
	
EndFunction

// Returns a match from the replaced and replacement financial accounting items when transferring accounting objects to asset and liability items.
// Returns:
//  Map of KeyAndValue:
//  * Key - EnumRef.DeleteFinancialAccountingObjects - the accounting object being replaced
//  * Value -  EnumRef.DeleteFinancialAccountingObjects - A Replacement Accounting Object
//
Function ReplaceableObjectsOfFinancialAccounting() Export
	
	ReplaceableAccountingObjects = New Map();
	ReplaceableAccountingObjects.Insert(ProductsReceivedForSubcontractingToWriteOff, ItemReceivedForSubcontractingAtAWarehouse);
	ReplaceableAccountingObjects.Insert(VMIToWriteOff, ItemReceivedForStorageAtAWarehouse);
	
	Return ReplaceableAccountingObjects;
	
EndFunction

// Returns the correspondence of financial accounting objects and their data sources - the names of balance Accumulation registers.
// Returns:
//  Map of KeyAndValue:
//  * Key - EnumRef.DeleteFinancialAccountingObjects
//  * Value - String - name of the Accumulation register balance sheet
//
Function DataSourcesOfFinancialAccountingObjects() Export
	
	DataSourcesOfAccountingObjects = New Map();
	AccumulationRegistersMetadata = Metadata.AccumulationRegisters;
	
	DataSourcesOfAccountingObjects.Insert(PrepaymentLeaseBuyoutValue, AccumulationRegistersMetadata.FinancialInstrumentsARAP.Name);
	DataSourcesOfAccountingObjects.Insert(PrepaymentsToVendors, AccumulationRegistersMetadata.VendorsARAPAccountingByDueDates.Name);
	DataSourcesOfAccountingObjects.Insert(PrepaymentsFromCustomers, AccumulationRegistersMetadata.CustomersARAPAccountingByDueDates.Name);
	DataSourcesOfAccountingObjects.Insert(IntangibleAssetsAmortizationCharge, AccumulationRegistersMetadata.IntangibleAssetsAmortizationCharge.Name);
	DataSourcesOfAccountingObjects.Insert(FixedAssetsDepreciationCharge, AccumulationRegistersMetadata.FixedAssetsDepreciationCharge.Name);
	DataSourcesOfAccountingObjects.Insert(LeaseObligations, AccumulationRegistersMetadata.FinancialInstrumentsARAP.Name);
	DataSourcesOfAccountingObjects.Insert(RentalPayments, AccumulationRegistersMetadata.InvestmentInRent.Name);
	DataSourcesOfAccountingObjects.Insert(TicketsAndBooking, AccumulationRegistersMetadata.VendorsARAPAccountingByDueDates.Name);
	DataSourcesOfAccountingObjects.Insert(BranchOfficeAccounting, AccumulationRegistersMetadata.OtherAssetsAndLiabilitiesRecords.Name);
	DataSourcesOfAccountingObjects.Insert(BranchOfficeAssetsAccounting, AccumulationRegistersMetadata.OtherAssetsAndLiabilitiesRecords.Name);
	DataSourcesOfAccountingObjects.Insert(IncomingVAT, AccumulationRegistersMetadata.VATInvoiced.Name);
	DataSourcesOfAccountingObjects.Insert(LeaseBuyoutValue, AccumulationRegistersMetadata.FinancialInstrumentsARAP.Name);
	DataSourcesOfAccountingObjects.Insert(ProductsRelease, AccumulationRegistersMetadata.InventoryCost.Name);
	DataSourcesOfAccountingObjects.Insert(SalesRevenue, AccumulationRegistersMetadata.RevenueAndCOGS.Name);
	DataSourcesOfAccountingObjects.Insert(SalesRevenueExcludingVAT, AccumulationRegistersMetadata.RevenueAndCOGS.Name);
	DataSourcesOfAccountingObjects.Insert(CashInCashRegisters, AccumulationRegistersMetadata.CashAccountBalance.Name);
	DataSourcesOfAccountingObjects.Insert(CashInCashRegistersCR, AccumulationRegistersMetadata.CashInCashRegistersCR.Name);
	DataSourcesOfAccountingObjects.Insert(CashInTransit, AccumulationRegistersMetadata.CashInTransit.Name);
	DataSourcesOfAccountingObjects.Insert(BankAccountBalance, AccumulationRegistersMetadata.BankAccountCash.Name);
	DataSourcesOfAccountingObjects.Insert(CustomersAccountsReceivable, AccumulationRegistersMetadata.CustomersARAPAccountingByDueDates.Name);
	DataSourcesOfAccountingObjects.Insert(VendorAccountsReceivable, AccumulationRegistersMetadata.VendorsARAPAccountingByDueDates.Name);
	DataSourcesOfAccountingObjects.Insert(ContinuingOperationIncomeClosing, AccumulationRegistersMetadata.OtherAssetsAndLiabilitiesRecords.Name);
	DataSourcesOfAccountingObjects.Insert(ContinuingOperationExpenseClosing, AccumulationRegistersMetadata.OtherAssetsAndLiabilitiesRecords.Name);
	DataSourcesOfAccountingObjects.Insert(LoansAndBorrowingsIssuedDebt, AccumulationRegistersMetadata.FinancialInstrumentsARAP.Name);
	DataSourcesOfAccountingObjects.Insert(LoansAndBorrowingsIssuedFee, AccumulationRegistersMetadata.FinancialInstrumentsARAP.Name);
	DataSourcesOfAccountingObjects.Insert(LoansAndBorrowingsIssuedInterest, AccumulationRegistersMetadata.FinancialInstrumentsARAP.Name);
	DataSourcesOfAccountingObjects.Insert(LoansAndBorrowingsReceivedDebt, AccumulationRegistersMetadata.FinancialInstrumentsARAP.Name);
	DataSourcesOfAccountingObjects.Insert(LoansAndBorrowingsReceivedFee, AccumulationRegistersMetadata.FinancialInstrumentsARAP.Name);
	DataSourcesOfAccountingObjects.Insert(LoansAndBorrowingsInterestReceived, AccumulationRegistersMetadata.FinancialInstrumentsARAP.Name);
	DataSourcesOfAccountingObjects.Insert(MaterialsAndWorksInProgress, AccumulationRegistersMetadata.InventoryCost.Name);
	DataSourcesOfAccountingObjects.Insert(VATForLease, AccumulationRegistersMetadata.FinancialInstrumentsARAP.Name);
	DataSourcesOfAccountingObjects.Insert(VATForShipmentsWithDeferredTransferOfTitle, AccumulationRegistersMetadata.OtherAssetsAndLiabilitiesRecords.Name);
	DataSourcesOfAccountingObjects.Insert(VATFromPrepaymentsToVendor, AccumulationRegistersMetadata.VATPrepaymentsToVendor.Name);
	DataSourcesOfAccountingObjects.Insert(VATFromPrepaymentsFromCustomer, AccumulationRegistersMetadata.VATPrepaymentsFromCustomer.Name);
	DataSourcesOfAccountingObjects.Insert(VATFromSales, AccumulationRegistersMetadata.RevenueAndCOGS.Name);
	DataSourcesOfAccountingObjects.Insert(VATFromOtherIncome, AccumulationRegistersMetadata.RevenueServicesAndAssets.Name);
	DataSourcesOfAccountingObjects.Insert(NonGuaranteedResidualValueFinancialLease, AccumulationRegistersMetadata.InvestmentInRent.Name);
	DataSourcesOfAccountingObjects.Insert(ItemInTransit, AccumulationRegistersMetadata.InventoryCost.Name);
	DataSourcesOfAccountingObjects.Insert(ItemsInShopStoreroom, AccumulationRegistersMetadata.InventoryCost.Name);
	DataSourcesOfAccountingObjects.Insert(InventoryItemsInStock, AccumulationRegistersMetadata.InventoryCost.Name);
	DataSourcesOfAccountingObjects.Insert(ItemShipped, AccumulationRegistersMetadata.InventoryCost.Name);
	DataSourcesOfAccountingObjects.Insert(ItemTransferredForProcessing, AccumulationRegistersMetadata.InventoryCost.Name);
	DataSourcesOfAccountingObjects.Insert(ItemsSubmittedForCommission, AccumulationRegistersMetadata.InventoryCost.Name);
	DataSourcesOfAccountingObjects.Insert(ItemHandedOverToSubConsignment, AccumulationRegistersMetadata.InventoryCost.Name);
	DataSourcesOfAccountingObjects.Insert(ItemTransferredForStorage, AccumulationRegistersMetadata.InventoryCost.Name);
	DataSourcesOfAccountingObjects.Insert(ItemReceivedForSubcontractingInProduction, AccumulationRegistersMetadata.InventoryCost.Name);
	DataSourcesOfAccountingObjects.Insert(ItemReceivedForSubcontractingInAShopFloorStockroom, AccumulationRegistersMetadata.InventoryCost.Name);
	DataSourcesOfAccountingObjects.Insert(ProductsReceivedForSubcontractingToWriteOff, AccumulationRegistersMetadata.InventoryCost.Name);
	DataSourcesOfAccountingObjects.Insert(ItemReceivedForSubcontractingAtAWarehouse, AccumulationRegistersMetadata.InventoryCost.Name);
	DataSourcesOfAccountingObjects.Insert(ProductsReceivedForSubcontractingTransferredToPartners, AccumulationRegistersMetadata.InventoryCost.Name);
	DataSourcesOfAccountingObjects.Insert(ConsignedItemReceived, AccumulationRegistersMetadata.InventoryCost.Name);
	DataSourcesOfAccountingObjects.Insert(ItemReceivedForStorageInProduction, AccumulationRegistersMetadata.InventoryCost.Name);
	DataSourcesOfAccountingObjects.Insert(ItemReceivedForStorageInAShopFloorStockroom, AccumulationRegistersMetadata.InventoryCost.Name);
	DataSourcesOfAccountingObjects.Insert(VMIToWriteOff, AccumulationRegistersMetadata.InventoryCost.Name);
	DataSourcesOfAccountingObjects.Insert(ItemReceivedForStorageAtAWarehouse, AccumulationRegistersMetadata.InventoryCost.Name);
	DataSourcesOfAccountingObjects.Insert(VMITransferredToPartners, AccumulationRegistersMetadata.InventoryCost.Name);
	DataSourcesOfAccountingObjects.Insert(SecurityPaymentForLease, AccumulationRegistersMetadata.FinancialInstrumentsARAP.Name);
	DataSourcesOfAccountingObjects.Insert(ImpairmentIA, AccumulationRegistersMetadata.ImpairmentFA.Name);
	DataSourcesOfAccountingObjects.Insert(FAImpairment, AccumulationRegistersMetadata.ImpairmentFA.Name);
	DataSourcesOfAccountingObjects.Insert(ObligationsToProcurementCommittee, AccumulationRegistersMetadata.GoodsAndServicesToRegisterPurchasingReportsToConsignor.Name);
	DataSourcesOfAccountingObjects.Insert(ObligationsToCommiteeForGoodsSold, AccumulationRegistersMetadata.GoodsToBeRegisteredInReportsToConsignor.Name);
	DataSourcesOfAccountingObjects.Insert(ObligationsToPrincipalForServicesProvided, AccumulationRegistersMetadata.ServicesForRegistrationOfReportsToPrincipal.Name);
	DataSourcesOfAccountingObjects.Insert(LiabilitiesForGoodsReceivedNotInvoiced, AccumulationRegistersMetadata.InventoryCost.Name);
	DataSourcesOfAccountingObjects.Insert(ItemCostVariances, AccumulationRegistersMetadata.GoodsCostVariances.Name);
	DataSourcesOfAccountingObjects.Insert(TransferredReturnablePackaging, AccumulationRegistersMetadata.TransferredReturnablePackaging.Name);
	DataSourcesOfAccountingObjects.Insert(FixedAssetsProvided, AccumulationRegistersMetadata.OtherAssetsAndLiabilitiesRecords.Name);
	DataSourcesOfAccountingObjects.Insert(GiftCertificates, AccumulationRegistersMetadata.GiftCertificates.Name);
	DataSourcesOfAccountingObjects.Insert(ItemizedCostsInWorkInProgress, AccumulationRegistersMetadata.OtherWorkInProgressExpenses.Name);
	DataSourcesOfAccountingObjects.Insert(ReceivedReturnablePackaging, AccumulationRegistersMetadata.ReceivedReturnablePackaging.Name);
	DataSourcesOfAccountingObjects.Insert(DiscountInterestExpense, AccumulationRegistersMetadata.DiscountInterestExpense.Name);
	DataSourcesOfAccountingObjects.Insert(InterestOnDiscountingRentalPaymentsFinancialLease, AccumulationRegistersMetadata.InvestmentInRent.Name);
	DataSourcesOfAccountingObjects.Insert(ProvisionDiscountingInterest, AccumulationRegistersMetadata.FutureExpenseCommitments.Name);
	DataSourcesOfAccountingObjects.Insert(RentalInterest, AccumulationRegistersMetadata.FinancialInstrumentsARAP.Name);
	DataSourcesOfAccountingObjects.Insert(RevenueServicesAndAssets, AccumulationRegistersMetadata.RevenueServicesAndAssets.Name);
	DataSourcesOfAccountingObjects.Insert(RevenueServicesAndAssetsExcludingVAT, AccumulationRegistersMetadata.RevenueServicesAndAssets.Name);
	DataSourcesOfAccountingObjects.Insert(OtherAssetsLiabilities, AccumulationRegistersMetadata.OtherAssetsAndLiabilitiesRecords.Name);
	DataSourcesOfAccountingObjects.Insert(OtherIncome, AccumulationRegistersMetadata.OtherIncome.Name);
	DataSourcesOfAccountingObjects.Insert(Expenses, AccumulationRegistersMetadata.OtherExpenses.Name);
	DataSourcesOfAccountingObjects.Insert(EmployeeARAPAccounting, AccumulationRegistersMetadata.OtherAssetsAndLiabilitiesRecords.Name);
	DataSourcesOfAccountingObjects.Insert(PayrollAccountsPayable, AccumulationRegistersMetadata.OtherAssetsAndLiabilitiesRecords.Name);
	DataSourcesOfAccountingObjects.Insert(TaxesAndContributionsAccountsPayable, AccumulationRegistersMetadata.OtherAssetsAndLiabilitiesRecords.Name);
	DataSourcesOfAccountingObjects.Insert(VATAccountsPayable, AccumulationRegistersMetadata.VATRegisterRecords.Name);
	DataSourcesOfAccountingObjects.Insert(AdvanceHoldersARAPAccounting, AccumulationRegistersMetadata.AdvanceHolderCash.Name);
	DataSourcesOfAccountingObjects.Insert(RevaluationReserveForIA, AccumulationRegistersMetadata.IACost.Name);
	DataSourcesOfAccountingObjects.Insert(RevaluationReserveForFixedAssets, AccumulationRegistersMetadata.FACost.Name);
	DataSourcesOfAccountingObjects.Insert(ProvisionsEstimatedLiabilities, AccumulationRegistersMetadata.FutureExpenseCommitments.Name);
	DataSourcesOfAccountingObjects.Insert(ProvisionsForImpairmentOfInventory, AccumulationRegistersMetadata.InventoryCost.Name);
	DataSourcesOfAccountingObjects.Insert(ProvisionsForImpairmentOfInventoryInShopPantry, AccumulationRegistersMetadata.InventoryCost.Name);
	DataSourcesOfAccountingObjects.Insert(ProvisionsForImpairmentOfInventoriesTransferred, AccumulationRegistersMetadata.InventoryCost.Name);
	DataSourcesOfAccountingObjects.Insert(ProvisionsForImpairmentOfWorkInProgress, AccumulationRegistersMetadata.InventoryCost.Name);
	DataSourcesOfAccountingObjects.Insert(LossAllowance, AccumulationRegistersMetadata.LossAllowance.Name);
	DataSourcesOfAccountingObjects.Insert(SaleCost, AccumulationRegistersMetadata.RevenueAndCOGS.Name);
	DataSourcesOfAccountingObjects.Insert(IACost, AccumulationRegistersMetadata.IACost.Name);
	DataSourcesOfAccountingObjects.Insert(FACost, AccumulationRegistersMetadata.FACost.Name);
	DataSourcesOfAccountingObjects.Insert(LaborCostsInWorkInProgress, AccumulationRegistersMetadata.WIPLaborCosts.Name);
	DataSourcesOfAccountingObjects.Insert(RentalServices, AccumulationRegistersMetadata.FinancialInstrumentsARAP.Name);
	
	FinancialAccountingByFinancialRegisterDataLocalization.SupplementDataSourcesOfFinancialAccountingObjects(DataSourcesOfAccountingObjects);
	
	Return DataSourcesOfAccountingObjects;
	
EndFunction

// Returns a table describing financial accounting objects.
// If any parameter is an expression of the query language, then the field descriptions in it must contain
// the alias of the data source obtained through the function of the financial accounting data of the balance registers.The Data source aliasing is silent().
// If the parameter is only a field name, including the one separated by a dot, it can be specified without an alias of the data source.
// It is allowed to use request parameters from the function of the International accounting data of financial registers.Financial Register data requests().
// It is allowed to use string templates from the International Financial Register Data collection function.Request textsrecording registers().
// 
// Parameters:
//  TransactionSettings - See Catalogs.FinancialAccountingPostingGenerationSetting.TransactionGenerationSettings
// 
// Returns:
//  ValueTable - Description Of Columns:
//  * AccountingObject - EnumRef.DeleteFinancialAccountingObjects - Reference of the financial accounting object
//  * FunctionalOptions - String, Array, ValueList - names of functional options that control accounting for the fin object.accounting. The values in the List are multiplied by "AND", in the Array they are added by "OR"
//  * DataSource - String - The name of the Accumulation register that keeps records of the fin object.accounting
//  * Filterdata_ - Map, Array - Selecting register data for the fin object.accounting. The selection conditions in accordance with are multiplied by "AND", in the Array are added by "OR"
//  * DebitCondition - String - A condition in the query language for determining the debit RegisteredRecords attribute. It is indicated in case of differences from the rules for attributing Registered Recorded movements in the register or their absence.
//  * ConditionCredit - String - A condition in the query language for determining the credit RegisteredRecorded attribute. It is indicated in case of differences from the rules for attributing Registered Recorded movements in the register or their absence.
//  * DataPathConfigurationObject - String - The path of selecting the register data corresponding to the settings objects, in the context of which the accounting accounts are specified. Specified in case of a difference from the same parameter of the accumulation register
//  * PathToDataLineOfBusiness - String - The path of fetching the activity direction value from the register data. Specified in case of a difference from the same parameter of the accumulation register
//  * DataPathRecordFinID - String - The path of fetching the value of the register record ID. Specified in case of a difference from the same parameter of the accumulation register
//  * DataPathSettingUpHouseholdOperations - String - The path of selecting the value of the business operation setting. Specified in case of difference from the same parameter of the accumulation register
//  * DataPathRowId - String - The path of selecting the value of the register string ID. Specified in case of a difference from the same parameter of the accumulation register
//  * PathsToExtdimensionData - Map of KeyAndValue - Refinement of sub-konto sampling paths. Specified in the case of an incorrect result of selecting the value of the sub-konto from the sources of the sub-konto register
//  	* Key - ChartOfCharacteristicTypesRef.FinancialExtraDimensionTypes - Extra dimension type
//  	* Value - String - The path of selecting the subconto value
//  * ManResources - Array - An array of rows with the names of resources that store the transaction amount in the management accounting currency. Specified in case of a difference from the same parameter of the accumulation register
//  * LocalResources - Array - An array of rows with the names of resources that store the transaction amount in the currency of regulated accounting. Specified in case of a difference from the same parameter of the accumulation register
//  * ShaftResources - Array - An array of strings with the names of resources that store the currency amount of the operation. Specified in case of a difference from the same parameter of the accumulation register
//  * ResourcesQuantity - Array - An array of strings with resource names that store the operation count. Specified in case of a difference from the same parameter of the accumulation register
//  * CorDataSources - Array - An array of rows with the names of the accumulation registers in which the corresponding accounting objects are recorded. Used for the Revenue register.
//  * AllocationOfLongTermAssetsAndLiabilities - Boolean - The data of the accounting object is divided into short-term and long-term, the attribute is translated from the data source.
//  * ImproperValues - Boolean - A sign of accounting for improper controlled values in an object
//  * VATAccounting - Boolean - Indicates whether VAT amounts are included in the item
//  * AccountingWithVAT - Boolean - Whether the amount including VAT is included in the item
//  * SignsOfCorrespondenceAccounting - ValueTable - Description of correspondence of the Cur object of the fin.accounting with other objects that are possible if certain conditions are met.
//  	* AccountingObject - EnumRef.DeleteFinancialAccountingObjects - Corresponding object of financial accounting
//  	* AccountingFlag - String - Name of the accounting feature that manages the correspondence of fin objects.accounting
//  	* Value - Boolean - The value of the accounting attribute that allows correspondence of FIN objects.accounting
// 
Function DescriptionOfFinancialAccountingObjects(TransactionSettings = Undefined) Export
	
	If TransactionSettings = Undefined Then
		TransactionSettings = Catalogs.FinancialAccountingPostingGenerationSetting.TransactionGenerationSettings();
	EndIf;
	
	FinancialAccountingObjects = New ValueTable();
	FinancialAccountingObjects.Columns.Add("AccountingObject", New TypeDescription("EnumRef.DeleteFinancialAccountingObjects"));
	FinancialAccountingObjects.Columns.Add("FunctionalOptions", New TypeDescription(Common.StringTypeDetails(150), "Array,ValueList"));
	FinancialAccountingObjects.Columns.Add("DataSource", Common.StringTypeDetails(150));
	FinancialAccountingObjects.Columns.Add("Filterdata_", New TypeDescription("Map,Array"));
	FinancialAccountingObjects.Columns.Add("DebitCondition", Common.StringTypeDetails(1000));
	FinancialAccountingObjects.Columns.Add("ConditionCredit", Common.StringTypeDetails(1000));
	FinancialAccountingObjects.Columns.Add("DataPathConfigurationObject", Common.StringTypeDetails(1000));
	FinancialAccountingObjects.Columns.Add("PathToDataLineOfBusiness", Common.StringTypeDetails(1000));
	FinancialAccountingObjects.Columns.Add("DataPathRecordFinID", Common.StringTypeDetails(1000));
	FinancialAccountingObjects.Columns.Add("DataPathSettingUpHouseholdOperations", Common.StringTypeDetails(1000));
	FinancialAccountingObjects.Columns.Add("DataPathRowId", Common.StringTypeDetails(1000));
	FinancialAccountingObjects.Columns.Add("PathsToExtdimensionData", New TypeDescription("Map"));
	FinancialAccountingObjects.Columns.Add("ManResources", New TypeDescription("Array"));
	FinancialAccountingObjects.Columns.Add("LocalResources", New TypeDescription("Array"));
	FinancialAccountingObjects.Columns.Add("ShaftResources", New TypeDescription("Array"));
	FinancialAccountingObjects.Columns.Add("ResourcesQuantity", New TypeDescription("Array"));
	FinancialAccountingObjects.Columns.Add("CorDataSources", New TypeDescription("Array"));
	FinancialAccountingObjects.Columns.Add("AllocationOfLongTermAssetsAndLiabilities", New TypeDescription("Boolean"));
	FinancialAccountingObjects.Columns.Add("ImproperValues", New TypeDescription("Boolean"));
	FinancialAccountingObjects.Columns.Add("VATAccounting", New TypeDescription("Boolean"));
	FinancialAccountingObjects.Columns.Add("AccountingWithVAT", New TypeDescription("Boolean"));
	FinancialAccountingObjects.Columns.Add("SignsOfCorrespondenceAccounting", New TypeDescription("ValueTable"));
	
	FillInAccountingItemsCash(FinancialAccountingObjects, TransactionSettings);
	FillInAccountingItemsProducts(FinancialAccountingObjects, TransactionSettings);
	FillInAccountingItemsFixedAssets(FinancialAccountingObjects, TransactionSettings);
	FillInAccountingItemsIntangibleAssets(FinancialAccountingObjects, TransactionSettings);
	FillInAccountingObjectsSettlementsWithCustomers(FinancialAccountingObjects, TransactionSettings);
	FillInAccountingItemsSettlementsWithSuppliers(FinancialAccountingObjects, TransactionSettings);
	FillInAccountingItemsLoansAndBorrowingsIssued(FinancialAccountingObjects, TransactionSettings);
	FillInAccountingItemsLoansAndBorrowingsReceived(FinancialAccountingObjects, TransactionSettings);
	FillInAccountingItemsSettlementsWithEmployees(FinancialAccountingObjects, TransactionSettings);
	FillInAccountingItemsExpenseLease(FinancialAccountingObjects, TransactionSettings);
	FillInAccountingItemsProfitableLease(FinancialAccountingObjects, TransactionSettings);
	FillInAccountingItemsWorkInProgress(FinancialAccountingObjects, TransactionSettings);
	FillInAccountingItemsIncomeAndExpenses(FinancialAccountingObjects, TransactionSettings);
	FillInVATObjects(FinancialAccountingObjects, TransactionSettings);
	OtherAccountingItemsProvisionsForImpairment(FinancialAccountingObjects, TransactionSettings);
	FillInAccountingObjectsLossesAllowanceForDoubtfulDebts(FinancialAccountingObjects, TransactionSettings);
	FillInAccountingObjectsProvisionsAndContingentLiabilities(FinancialAccountingObjects, TransactionSettings);
	OtherAccountingItemsOtherAssetsAndLiabilities(FinancialAccountingObjects, TransactionSettings);
	
	FinancialAccountingByFinancialRegisterDataLocalization.AddDescriptionOfFinancialAccountingObjects(FinancialAccountingObjects, TransactionSettings);
	
	FillInDataSourcesOfAccountingObjects(FinancialAccountingObjects);
	
	If TransactionSettings.AllocationOfLongTermAssetsAndLiabilities = True
	 Or TransactionSettings.AllocationOfLongTermAssetsAndLiabilities = Undefined Then
		CompleteAllocationOfNonCurrentAssetsLiabilities(FinancialAccountingObjects);
	EndIf;
	
	FinancialAccountingObjects.Indexes.Add("DataSource");
	FinancialAccountingObjects.Indexes.Add("AccountingObject");
	
	Return FinancialAccountingObjects;
	
EndFunction

// Returns the structure of the description of the financial accounting object.
// 
// Returns:
// 	Structure - LongDesc:
//  * AccountingObject - EnumRef.DeleteFinancialAccountingObjects - Reference of the financial accounting object
//  * FunctionalOptions - String, Array, ValueList - names of functional options that control accounting for the fin object.accounting. The values in the List are multiplied by "AND", in the Array they are added by "OR"
//  * DataSource - String - The name of the Accumulation register that keeps records of the fin object.accounting
//  * Filterdata_ - Map, Array - Selecting register data for the fin object.accounting. The selection conditions in accordance with are multiplied by "AND", in the Array are added by "OR"
//  * DebitCondition - String - A condition in the query language for determining the debit RegisteredRecords attribute. It is indicated in case of differences from the rules for attributing Registered Recorded movements in the register or their absence.
//  * ConditionCredit - String - A condition in the query language for determining the credit RegisteredRecorded attribute. It is indicated in case of differences from the rules for attributing Registered Recorded movements in the register or their absence.
//  * DataPathConfigurationObject - String - The path of selecting the register data corresponding to the settings objects, in the context of which the accounting accounts are specified. Specified in case of a difference from the same parameter of the accumulation register
//  * PathToDataLineOfBusiness - String - The path of fetching the activity direction value from the register data. Specified in case of a difference from the same parameter of the accumulation register
//  * DataPathRecordFinID - String - The path of fetching the value of the register record ID. Specified in case of a difference from the same parameter of the accumulation register
//  * DataPathSettingUpHouseholdOperations - String - The path of selecting the value of the business operation setting. Specified in case of difference from the same parameter of the accumulation register
//  * DataPathRowId - String - The path of selecting the value of the register string ID. Specified in case of a difference from the same parameter of the accumulation register
//  * PathsToExtdimensionData - Map of KeyAndValue - Refinement of sub-konto sampling paths. Specified in the case of an incorrect result of selecting the value of the sub-konto from the sources of the sub-konto register
//  	* Key - ChartOfCharacteristicTypesRef.FinancialExtraDimensionTypes - Extra dimension type
//  	* Value - String - The path of selecting the subconto value
//  * ManResources - Array - An array of rows with the names of resources that store the transaction amount in the management accounting currency. Specified in case of a difference from the same parameter of the accumulation register
//  * LocalResources - Array - An array of rows with the names of resources that store the transaction amount in the currency of regulated accounting. Specified in case of a difference from the same parameter of the accumulation register
//  * ShaftResources - Array - An array of strings with the names of resources that store the currency amount of the operation. Specified in case of a difference from the same parameter of the accumulation register
//  * ResourcesQuantity - Array - An array of strings with resource names that store the operation count. Specified in case of a difference from the same parameter of the accumulation register
//  * CorDataSources - Array - An array of rows with the names of the accumulation registers in which the corresponding accounting objects are recorded. Used for the Revenue register.
//  * AllocationOfLongTermAssetsAndLiabilities - Boolean - The data of the accounting object is divided into short-term and long-term, the attribute is translated from the data source.
//  * ImproperValues - Boolean - A sign of accounting for improper controlled values in an object
//  * VATAccounting - Boolean - Indicates whether VAT amounts are included in the item
//  * AccountingWithVAT - Boolean - Whether the amount including VAT is included in the item
//  * SignsOfCorrespondenceAccounting - ValueTable - Description of correspondence of the Cur object of the fin.accounting with other objects that are possible if certain conditions are met.
//  	* AccountingObject - EnumRef.DeleteFinancialAccountingObjects - Corresponding object of financial accounting
//  	* AccountingFlag - String - Name of the accounting feature that manages the correspondence of fin objects.accounting
//  	* Value - Boolean - The value of the accounting attribute that allows correspondence of FIN objects.accounting
// 
Function DescriptionOfFinancialAccountingObject(AccountingObject, ExtendedDescription = False) Export
	
	If Not ValueIsFilled(AccountingObject) Then
		Return Undefined;
	EndIf;
	
	If ExtendedDescription Then
		DescriptionOfAccountingObjects = ExtendedDescriptionOfAccountingObjectsToConfigure();
	Else
		DescriptionOfAccountingObjects = DescriptionOfFinancialAccountingObjects();
	EndIf;
	
	Result = New Structure;
	For Each Column In DescriptionOfAccountingObjects.Columns Do
		If Not Column.ValueType.ContainsType(Type("ValueTable")) Then
			Result.Insert(Column.Name);
		EndIf;
	EndDo;
	
	DescriptionOfTheAccountingObject = DescriptionOfAccountingObjects.Find(AccountingObject, "AccountingObject");
	
	If DescriptionOfTheAccountingObject = Undefined And ExtendedDescription Then
		DescriptionOfAccountingObjects = DescriptionOfFinancialAccountingObjects();
		AddColumnsForExtendedDescriptionOfAccountingItems(DescriptionOfAccountingObjects);
		DescriptionOfTheAccountingObject = DescriptionOfAccountingObjects.Find(AccountingObject, "AccountingObject");
	EndIf;
	
	If DescriptionOfTheAccountingObject = Undefined Then
		Raise StrTemplate(NStr("vi = 'Không có mô tả về đối tượng kế toán ""%1""';
								|ru = 'Отсутствует описание объекта учета ""%1""';
								|en = 'No details for the ""%1"" accounting object'; fa = 'No details for the ""%1"" accounting object';
								|it = 'Отсутствует описание объекта учета ""%1""';
								|pl = 'Brak opisu obiektu ewidencji ""%1""';
								|tr = '""%1"" muhasebe nesnesi ayrıntıları bulunmuyor'"), AccountingObject);
	EndIf;
	
	FillPropertyValues(Result, DescriptionOfTheAccountingObject);
	
	Return Result;
	
EndFunction

// Returns an extended table describing financial accounting objects. The table contains a description of the grouping of accounting objects, types of configuration objects, and so on.
// 
// Parameters:
//  TransactionSettings - See Catalogs.FinancialAccountingPostingGenerationSetting.TransactionGenerationSettings
// 
// Returns:
// 	Structure - LongDesc:
//  * AccountingObject - EnumRef.DeleteFinancialAccountingObjects - Reference of the financial accounting object
//  * FunctionalOptions - String, Array, ValueList - names of functional options that control accounting for the fin object.accounting. The values in the List are multiplied by "AND", in the Array they are added by "OR"
//  * DataSource - String - The name of the Accumulation register that keeps records of the fin object.accounting
//  * Filterdata_ - Map, Array - Selecting register data for the fin object.accounting. The selection conditions in accordance with are multiplied by "AND", in the Array are added by "OR"
//  * DebitCondition - String - A condition in the query language for determining the debit RegisteredRecords attribute. It is indicated in case of differences from the rules for attributing Registered Recorded movements in the register or their absence.
//  * ConditionCredit - String - A condition in the query language for determining the credit RegisteredRecorded attribute. It is indicated in case of differences from the rules for attributing Registered Recorded movements in the register or their absence.
//  * DataPathConfigurationObject - String - The path of selecting the register data corresponding to the settings objects, in the context of which the accounting accounts are specified. Specified in case of a difference from the same parameter of the accumulation register
//  * PathToDataLineOfBusiness - String - The path of fetching the activity direction value from the register data. Specified in case of a difference from the same parameter of the accumulation register
//  * DataPathRecordFinID - String - The path of fetching the value of the register record ID. Specified in case of a difference from the same parameter of the accumulation register
//  * DataPathSettingUpHouseholdOperations - String - The path of selecting the value of the business operation setting. Specified in case of difference from the same parameter of the accumulation register
//  * DataPathRowId - String - The path of selecting the value of the register string ID. Specified in case of a difference from the same parameter of the accumulation register
//  * PathsToExtdimensionData - Map of KeyAndValue - Refinement of sub-konto sampling paths. Specified in the case of an incorrect result of selecting the value of the sub-konto from the sources of the sub-konto register
//  	* Key - ChartOfCharacteristicTypesRef.FinancialExtraDimensionTypes - Extra dimension type
//  	* Value - String - The path of selecting the subconto value
//  * ManResources - Array - An array of rows with the names of resources that store the transaction amount in the management accounting currency. Specified in case of a difference from the same parameter of the accumulation register
//  * LocalResources - Array - An array of rows with the names of resources that store the transaction amount in the currency of regulated accounting. Specified in case of a difference from the same parameter of the accumulation register
//  * ShaftResources - Array - An array of strings with the names of resources that store the currency amount of the operation. Specified in case of a difference from the same parameter of the accumulation register
//  * ResourcesQuantity - Array - An array of strings with resource names that store the operation count. Specified in case of a difference from the same parameter of the accumulation register
//  * CorDataSources - Array - An array of rows with the names of the accumulation registers in which the corresponding accounting objects are recorded. Used for the Revenue register.
//  * AllocationOfLongTermAssetsAndLiabilities - Boolean - The data of the accounting object is divided into short-term and long-term, the attribute is translated from the data source.
//  * ImproperValues - Boolean - A sign of accounting for improper controlled values in an object
//  * VATAccounting - Boolean - Indicates whether VAT amounts are included in the item
//  * AccountingWithVAT - Boolean - Whether the amount including VAT is included in the item
//  * SignsOfCorrespondenceAccounting - ValueTable - Description of correspondence of the Cur object of the fin.accounting with other objects that are possible if certain conditions are met.
//  	* AccountingObject - EnumRef.DeleteFinancialAccountingObjects - Corresponding object of financial accounting
//  	* AccountingFlag - String - Name of the accounting feature that manages the correspondence of fin objects.accounting
//  	* Value - Boolean - The value of the accounting attribute that allows correspondence of FIN objects.accounting
//  * Group - String - Group of accounting objects
//  * Presentation - String - Representation of an object when displayed in a group
//  * DescriptionOfTheConfigurationObjectTypes - TypeDescription - Description of the types of the configuration object. If only a general setting, then the description does not contain types.
//  * SelectingConfigurationObjects - Structure, Array - Selection of configuration objects. In the case of an array, the conditions are added by "OR":
//  	* Key - String - Name of the selection item
//  	* Value - Arbitrary - Selection value
//  * DescriptionOfTheAccountingLocationTypes - TypeDescription - Description of the accounting location types for the exception setting. If the setting of exceptions for accounting locations is not provided, then the description does not contain types.
//  * TitleOfTheInvoiceSetupTable - String - Title of the invoice setup table by accounting object
Function ExtendedDescriptionOfAccountingObjectsToConfigure(TransactionSettings = Undefined) Export
	
	If TransactionSettings = Undefined Then
		TransactionSettings = Catalogs.FinancialAccountingPostingGenerationSetting.TransactionGenerationSettings();
	EndIf;
	
	FinancialAccountingObjects = DescriptionOfFinancialAccountingObjects(TransactionSettings);
	AddColumnsForExtendedDescriptionOfAccountingItems(FinancialAccountingObjects);
	
	GroupsOfAccountingObjects = GroupsOfAccountingObjects(TransactionSettings);
	DescriptionOfAccountingObjectsForConfiguringForms = New Map();
	
	#Region DescriptionOfAccountingObjects
	
	#Region Cash
	
	BankingDetailsNameTypeOfFunds = Metadata.Catalogs.GroupsOfFinancialAccountingOfCash.Attributes.CashType.Name;
	
	DescriptionOfAccountingObject_ = DescriptionOfAccountingObjectForConfiguringForms();
	DescriptionOfAccountingObject_.Group = GroupsOfAccountingObjects.RoadsideFunds;
	DescriptionOfAccountingObject_.Presentation = NStr("vi = 'Trong quỹ tiền mặt của công ty';
														|ru = 'В кассах предприятия';
														|en = 'On the cash accounts'; fa = 'On the cash accounts';
														|it = 'В кассах предприятия';
														|pl = 'W kasach przedzsiębiorstwa';
														|tr = 'İşletme kasalarında'");
	DescriptionOfAccountingObject_.TitleOfTheInvoiceSetupTable = NStr("vi = 'Tài khoản tiền mặt trong quỹ của công ty';
																		|ru = 'Счета учета денежных средств в кассах предприятия';
																		|en = 'Ledger account of cash in cash accounts'; fa = 'Ledger account of cash in cash accounts';
																		|it = 'Счета учета денежных средств в кассах предприятия';
																		|pl = 'Konta księgowe środków w kasach firmy';
																		|tr = 'İş yeri kasalarında kasa ve banka hesapları'");
	DescriptionOfAccountingObject_.DescriptionOfTheConfigurationObjectTypes = New TypeDescription("CatalogRef.GroupsOfFinancialAccountingOfCash");
	DescriptionOfAccountingObject_.SelectingConfigurationObjects = New Structure(BankingDetailsNameTypeOfFunds, Enums.CashTypes.CashPayment);
	DescriptionOfAccountingObject_.DescriptionOfTheAccountingLocationTypes = New TypeDescription();
	DescriptionOfAccountingObjectsForConfiguringForms.Insert(Enums.DeleteFinancialAccountingObjects.CashInCashRegisters, DescriptionOfAccountingObject_);
	
	DescriptionOfAccountingObject_ = DescriptionOfAccountingObjectForConfiguringForms();
	DescriptionOfAccountingObject_.Group = GroupsOfAccountingObjects.RoadsideFunds;
	DescriptionOfAccountingObject_.Presentation = NStr("vi = 'Trong quầy thu ngân';
														|ru = 'В кассах ККМ';
														|en = 'In cash registers'; fa = 'در صندوق‌های فروش';
														|it = 'В кассах ККМ';
														|pl = 'W kasach KKM';
														|tr = 'Yazar kasalarda'");
	DescriptionOfAccountingObject_.TitleOfTheInvoiceSetupTable = NStr("vi = 'Tài khoản tiền mặt bán lẻ';
																		|ru = 'Счета учета денежных средств в рознице';
																		|en = 'Ledger account of retail cash'; fa = 'Ledger account of retail cash';
																		|it = 'Счета учета денежных средств в рознице';
																		|pl = 'Konta księgowe środków pieniężnych w detalu';
																		|tr = 'Perakendede kasa ve banka hesapları'");
	DescriptionOfAccountingObject_.DescriptionOfTheConfigurationObjectTypes = New TypeDescription("CatalogRef.GroupsOfFinancialAccountingOfCash");
	DescriptionOfAccountingObject_.SelectingConfigurationObjects = New Structure(BankingDetailsNameTypeOfFunds, Enums.CashTypes.InCashRegisters);
	DescriptionOfAccountingObject_.DescriptionOfTheAccountingLocationTypes = New TypeDescription();
	DescriptionOfAccountingObjectsForConfiguringForms.Insert(Enums.DeleteFinancialAccountingObjects.CashInCashRegistersCR, DescriptionOfAccountingObject_);
	
	DescriptionOfAccountingObject_ = DescriptionOfAccountingObjectForConfiguringForms();
	DescriptionOfAccountingObject_.Group = GroupsOfAccountingObjects.RoadsideFunds;
	DescriptionOfAccountingObject_.Presentation = NStr("vi = 'Trong tài khoản ngân hàng';
														|ru = 'На банковских счетах';
														|en = 'On bank accounts'; fa = 'در حساب‌های بانکی';
														|it = 'На банковских счетах';
														|pl = 'Na kontach bankowych';
														|tr = 'Banka hesaplarında'");
	DescriptionOfAccountingObject_.TitleOfTheInvoiceSetupTable = NStr("vi = 'Tài khoản hạch toán tiền trong tài khoản ngân hàng';
																		|ru = 'Счета учета денежных средств на банковских счетах';
																		|en = 'Ledger accounts of cash in bank accounts'; fa = 'Ledger accounts of cash in bank accounts';
																		|it = 'Счета учета денежных средств на банковских счетах';
																		|pl = 'Konta księgowe środków pieniężnych na rachunkach bankowych';
																		|tr = 'Banka hesaplarında kasa ve banka hesapları'");
	DescriptionOfAccountingObject_.DescriptionOfTheConfigurationObjectTypes = New TypeDescription("CatalogRef.GroupsOfFinancialAccountingOfCash");
	DescriptionOfAccountingObject_.SelectingConfigurationObjects = New Structure(BankingDetailsNameTypeOfFunds, Enums.CashTypes.BankAccountPayments_);
	DescriptionOfAccountingObject_.DescriptionOfTheAccountingLocationTypes = New TypeDescription();
	DescriptionOfAccountingObjectsForConfiguringForms.Insert(Enums.DeleteFinancialAccountingObjects.BankAccountBalance, DescriptionOfAccountingObject_);
	
	DescriptionOfAccountingObject_ = DescriptionOfAccountingObjectForConfiguringForms();
	DescriptionOfAccountingObject_.Group = GroupsOfAccountingObjects.RoadsideFunds;
	DescriptionOfAccountingObject_.Presentation = NStr("vi = 'Đang chuyển';
														|ru = 'В пути';
														|en = 'In transit'; fa = 'در راه';
														|it = 'В пути';
														|pl = 'W drodze';
														|tr = 'Nakil halinde'");
	DescriptionOfAccountingObject_.TitleOfTheInvoiceSetupTable = NStr("vi = 'Tài khoản kế toán tiền đang chuyển';
																		|ru = 'Счета учета денежных средств в пути';
																		|en = 'Cash-in-transit ledger accounts'; fa = 'Cash-in-transit ledger accounts';
																		|it = 'Счета учета денежных средств в пути';
																		|pl = 'Konta księgowe środków pieniężnych w drodze';
																		|tr = 'Nakil halindeki kasa ve banka hesapları'");
	DescriptionOfAccountingObject_.DescriptionOfTheConfigurationObjectTypes = New TypeDescription("EnumRef.CashTransferKinds");
	DescriptionOfAccountingObject_.DescriptionOfTheAccountingLocationTypes = New TypeDescription();
	DescriptionOfAccountingObjectsForConfiguringForms.Insert(Enums.DeleteFinancialAccountingObjects.CashInTransit, DescriptionOfAccountingObject_);
	
	#EndRegion
	
	#Region Products
	
	DescriptionOfAccountingObject_ = DescriptionOfAccountingObjectForConfiguringForms();
	DescriptionOfAccountingObject_.Group = GroupsOfAccountingObjects.Products;
	DescriptionOfAccountingObject_.Presentation = NStr("vi = 'Xuất xưởng thành phẩm';
														|ru = 'Выпуск продукции';
														|en = 'Product release'; fa = 'تولید محصول';
														|it = 'Emissione di prodotti';
														|pl = 'Wyprodukowanie';
														|tr = 'Ürün sürümü'");
	DescriptionOfAccountingObject_.TitleOfTheInvoiceSetupTable = NStr("vi = 'Tài khoản chi phí xuất xưởng thành phẩm';
																		|ru = 'Счета учета выпуска продукции';
																		|en = 'Product release ledger accounts'; fa = 'Product release ledger accounts';
																		|it = 'Product release ledger accounts';
																		|pl = 'Product release ledger accounts';
																		|tr = 'İmal edilen ürün çıkışının defterikebir hesabı'");
	DescriptionOfAccountingObject_.DescriptionOfTheConfigurationObjectTypes = New TypeDescription("CatalogRef.InventoryAccountingGroups");
	DescriptionOfAccountingObject_.DescriptionOfTheAccountingLocationTypes = New TypeDescription("CatalogRef.Warehouses");
	DescriptionOfAccountingObjectsForConfiguringForms.Insert(Enums.DeleteFinancialAccountingObjects.ProductsRelease, DescriptionOfAccountingObject_);
	
	DescriptionOfAccountingObject_ = DescriptionOfAccountingObjectForConfiguringForms();
	DescriptionOfAccountingObject_.Group = GroupsOfAccountingObjects.Products;
	DescriptionOfAccountingObject_.Presentation = NStr("vi = 'Trong kho';
														|ru = 'На складе';
														|en = 'In warehouse'; fa = 'در انبار';
														|it = 'На складе';
														|pl = 'W magazynie';
														|tr = 'Ambarda'");
	DescriptionOfAccountingObject_.TitleOfTheInvoiceSetupTable = NStr("vi = 'Tài khoản hạch toán hàng hóa trong kho';
																		|ru = 'Счета учета товаров на складах';
																		|en = 'Ledger accounts of goods in warehouses'; fa = 'Ledger accounts of goods in warehouses';
																		|it = 'Счета учета товаров на складах';
																		|pl = 'Konta księgowe towarów w magazynach';
																		|tr = 'Ambardaki ürünlerin defterikebir hesabı'");
	DescriptionOfAccountingObject_.DescriptionOfTheConfigurationObjectTypes = New TypeDescription("CatalogRef.InventoryAccountingGroups");
	DescriptionOfAccountingObject_.DescriptionOfTheAccountingLocationTypes = New TypeDescription("CatalogRef.Warehouses");
	DescriptionOfAccountingObjectsForConfiguringForms.Insert(Enums.DeleteFinancialAccountingObjects.InventoryItemsInStock, DescriptionOfAccountingObject_);

	DescriptionOfAccountingObject_ = DescriptionOfAccountingObjectForConfiguringForms();
	DescriptionOfAccountingObject_.Group = GroupsOfAccountingObjects.Products;
	DescriptionOfAccountingObject_.Presentation = NStr("vi = 'Đang chuyển';
														|ru = 'В пути';
														|en = 'In transit'; fa = 'در راه';
														|it = 'В пути';
														|pl = 'W drodze';
														|tr = 'Nakil halinde'");
	DescriptionOfAccountingObject_.TitleOfTheInvoiceSetupTable = NStr("vi = 'Tài khoản hạch toán hàng hóa riêng đi đường';
																		|ru = 'Счета учета собственных товаров в пути';
																		|en = 'Ledger accounts of own goods in transit'; fa = 'Ledger accounts of own goods in transit';
																		|it = 'Счета учета собственных товаров в пути';
																		|pl = 'Konta księgowe towarów własnych w drodze';
																		|tr = 'Transit malların defterikebir hesabı'");
	DescriptionOfAccountingObject_.DescriptionOfTheConfigurationObjectTypes = New TypeDescription("CatalogRef.InventoryAccountingGroups");
	DescriptionOfAccountingObject_.DescriptionOfTheAccountingLocationTypes = New TypeDescription();
	DescriptionOfAccountingObjectsForConfiguringForms.Insert(Enums.DeleteFinancialAccountingObjects.ItemInTransit, DescriptionOfAccountingObject_);
	
	DescriptionOfAccountingObject_ = DescriptionOfAccountingObjectForConfiguringForms();
	DescriptionOfAccountingObject_.Group = GroupsOfAccountingObjects.Products;
	DescriptionOfAccountingObject_.Presentation = NStr("vi = 'Trong kho xưởng';
														|ru = 'В цеховой кладовой';
														|en = 'In shop floor stockrooms'; fa = 'In shop floor stockrooms';
														|it = 'В цеховой кладовой';
														|pl = 'W magazynie spiżarni';
														|tr = 'Atölye deposunda'");
	DescriptionOfAccountingObject_.TitleOfTheInvoiceSetupTable = NStr("vi = 'Tài khoản kế toán nguyên vật liệu trong kho xưởng';
																		|ru = 'Счета учета материалов в цеховых кладовых';
																		|en = 'Ledger accounts of materials in shop floor stockrooms'; fa = 'Ledger accounts of materials in shop floor stockrooms';
																		|it = 'Счета учета материалов в цеховых кладовых';
																		|pl = 'Konta księgowe materiałów w magazynach spiżarni';
																		|tr = 'İmalat deposunda malzemelerin defterikebir hesabı'");
	DescriptionOfAccountingObject_.DescriptionOfTheConfigurationObjectTypes = New TypeDescription("CatalogRef.InventoryAccountingGroups");
	DescriptionOfAccountingObject_.DescriptionOfTheAccountingLocationTypes = New TypeDescription("CatalogRef.Warehouses");
	DescriptionOfAccountingObjectsForConfiguringForms.Insert(Enums.DeleteFinancialAccountingObjects.ItemsInShopStoreroom, DescriptionOfAccountingObject_);
	
	DescriptionOfAccountingObject_ = DescriptionOfAccountingObjectForConfiguringForms();
	DescriptionOfAccountingObject_.Group = GroupsOfAccountingObjects.Products;
	DescriptionOfAccountingObject_.Presentation = NStr("vi = 'Đã giao hàng';
														|ru = 'Отгруженная';
														|en = 'Shipped'; fa = 'ارسال‌شده';
														|it = 'Отгруженная';
														|pl = 'Shipped';
														|tr = 'Gönderim'");
	DescriptionOfAccountingObject_.TitleOfTheInvoiceSetupTable = NStr("vi = 'Tài khoản kế toán hàng hóa đã giao cho khách hàng';
																		|ru = 'Счета учета товаров отгруженных покупателю';
																		|en = 'Ledger accounts of goods shipped to customer'; fa = 'Ledger accounts of goods shipped to customer';
																		|it = 'Счета учета товаров отгруженных покупателю';
																		|pl = 'Konta księgowe towarów wysłanych nabywcy';
																		|tr = 'Müşteriye indirilen ürünlerin defterikebir hesabı'");
	DescriptionOfAccountingObject_.DescriptionOfTheConfigurationObjectTypes = New TypeDescription("CatalogRef.InventoryAccountingGroups");
	DescriptionOfAccountingObject_.DescriptionOfTheAccountingLocationTypes = New TypeDescription();
	DescriptionOfAccountingObjectsForConfiguringForms.Insert(Enums.DeleteFinancialAccountingObjects.ItemShipped, DescriptionOfAccountingObject_);
	
	DescriptionOfAccountingObject_ = DescriptionOfAccountingObjectForConfiguringForms();
	DescriptionOfAccountingObject_.Group = GroupsOfAccountingObjects.Products;
	DescriptionOfAccountingObject_.Presentation = NStr("vi = 'Đã chuyển giao đi gia công';
														|ru = 'Переданная в переработку';
														|en = 'Transferred to subcontracting'; fa = 'Transferred to subcontracting';
														|it = 'Переданная в переработку';
														|pl = 'Przakazana do przetwarzania';
														|tr = 'Geri dönüşüme transfer edilen'");
	DescriptionOfAccountingObject_.TitleOfTheInvoiceSetupTable = NStr("vi = 'Tài khoản kế toán nguyên vật liệu đã chuyển giao cho người nhận gia công';
																		|ru = 'Счета учета материалов переданных переработчику';
																		|en = 'Ledger accounts of materials transferred to subcontractor'; fa = 'Ledger accounts of materials transferred to subcontractor';
																		|it = 'Счета учета материалов переданных переработчику';
																		|pl = 'Konta księgowe materiałów przekazanych przetwórcom';
																		|tr = 'Yeniden fason üreticiye transfer dilen ürünlerin defterikebir hesabı'");
	DescriptionOfAccountingObject_.DescriptionOfTheConfigurationObjectTypes = New TypeDescription("CatalogRef.InventoryAccountingGroups");
	DescriptionOfAccountingObject_.DescriptionOfTheAccountingLocationTypes = New TypeDescription();
	DescriptionOfAccountingObjectsForConfiguringForms.Insert(Enums.DeleteFinancialAccountingObjects.ItemTransferredForProcessing, DescriptionOfAccountingObject_);
	
	DescriptionOfAccountingObject_ = DescriptionOfAccountingObjectForConfiguringForms();
	DescriptionOfAccountingObject_.Group = GroupsOfAccountingObjects.Products;
	DescriptionOfAccountingObject_.Presentation = NStr("vi = 'Chuyển sang bảo quản và được phép xuất bán';
														|ru = 'Переданная на хранение с правом продажи';
														|en = 'Transferred to safekeeping with the right of sale'; fa = 'Transferred to safekeeping with the right of sale';
														|it = 'Переданная на хранение с правом продажи';
														|pl = 'Przekazana do przechowywanie z prawem sprzedaży';
														|tr = 'Satış hakkı ile depoya transfer edilen'");
	DescriptionOfAccountingObject_.TitleOfTheInvoiceSetupTable = NStr("vi = 'Tài khoản kế toán hàng hóa đã chuyển vào bảo quản';
																		|ru = 'Счета учета товаров переданных на хранение';
																		|en = 'Ledger accounts of goods transferred to safekeeping'; fa = 'Ledger accounts of goods transferred to safekeeping';
																		|it = 'Счета учета товаров переданных на хранение';
																		|pl = 'Konta księgowe towarów przekazanych do przechowywania';
																		|tr = 'Saklamaya verilmiş ürünlerin defterikebir hesabı'");
	DescriptionOfAccountingObject_.DescriptionOfTheConfigurationObjectTypes = New TypeDescription("CatalogRef.InventoryAccountingGroups");
	DescriptionOfAccountingObject_.DescriptionOfTheAccountingLocationTypes = New TypeDescription();
	DescriptionOfAccountingObjectsForConfiguringForms.Insert(Enums.DeleteFinancialAccountingObjects.ItemTransferredForStorage, DescriptionOfAccountingObject_);
	
	DescriptionOfAccountingObject_ = DescriptionOfAccountingObjectForConfiguringForms();
	DescriptionOfAccountingObject_.Group = GroupsOfAccountingObjects.Products;
	DescriptionOfAccountingObject_.Presentation = NStr("vi = 'Đã chuyển giao ký gửi';
														|ru = 'Переданная на комиссию';
														|en = 'Transferred to consignee'; fa = 'منتقل‌شده به امانت‌دار';
														|it = 'Переданная на комиссию';
														|pl = 'Przekazana do komisu';
														|tr = 'Komisyona transfer edilen'");
	DescriptionOfAccountingObject_.TitleOfTheInvoiceSetupTable = NStr("vi = 'Tài khoản kế toán hàng hóa đã chuyển giao cho người nhận ký gửi';
																		|ru = 'Счета учета товаров переданных комиссионеру';
																		|en = 'Ledger accounts of consignment sales stock'; fa = 'Ledger accounts of consignment sales stock';
																		|it = 'Счета учета товаров переданных комиссионеру';
																		|pl = 'Konta księgowe towarów przekazanych do komisanta';
																		|tr = 'Konsinyeye transfer edilen ürünlerin defterikebir hesabı'");
	DescriptionOfAccountingObject_.DescriptionOfTheConfigurationObjectTypes = New TypeDescription("CatalogRef.InventoryAccountingGroups");
	DescriptionOfAccountingObject_.DescriptionOfTheAccountingLocationTypes = New TypeDescription();
	DescriptionOfAccountingObjectsForConfiguringForms.Insert(Enums.DeleteFinancialAccountingObjects.ItemsSubmittedForCommission, DescriptionOfAccountingObject_);
	
	DescriptionOfAccountingObject_ = DescriptionOfAccountingObjectForConfiguringForms();
	DescriptionOfAccountingObject_.Group = GroupsOfAccountingObjects.Products;
	DescriptionOfAccountingObject_.Presentation = NStr("vi = 'Chênh lệch về giá trị';
														|ru = 'Отклонения в стоимости';
														|en = 'Cost variances'; fa = 'Cost variances';
														|it = 'Cost variances';
														|pl = 'Cost variances';
														|tr = 'Maliyetteki fark'");
	DescriptionOfAccountingObject_.TitleOfTheInvoiceSetupTable = NStr("vi = 'Tài khoản kế toán chênh lệch về giá trị';
																		|ru = 'Счета учета отклонений в стоимости товаров';
																		|en = 'Ledger accounts of item cost variances'; fa = 'Ledger accounts of item cost variances';
																		|it = 'Ledger accounts of item cost variances';
																		|pl = 'Ledger accounts of item cost variances';
																		|tr = 'Maliyetteki defterikebir hesapı farkları'");
	DescriptionOfAccountingObject_.DescriptionOfTheConfigurationObjectTypes = New TypeDescription("CatalogRef.InventoryAccountingGroups");
	DescriptionOfAccountingObject_.DescriptionOfTheAccountingLocationTypes = New TypeDescription("CatalogRef.Warehouses");
	DescriptionOfAccountingObjectsForConfiguringForms.Insert(Enums.DeleteFinancialAccountingObjects.ItemCostVariances, DescriptionOfAccountingObject_);
	
	DescriptionOfAccountingObject_ = DescriptionOfAccountingObjectForConfiguringForms();
	DescriptionOfAccountingObject_.Group = GroupsOfAccountingObjects.Products;
	DescriptionOfAccountingObject_.Presentation = NStr("vi = 'Bao bì luân chuyển đã chuyển giao';
														|ru = 'Переданная возвратная тара';
														|en = 'Transferred returnable packaging'; fa = 'بسته‌بندی برگشت‌پذیر انتقالی';
														|it = 'Переданная возвратная тара';
														|pl = 'Przekazana tara zwrotna';
														|tr = 'Transfer edilen iade edilebilir ambalaj'");
	DescriptionOfAccountingObject_.TitleOfTheInvoiceSetupTable = NStr("vi = 'Tài khoản hạch toán bao bì luân chuyển đã chuyển giao';
																		|ru = 'Счета учета переданной возвратной тары';
																		|en = 'Ledger accounts of transferred returnable packaging'; fa = 'Ledger accounts of transferred returnable packaging';
																		|it = 'Счета учета переданной возвратной тары';
																		|pl = 'Konta księgowe przekazanego opakowania zwrotnego';
																		|tr = 'Aktarılan iade edilebilir ambalajın defterikebir hesabı'");
	DescriptionOfAccountingObject_.DescriptionOfTheConfigurationObjectTypes = Undefined;
	DescriptionOfAccountingObject_.DescriptionOfTheAccountingLocationTypes = New TypeDescription();
	DescriptionOfAccountingObjectsForConfiguringForms.Insert(Enums.DeleteFinancialAccountingObjects.TransferredReturnablePackaging, DescriptionOfAccountingObject_);
	
	DescriptionOfAccountingObject_ = DescriptionOfAccountingObjectForConfiguringForms();
	DescriptionOfAccountingObject_.Group = GroupsOfAccountingObjects.Products;
	DescriptionOfAccountingObject_.Presentation = NStr("vi = 'Bao bì luân chuyển đã tiếp nhận';
														|ru = 'Принятая возвратная тара';
														|en = 'Received returnable packaging'; fa = 'بسته‌بندی برگشت‌پذیر دریافتی';
														|it = 'Принятая возвратная тара';
														|pl = 'Przyjęta tara zwrotna';
														|tr = 'İade edilebilir ambalajların kabulü'");
	DescriptionOfAccountingObject_.TitleOfTheInvoiceSetupTable = NStr("vi = 'Tài khoản hạch toán bao bì luân chuyển đã tiếp nhận';
																		|ru = 'Счета учета принятой возвратной тары';
																		|en = 'Ledger accounts of received returnable packaging'; fa = 'Ledger accounts of received returnable packaging';
																		|it = 'Счета учета принятой возвратной тары';
																		|pl = 'Konta księgowe przyjętego opakowania zwrotnego';
																		|tr = 'Kabul edilen iade edilebilir ambalajın defterikebir hesabı'");
	DescriptionOfAccountingObject_.DescriptionOfTheConfigurationObjectTypes = Undefined;
	DescriptionOfAccountingObject_.DescriptionOfTheAccountingLocationTypes = New TypeDescription();
	DescriptionOfAccountingObjectsForConfiguringForms.Insert(Enums.DeleteFinancialAccountingObjects.ReceivedReturnablePackaging, DescriptionOfAccountingObject_);
	
	#EndRegion
	
	#Region ProductListIsAccepted
	
	If TransactionSettings.MethodOfAccountingForImproperValues <> Enums.MethodsOfNotOwnedControlledValuesAccounting.NotRecordedOnAccounts
	   And TransactionSettings.MethodOfAccountingForImproperValues <> Enums.MethodsOfNotOwnedControlledValuesAccounting.EmptyRef() Then
		DescriptionOfAccountingObject_ = DescriptionOfAccountingObjectForConfiguringForms();
		DescriptionOfAccountingObject_.Group = GroupsOfAccountingObjects.ProductListIsAccepted;
		DescriptionOfAccountingObject_.Presentation = NStr("vi = 'Lưu kho';
															|ru = 'На хранение, на складе';
															|en = 'To store, at a warehouse'; fa = 'To store, at a warehouse';
															|it = 'На хранение, на складе';
															|pl = 'Na przechowywanie, w magazynie';
															|tr = 'Saklamak için, ambarda'");
		DescriptionOfAccountingObject_.TitleOfTheInvoiceSetupTable = NStr("vi = 'Tài khoản kế toán hàng hóa được tiếp nhận vào lưu kho';
																			|ru = 'Счета учета товаров принятых на хранение на складе';
																			|en = 'Ledger accounts of vendor-managed inventory'; fa = 'Ledger accounts of vendor-managed inventory';
																			|it = 'Счета учета товаров принятых на хранение на складе';
																			|pl = 'Konta księgowe towarów, przyjętych na przechowywanie w magazynie';
																			|tr = 'Ambarda saklamak için kabul edilen ürünlerin defterikebir hesabı'");
		DescriptionOfAccountingObject_.DescriptionOfTheConfigurationObjectTypes = New TypeDescription("CatalogRef.InventoryAccountingGroups");
		DescriptionOfAccountingObject_.DescriptionOfTheAccountingLocationTypes = New TypeDescription();
		DescriptionOfAccountingObjectsForConfiguringForms.Insert(Enums.DeleteFinancialAccountingObjects.ItemReceivedForStorageAtAWarehouse, DescriptionOfAccountingObject_);
		
		DescriptionOfAccountingObject_ = DescriptionOfAccountingObjectForConfiguringForms();
		DescriptionOfAccountingObject_.Group = GroupsOfAccountingObjects.ProductListIsAccepted;
		DescriptionOfAccountingObject_.Presentation = NStr("vi = 'Lưu vào kho xưởng';
															|ru = 'На хранение, в цеховой кладовой';
															|en = 'To store, in a shop floor stockroom'; fa = 'To store, in a shop floor stockroom';
															|it = 'На хранение, в цеховой кладовой';
															|pl = 'Na przechowywanie, w magazynie spiżarni';
															|tr = 'Depolamak için, atölye deposunda'");
		DescriptionOfAccountingObject_.TitleOfTheInvoiceSetupTable = NStr("vi = 'Tài khoản kế toán hàng hóa được tiếp nhận vào lưu kho xưởng';
																			|ru = 'Счета учета товаров принятых на хранение в цеховой кладовой';
																			|en = 'Ledger accounts of goods received to store in a shop floor stockroom'; fa = 'Ledger accounts of goods received to store in a shop floor stockroom';
																			|it = 'Счета учета товаров принятых на хранение в цеховой кладовой';
																			|pl = 'Konta księgowe towarów przyjętych do przechowywania w magazynie spiżarni';
																			|tr = 'Atölye deposunda saklamak için kabul edilmiş ürünlerin defterikebir hesabı'");
		DescriptionOfAccountingObject_.DescriptionOfTheConfigurationObjectTypes = New TypeDescription("CatalogRef.InventoryAccountingGroups");
		DescriptionOfAccountingObject_.DescriptionOfTheAccountingLocationTypes = New TypeDescription();
		DescriptionOfAccountingObjectsForConfiguringForms.Insert(Enums.DeleteFinancialAccountingObjects.ItemReceivedForStorageInAShopFloorStockroom, DescriptionOfAccountingObject_);
		
		DescriptionOfAccountingObject_ = DescriptionOfAccountingObjectForConfiguringForms();
		DescriptionOfAccountingObject_.Group = GroupsOfAccountingObjects.ProductListIsAccepted;
		DescriptionOfAccountingObject_.Presentation = NStr("vi = 'Lưu kho đã chuyển giao cho bạn hàng';
															|ru = 'На хранение, переданная партнерам';
															|en = 'To store, transferred to partners'; fa = 'To store, transferred to partners';
															|it = 'На хранение, переданная партнерам';
															|pl = 'Na przechowywanie, przekazane partnerom';
															|tr = 'Saklamak için, iş ortaklarına transfer edilen'");
		DescriptionOfAccountingObject_.TitleOfTheInvoiceSetupTable = NStr("vi = 'Tài khoản kế toán hàng hóa đã tiếp nhận vào lưu kho và chuyển giao cho bạn hàng';
																			|ru = 'Счета учета товаров принятых на хранение и переданных партнерам';
																			|en = 'Ledger accounts of vendor- managed inventory transferred to partners'; fa = 'Ledger accounts of vendor- managed inventory transferred to partners';
																			|it = 'Счета учета товаров принятых на хранение и переданных партнерам';
																			|pl = 'Konta księgowe towarów przyjętych do przechowywania i przekazanych partnerom';
																			|tr = 'Saklamaya kabul edilmiş ve iş ortaklara verilmiş ürünlerin defterikebir hesabı'");
		DescriptionOfAccountingObject_.DescriptionOfTheConfigurationObjectTypes = New TypeDescription("CatalogRef.InventoryAccountingGroups");
		DescriptionOfAccountingObject_.DescriptionOfTheAccountingLocationTypes = New TypeDescription();
		DescriptionOfAccountingObjectsForConfiguringForms.Insert(Enums.DeleteFinancialAccountingObjects.VMITransferredToPartners, DescriptionOfAccountingObject_);
		
		DescriptionOfAccountingObject_ = DescriptionOfAccountingObjectForConfiguringForms();
		DescriptionOfAccountingObject_.Group = GroupsOfAccountingObjects.ProductListIsAccepted;
		DescriptionOfAccountingObject_.Presentation = NStr("vi = 'Lưu kho, cần ghi giảm';
															|ru = 'На хранение, к списанию';
															|en = 'To store, to write off'; fa = 'To store, to write off';
															|it = 'На хранение, к списанию';
															|pl = 'Do przechowywania, do rozchodu';
															|tr = 'Saklamaya, gider yazmak için'");
		DescriptionOfAccountingObject_.TitleOfTheInvoiceSetupTable = NStr("vi = 'Tài khoản kế toán hàng hóa đã tiếp nhận vào lưu kho cần lập chứng từ ghi giảm';
																			|ru = 'Счета учета товаров принятых на хранение к оформлению списания';
																			|en = 'Ledger accounts of vendor-managed inventory to register write-off'; fa = 'Ledger accounts of vendor-managed inventory to register write-off';
																			|it = 'Счета учета товаров принятых на хранение к оформлению списания';
																			|pl = 'Konta księgowe towarów przyjętych do przechowywania do rejestracji rozchodu';
																			|tr = 'gider yazmaya saklanmak üzere kabul edilen ürünlerin defterikebir hesabı'");
		DescriptionOfAccountingObject_.DescriptionOfTheConfigurationObjectTypes = New TypeDescription("CatalogRef.InventoryAccountingGroups");
		DescriptionOfAccountingObject_.DescriptionOfTheAccountingLocationTypes = New TypeDescription();
		DescriptionOfAccountingObjectsForConfiguringForms.Insert(Enums.DeleteFinancialAccountingObjects.VMIToWriteOff, DescriptionOfAccountingObject_);
		
		DescriptionOfAccountingObject_ = DescriptionOfAccountingObjectForConfiguringForms();
		DescriptionOfAccountingObject_.Group = GroupsOfAccountingObjects.ProductListIsAccepted;
		DescriptionOfAccountingObject_.Presentation = NStr("vi = 'Đưa vào gia công trong kho';
															|ru = 'В переработку, на складе';
															|en = 'To subcontract, at a warehouse'; fa = 'To subcontract, at a warehouse';
															|it = 'В переработку, на складе';
															|pl = 'Do przetwarzania, w magazynie';
															|tr = 'Yeniden işlemeye, ambarda'");
		DescriptionOfAccountingObject_.TitleOfTheInvoiceSetupTable = NStr("vi = 'Tài khoản kế toán nguyên vật liệu được tiếp nhận vào gia công trong kho';
																			|ru = 'Счета учета материалов принятых в переработку на складе';
																			|en = 'Ledger accounts of materials for subcontracting at a warehouse'; fa = 'Ledger accounts of materials for subcontracting at a warehouse';
																			|it = 'Счета учета материалов принятых в переработку на складе';
																			|pl = 'Konta księgowe materiałów przyjętych do przetwarzania w magazynie';
																			|tr = 'Ambarda yeniden işlemek için kabul edilmiş ürünlerin defterikebir hesabı'");
		DescriptionOfAccountingObject_.DescriptionOfTheConfigurationObjectTypes = New TypeDescription("CatalogRef.InventoryAccountingGroups");
		DescriptionOfAccountingObject_.DescriptionOfTheAccountingLocationTypes = New TypeDescription();
		DescriptionOfAccountingObjectsForConfiguringForms.Insert(Enums.DeleteFinancialAccountingObjects.ItemReceivedForSubcontractingAtAWarehouse, DescriptionOfAccountingObject_);
		
		DescriptionOfAccountingObject_ = DescriptionOfAccountingObjectForConfiguringForms();
		DescriptionOfAccountingObject_.Group = GroupsOfAccountingObjects.ProductListIsAccepted;
		DescriptionOfAccountingObject_.Presentation = NStr("vi = 'Đưa vào gia công trong kho xưởng';
															|ru = 'В переработку, в цеховой кладовой';
															|en = 'To subcontract, in a shop floor stockroom'; fa = 'To subcontract, in a shop floor stockroom';
															|it = 'В переработку, в цеховой кладовой';
															|pl = 'Do przetwarzania, w magazynie spiżarni';
															|tr = 'Yeniden işlemeye, atölye deposu'");
		DescriptionOfAccountingObject_.TitleOfTheInvoiceSetupTable = NStr("vi = 'Tài khoản kế toán nguyên vật liệu được tiếp nhận vào gia công trong kho xưởng';
																			|ru = 'Счета учета материалов принятых в переработку в цеховой кладовой';
																			|en = 'Ledger accounts of materials for subcontracting in a shop floor stockroom'; fa = 'Ledger accounts of materials for subcontracting in a shop floor stockroom';
																			|it = 'Счета учета материалов принятых в переработку в цеховой кладовой';
																			|pl = 'Konta księgowe materiałów przyjętych do przetworzenia w magazynie spiżarni';
																			|tr = 'Atölye deposuna yeniden işlemek için kabul edilmiş ürünlerin defterikebir hesabı'");
		DescriptionOfAccountingObject_.DescriptionOfTheConfigurationObjectTypes = New TypeDescription("CatalogRef.InventoryAccountingGroups");
		DescriptionOfAccountingObject_.DescriptionOfTheAccountingLocationTypes = New TypeDescription();
		DescriptionOfAccountingObjectsForConfiguringForms.Insert(Enums.DeleteFinancialAccountingObjects.ItemReceivedForSubcontractingInAShopFloorStockroom, DescriptionOfAccountingObject_);
		
		DescriptionOfAccountingObject_ = DescriptionOfAccountingObjectForConfiguringForms();
		DescriptionOfAccountingObject_.Group = GroupsOfAccountingObjects.ProductListIsAccepted;
		DescriptionOfAccountingObject_.Presentation = NStr("vi = 'Đưa vào gia công đã chuyển giao cho bạn hàng';
															|ru = 'В переработку, переданная партнерам';
															|en = 'To subcontract, transferred to partners'; fa = 'To subcontract, transferred to partners';
															|it = 'В переработку, переданная партнерам';
															|pl = 'Do przetwarzania, przekazana partnerom';
															|tr = 'Yeniden işlemeye, iş ortaklarına transfer edilen'");
		DescriptionOfAccountingObject_.TitleOfTheInvoiceSetupTable = NStr("vi = 'Tài khoản kế toán nguyên vật liệu đã tiếp nhận vào gia công và chuyển giao cho bạn hàng';
																			|ru = 'Счета учета материалов принятых в переработку и переданных партнерам';
																			|en = 'Ledger accounts of materials received for subcontracting and transferred to partners'; fa = 'Ledger accounts of materials received for subcontracting and transferred to partners';
																			|it = 'Счета учета материалов принятых в переработку и переданных партнерам';
																			|pl = 'Konta księgowe materiałów, przyjętych do przetwarzania i przekazanych partnerom';
																			|tr = 'Yeniden işlemeye kabul edilmiş ve iş ortaklarına transfer edilen ürünlerin defterikebir hesabı'");
		DescriptionOfAccountingObject_.DescriptionOfTheConfigurationObjectTypes = New TypeDescription("CatalogRef.InventoryAccountingGroups");
		DescriptionOfAccountingObject_.DescriptionOfTheAccountingLocationTypes = New TypeDescription();
		DescriptionOfAccountingObjectsForConfiguringForms.Insert(Enums.DeleteFinancialAccountingObjects.ProductsReceivedForSubcontractingTransferredToPartners, DescriptionOfAccountingObject_);
		
		DescriptionOfAccountingObject_ = DescriptionOfAccountingObjectForConfiguringForms();
		DescriptionOfAccountingObject_.Group = GroupsOfAccountingObjects.ProductListIsAccepted;
		DescriptionOfAccountingObject_.Presentation = NStr("vi = 'Đưa vào gia công cần ghi giảm';
															|ru = 'В переработку, к списанию';
															|en = 'To subcontract, to write off'; fa = 'To subcontract, to write off';
															|it = 'В переработку, к списанию';
															|pl = 'Do przetwarzania, do rozchodu';
															|tr = 'Fason üretilecek, gider yazılacak'");
		DescriptionOfAccountingObject_.TitleOfTheInvoiceSetupTable = NStr("vi = 'Tài khoản kế toán nguyên vật liệu được tiếp nhận vào gia công cần lập chứng từ ghi giảm';
																			|ru = 'Счета учета материалов принятых в переработку к оформлению списания';
																			|en = 'Ledger accounts of materials received for subcontracting to register write-off'; fa = 'Ledger accounts of materials received for subcontracting to register write-off';
																			|it = 'Счета учета материалов принятых в переработку к оформлению списания';
																			|pl = 'Konta księgowe materiałów, przyjętych do przetwarzania do rejestracji rozchodu';
																			|tr = 'Gider yazmak için fason üretime kabul edilen ürünlerin defterikebir hesabı'");
		DescriptionOfAccountingObject_.DescriptionOfTheConfigurationObjectTypes = New TypeDescription("CatalogRef.InventoryAccountingGroups");
		DescriptionOfAccountingObject_.DescriptionOfTheAccountingLocationTypes = New TypeDescription();
		DescriptionOfAccountingObjectsForConfiguringForms.Insert(Enums.DeleteFinancialAccountingObjects.ProductsReceivedForSubcontractingToWriteOff, DescriptionOfAccountingObject_);
		
		DescriptionOfAccountingObject_ = DescriptionOfAccountingObjectForConfiguringForms();
		DescriptionOfAccountingObject_.Group = GroupsOfAccountingObjects.ProductListIsAccepted;
		DescriptionOfAccountingObject_.Presentation = NStr("vi = 'Đưa vào ký gửi';
															|ru = 'На комиссию';
															|en = 'To consignment'; fa = 'To consignment';
															|it = 'На комиссию';
															|pl = 'Na komis';
															|tr = 'Komisyon için'");
		DescriptionOfAccountingObject_.TitleOfTheInvoiceSetupTable = NStr("vi = 'Tài khoản kế toán hàng hóa được tiếp nhận vào ký gửi';
																			|ru = 'Счета учета товаров принятых на комиссию';
																			|en = 'Ledger accounts of consignment stock received'; fa = 'Ledger accounts of consignment stock received';
																			|it = 'Счета учета товаров принятых на комиссию';
																			|pl = 'Konta księgowe towarów przyjętych do komisu';
																			|tr = 'Komisyona kabul edilen ürünlerin defterikebir hesabı'");
		DescriptionOfAccountingObject_.DescriptionOfTheConfigurationObjectTypes = New TypeDescription("CatalogRef.InventoryAccountingGroups");
		DescriptionOfAccountingObject_.DescriptionOfTheAccountingLocationTypes = New TypeDescription();
		DescriptionOfAccountingObjectsForConfiguringForms.Insert(Enums.DeleteFinancialAccountingObjects.ConsignedItemReceived, DescriptionOfAccountingObject_);
		
		DescriptionOfAccountingObject_ = DescriptionOfAccountingObjectForConfiguringForms();
		DescriptionOfAccountingObject_.Group = GroupsOfAccountingObjects.ProductListIsAccepted;
		DescriptionOfAccountingObject_.Presentation = NStr("vi = 'Được chuyển vào ký gửi';
															|ru = 'Переданная на субкомиссию';
															|en = 'Handed over to sub-consignment'; fa = 'Handed over to sub-consignment';
															|it = 'Переданная на субкомиссию';
															|pl = 'Przekazana do subkomisu';
															|tr = 'Alt komisyona transfer edilen'");
		DescriptionOfAccountingObject_.TitleOfTheInvoiceSetupTable = NStr("vi = 'Tài khoản kế toán hàng hóa được chuyển giao đi ký gửi';
																			|ru = 'Счета учета товаров переданных на субкомиссию';
																			|en = 'Ledger accounts of goods handed over to sub-consignment'; fa = 'Ledger accounts of goods handed over to sub-consignment';
																			|it = 'Счета учета товаров переданных на субкомиссию';
																			|pl = 'Konta księgowe towarów przekazanych do subkomisu';
																			|tr = 'Alt komisyona transfer edilen ürünlerin defterikebir hesabı'");
		DescriptionOfAccountingObject_.DescriptionOfTheConfigurationObjectTypes = New TypeDescription("CatalogRef.InventoryAccountingGroups");
		DescriptionOfAccountingObject_.DescriptionOfTheAccountingLocationTypes = New TypeDescription();
		DescriptionOfAccountingObjectsForConfiguringForms.Insert(Enums.DeleteFinancialAccountingObjects.ItemHandedOverToSubConsignment, DescriptionOfAccountingObject_);
	EndIf;
	
	#EndRegion
	
	#Region FixedAssets
	
	DetailsAssetType = Metadata.Catalogs.NonCurrentAssetsAccountingGroups.Attributes.AssetKind.Name;
	ArrayOfAssetTypes = New Array;
	ArrayOfAssetTypes.Add(Enums.KindsOfNonCurrentAssets.FixedAsset);
	ArrayOfAssetTypes.Add(Enums.KindsOfNonCurrentAssets.InvestmentProperty);
	SelectionOfFinancialAccountingGroupsFA = New Structure(DetailsAssetType, ArrayOfAssetTypes);
	
	DescriptionOfAccountingObject_ = DescriptionOfAccountingObjectForConfiguringForms();
	DescriptionOfAccountingObject_.Group = GroupsOfAccountingObjects.FixedAssets;
	DescriptionOfAccountingObject_.Presentation = NStr("vi = 'Giá trị TSCĐ';
														|ru = 'Стоимость ОС';
														|en = 'Fixed assets cost'; fa = 'بهای دارایی‌های ثابت';
														|it = 'Стоимость ОС';
														|pl = 'Wartość środki trwałe';
														|tr = 'Sabit kıymet maliyeti'");
	DescriptionOfAccountingObject_.TitleOfTheInvoiceSetupTable = NStr("vi = 'Tài khoản kế toán giá trị TSCĐ';
																		|ru = 'Счета учета стоимости ОС';
																		|en = 'Ledger accounts of fixed assets cost'; fa = 'Ledger accounts of fixed assets cost';
																		|it = 'Счета учета стоимости ОС';
																		|pl = 'Konta księgowe wartości środków trwałych';
																		|tr = 'Sabit kıymet ücret defterikebir hesabı'");
	DescriptionOfAccountingObject_.DescriptionOfTheConfigurationObjectTypes = New TypeDescription("CatalogRef.NonCurrentAssetsAccountingGroups");
	DescriptionOfAccountingObject_.SelectingConfigurationObjects = SelectionOfFinancialAccountingGroupsFA;
	DescriptionOfAccountingObject_.DescriptionOfTheAccountingLocationTypes = New TypeDescription();
	DescriptionOfAccountingObjectsForConfiguringForms.Insert(Enums.DeleteFinancialAccountingObjects.FACost, DescriptionOfAccountingObject_);
	
	DescriptionOfAccountingObject_ = DescriptionOfAccountingObjectForConfiguringForms();
	DescriptionOfAccountingObject_.Group = GroupsOfAccountingObjects.FixedAssets;
	DescriptionOfAccountingObject_.Presentation = NStr("vi = 'Khấu hao TSCĐ';
														|ru = 'Амортизация ОС';
														|en = 'Fixed assets — Depreciation charge'; fa = 'دارایی‌های ثابت — محاسبه استهلاک';
														|it = 'Амортизация ОС';
														|pl = 'Amortyzacja środków trwałych';
														|tr = 'Amortisman SV'");
	DescriptionOfAccountingObject_.TitleOfTheInvoiceSetupTable = NStr("vi = 'Tài khoản khấu hao TSCĐ';
																		|ru = 'Счета учета амортизации ОС';
																		|en = 'Ledger accounts of fixed asset depreciation'; fa = 'Ledger accounts of fixed asset depreciation';
																		|it = 'Счета учета амортизации ОС';
																		|pl = 'Konta księgowe amortyzacji środków trwałych';
																		|tr = 'Amortisman SK defterikebir hesabı'");
	DescriptionOfAccountingObject_.DescriptionOfTheConfigurationObjectTypes = New TypeDescription("CatalogRef.NonCurrentAssetsAccountingGroups");
	DescriptionOfAccountingObject_.SelectingConfigurationObjects = SelectionOfFinancialAccountingGroupsFA;
	DescriptionOfAccountingObject_.DescriptionOfTheAccountingLocationTypes = New TypeDescription();
	DescriptionOfAccountingObjectsForConfiguringForms.Insert(Enums.DeleteFinancialAccountingObjects.FixedAssetsDepreciationCharge, DescriptionOfAccountingObject_);
	
	DescriptionOfAccountingObject_ = DescriptionOfAccountingObjectForConfiguringForms();
	DescriptionOfAccountingObject_.Group = GroupsOfAccountingObjects.FixedAssets;
	DescriptionOfAccountingObject_.Presentation = NStr("vi = 'Dự phòng đánh giá lại giá trị TSCĐ';
														|ru = 'Резерв переоценки стоимости ОС';
														|en = 'Revaluation reserve of fixed assets cost'; fa = 'مازاد تجدید ارزیابی بهای دارایی‌های ثابت';
														|it = 'Резерв переоценки стоимости ОС';
														|pl = 'Rezerwa przeszacowania wartości środków trwałych';
														|tr = 'Sabit kıymet yeniden değerlemesi değer rezervi'");
	DescriptionOfAccountingObject_.TitleOfTheInvoiceSetupTable = NStr("vi = 'Tài khoản kế toán dự phòng đánh giá lại giá trị TSCĐ';
																		|ru = 'Счета учета резерва переоценки стоимости ОС';
																		|en = 'Ledger accounts of revaluation reserve of fixed assets cost'; fa = 'Ledger accounts of revaluation reserve of fixed assets cost';
																		|it = 'Счета учета резерва переоценки стоимости ОС';
																		|pl = 'Konta księgowe rezerwy przeszacowania wartości środków trwałych';
																		|tr = 'SK''nın değerini yeniden değerleme rezervini defterikebir hesabı'");
	DescriptionOfAccountingObject_.DescriptionOfTheConfigurationObjectTypes = New TypeDescription("CatalogRef.NonCurrentAssetsAccountingGroups");
	DescriptionOfAccountingObject_.SelectingConfigurationObjects = SelectionOfFinancialAccountingGroupsFA;
	DescriptionOfAccountingObject_.DescriptionOfTheAccountingLocationTypes = New TypeDescription();
	DescriptionOfAccountingObjectsForConfiguringForms.Insert(Enums.DeleteFinancialAccountingObjects.RevaluationReserveForFixedAssets, DescriptionOfAccountingObject_);
	
	DescriptionOfAccountingObject_ = DescriptionOfAccountingObjectForConfiguringForms();
	DescriptionOfAccountingObject_.Group = GroupsOfAccountingObjects.FixedAssets;
	DescriptionOfAccountingObject_.Presentation = NStr("vi = 'Khấu hao TSCĐ';
														|ru = 'Обесценение ОС';
														|en = 'Fixed asset impairment'; fa = 'کاهش ارزش دارایی ثابت';
														|it = 'Обесценение ОС';
														|pl = 'Utrata wartości ŚT';
														|tr = 'SK değer kaybı'");
	DescriptionOfAccountingObject_.TitleOfTheInvoiceSetupTable = NStr("vi = 'Tài khoản kế toán khấu hao TSCĐ';
																		|ru = 'Счета учета обесценения ОС';
																		|en = 'Fixed asset impairment ledger account'; fa = 'Fixed asset impairment ledger account';
																		|it = 'Счета учета обесценения ОС';
																		|pl = 'Konta księgowe utraty wartości ŚT';
																		|tr = 'SK değer kaybı defterikebir hesabı'");
	DescriptionOfAccountingObject_.DescriptionOfTheConfigurationObjectTypes = New TypeDescription("CatalogRef.NonCurrentAssetsAccountingGroups");
	DescriptionOfAccountingObject_.SelectingConfigurationObjects = SelectionOfFinancialAccountingGroupsFA;
	DescriptionOfAccountingObject_.DescriptionOfTheAccountingLocationTypes = New TypeDescription();
	DescriptionOfAccountingObjectsForConfiguringForms.Insert(Enums.DeleteFinancialAccountingObjects.FAImpairment, DescriptionOfAccountingObject_);
	
	DescriptionOfAccountingObject_ = DescriptionOfAccountingObjectForConfiguringForms();
	DescriptionOfAccountingObject_.Group = GroupsOfAccountingObjects.FixedAssets;
	DescriptionOfAccountingObject_.Presentation = NStr("vi = 'TSCĐ đã chuyển giao';
														|ru = 'Переданные ОС';
														|en = 'Fixed assets provided'; fa = 'دارایی‌های ثابت واگذارشده';
														|it = 'Переданные ОС';
														|pl = 'Fixed assets provided';
														|tr = 'Transfer edilen SV'");
	DescriptionOfAccountingObject_.TitleOfTheInvoiceSetupTable = NStr("vi = 'Tài khoản kế toán TSCĐ đã chuyển giao';
																		|ru = 'Счета учета переданных ОС';
																		|en = 'Ledger accounts of fixed assets provided'; fa = 'Ledger accounts of fixed assets provided';
																		|it = 'Счета учета переданных ОС';
																		|pl = 'Ledger accounts of fixed assets provided';
																		|tr = 'Transfer edilen SV için defterikebir hesabı'");
	DescriptionOfAccountingObject_.DescriptionOfTheConfigurationObjectTypes = New TypeDescription();
	DescriptionOfAccountingObject_.DescriptionOfTheAccountingLocationTypes = New TypeDescription();
	DescriptionOfAccountingObjectsForConfiguringForms.Insert(Enums.DeleteFinancialAccountingObjects.FixedAssetsProvided, DescriptionOfAccountingObject_);

	#EndRegion
	
	#Region IntangibleAssets
	
	DetailsAssetType = Metadata.Catalogs.NonCurrentAssetsAccountingGroups.Attributes.AssetKind.Name;
	ArrayOfAssetTypes = New Array;
	ArrayOfAssetTypes.Add(Enums.KindsOfNonCurrentAssets.IA);
	ArrayOfAssetTypes.Add(Enums.KindsOfNonCurrentAssets.RD);
	SelectionOfFinancialAccountingGroupsOfIa = New Structure(DetailsAssetType, ArrayOfAssetTypes);
	
	DescriptionOfAccountingObject_ = DescriptionOfAccountingObjectForConfiguringForms();
	DescriptionOfAccountingObject_.Group = GroupsOfAccountingObjects.IntangibleAssets;
	DescriptionOfAccountingObject_.Presentation = NStr("vi = 'Giá trị tài sản cố định vô hình';
														|ru = 'Стоимость НМА';
														|en = 'Intangible assets cost'; fa = 'بهای دارایی‌های نامشهود';
														|it = 'Стоимость НМА';
														|pl = 'Koszt wartości niematerialnych';
														|tr = 'Maliyet GMA'");
	DescriptionOfAccountingObject_.TitleOfTheInvoiceSetupTable = NStr("vi = 'Tài khoản kế toán giá trị TSCĐVH';
																		|ru = 'Счета учета стоимости НМА';
																		|en = 'Ledger accounts of intangible assets cost'; fa = 'Ledger accounts of intangible assets cost';
																		|it = 'Счета учета стоимости НМА';
																		|pl = 'Konta księgowe kosztów wartości niematerialnych';
																		|tr = 'Maddi olmayan varlıkların maliyeti defterikebir hesabı'");
	DescriptionOfAccountingObject_.DescriptionOfTheConfigurationObjectTypes = New TypeDescription("CatalogRef.NonCurrentAssetsAccountingGroups");
	DescriptionOfAccountingObject_.SelectingConfigurationObjects = SelectionOfFinancialAccountingGroupsOfIa;
	DescriptionOfAccountingObject_.DescriptionOfTheAccountingLocationTypes = New TypeDescription();
	DescriptionOfAccountingObjectsForConfiguringForms.Insert(Enums.DeleteFinancialAccountingObjects.IACost, DescriptionOfAccountingObject_);
	
	DescriptionOfAccountingObject_ = DescriptionOfAccountingObjectForConfiguringForms();
	DescriptionOfAccountingObject_.Group = GroupsOfAccountingObjects.IntangibleAssets;
	DescriptionOfAccountingObject_.Presentation = NStr("vi = 'Khấu hao TSCĐ vô hình';
														|ru = 'Амортизация НМА';
														|en = 'Intangible assets — Amortization charge'; fa = 'دارایی‌های نامشهود — محاسبه استهلاک';
														|it = 'Амортизация НМА';
														|pl = 'Amortyzacja wartości niematerialnych';
														|tr = 'Maddi olmayan varlıklar - Amortisman gideri'");
	DescriptionOfAccountingObject_.TitleOfTheInvoiceSetupTable = NStr("vi = 'Tài khoản khấu hao TSCĐ vô hình';
																		|ru = 'Счета учета амортизации НМА';
																		|en = 'Ledger accounts of intangible asset amortization'; fa = 'Ledger accounts of intangible asset amortization';
																		|it = 'Счета учета амортизации НМА';
																		|pl = 'Konta księgowe amortyzacji wartości niematerialnych';
																		|tr = 'Maddi olmayan varlıklar - Amortisman defterikebir hesabı'");
	DescriptionOfAccountingObject_.DescriptionOfTheConfigurationObjectTypes = New TypeDescription("CatalogRef.NonCurrentAssetsAccountingGroups");
	DescriptionOfAccountingObject_.SelectingConfigurationObjects = SelectionOfFinancialAccountingGroupsOfIa;
	DescriptionOfAccountingObject_.DescriptionOfTheAccountingLocationTypes = New TypeDescription();
	DescriptionOfAccountingObjectsForConfiguringForms.Insert(Enums.DeleteFinancialAccountingObjects.IntangibleAssetsAmortizationCharge, DescriptionOfAccountingObject_);
	
	DescriptionOfAccountingObject_ = DescriptionOfAccountingObjectForConfiguringForms();
	DescriptionOfAccountingObject_.Group = GroupsOfAccountingObjects.IntangibleAssets;
	DescriptionOfAccountingObject_.Presentation = NStr("vi = 'Dự phòng đánh giá lại giá trị TSCĐ vô hình';
														|ru = 'Резерв переоценки стоимости НМА';
														|en = 'Revaluation reserve of intangible assets cost'; fa = 'مازاد تجدید ارزیابی بهای دارایی‌های نامشهود';
														|it = 'Резерв переоценки стоимости НМА';
														|pl = 'Rezerwa przeszacowania kosztów wartości niematerialnych';
														|tr = 'Maddi olmayan varlıkların yeniden değerlemesi değer rezervi'");
	DescriptionOfAccountingObject_.TitleOfTheInvoiceSetupTable = NStr("vi = 'Tài khoản kế toán dự phòng đánh giá lại giá trị TSCĐ vô hình';
																		|ru = 'Счета учета резерва переоценки стоимости НМА';
																		|en = 'Ledger accounts of revaluation reserve of intangible assets cost'; fa = 'Ledger accounts of revaluation reserve of intangible assets cost';
																		|it = 'Счета учета резерва переоценки стоимости НМА';
																		|pl = 'Konta księgowe rezerwy przeszacowania kosztów wartości niematerialnych';
																		|tr = 'Maddi olmayan varlıkların yeniden değerlemesi değer rezervi defterikebir hesabı'");
	DescriptionOfAccountingObject_.DescriptionOfTheConfigurationObjectTypes = New TypeDescription("CatalogRef.NonCurrentAssetsAccountingGroups");
	DescriptionOfAccountingObject_.SelectingConfigurationObjects = SelectionOfFinancialAccountingGroupsOfIa;
	DescriptionOfAccountingObject_.DescriptionOfTheAccountingLocationTypes = New TypeDescription();
	DescriptionOfAccountingObjectsForConfiguringForms.Insert(Enums.DeleteFinancialAccountingObjects.RevaluationReserveForIA, DescriptionOfAccountingObject_);
	
	DescriptionOfAccountingObject_ = DescriptionOfAccountingObjectForConfiguringForms();
	DescriptionOfAccountingObject_.Group = GroupsOfAccountingObjects.IntangibleAssets;
	DescriptionOfAccountingObject_.Presentation = NStr("vi = 'Khấu hao TSCĐ vô hình';
														|ru = 'Обесценение НМА';
														|en = 'Intangible asset impairment'; fa = 'کاهش ارزش دارایی نامشهود';
														|it = 'Обесценение НМА';
														|pl = 'Utrata wartości aktywów niematerialnych';
														|tr = 'Maddi olmayan varlıkların değer kaybı'");
	DescriptionOfAccountingObject_.TitleOfTheInvoiceSetupTable = NStr("vi = 'Tài khoản kế toán khấu hao TSCĐ vô hình';
																		|ru = 'Счета учета обесценения НМА';
																		|en = 'Intangible asset impairment ledger account'; fa = 'Intangible asset impairment ledger account';
																		|it = 'Счета учета обесценения НМА';
																		|pl = 'Konta księgowe utraty wartości aktywów niematerialnych';
																		|tr = 'Maddi olmayan varlıkların değer kaybı defterikebir hesabı'");
	DescriptionOfAccountingObject_.DescriptionOfTheConfigurationObjectTypes = New TypeDescription("CatalogRef.NonCurrentAssetsAccountingGroups");
	DescriptionOfAccountingObject_.SelectingConfigurationObjects = SelectionOfFinancialAccountingGroupsOfIa;
	DescriptionOfAccountingObject_.DescriptionOfTheAccountingLocationTypes = New TypeDescription();
	DescriptionOfAccountingObjectsForConfiguringForms.Insert(Enums.DeleteFinancialAccountingObjects.ImpairmentIA, DescriptionOfAccountingObject_);
	
	#EndRegion

	#Region CustomersARAPAccounting
	
	DetailsOfHFCCalculations = Metadata.Catalogs.FinancialAccountingGroupsOfARAP.Attributes;
	SelectionOfFinancialAccountingGroupsForSettlementsWithClients = New Array();
	SelectionOfFinancialAccountingGroupsForSettlementsWithClients.Add(New Structure(DetailsOfHFCCalculations.CustomersARAPAccounting.Name, True));
	SelectionOfFinancialAccountingGroupsForSettlementsWithClients.Add(New Structure(DetailsOfHFCCalculations.CommissionAgentsARAPAccounting.Name, True));
	SelectionOfFinancialAccountingGroupsForSettlementsWithClients.Add(New Structure(DetailsOfHFCCalculations.PurchaseSettlementsWithConsignors.Name, True));
	SelectionOfFinancialAccountingGroupsForSettlementsWithClients.Add(New Structure(DetailsOfHFCCalculations.ConsignorsARAPAccounting.Name, True));
	SelectionOfFinancialAccountingGroupsForSettlementsWithClients.Add(New Structure(DetailsOfHFCCalculations.SettlementsWithSubcontractor.Name, True));
	SelectionOfFinancialAccountingGroupsForSettlementsWithClients.Add(New Structure(DetailsOfHFCCalculations.ProvidersARAP.Name, True));
	
	DescriptionOfAccountingObject_ = DescriptionOfAccountingObjectForConfiguringForms();
	DescriptionOfAccountingObject_.Group = GroupsOfAccountingObjects.CustomersARAPAccounting;
	DescriptionOfAccountingObject_.Presentation = NStr("vi = 'Ứng trước';
														|ru = 'Аванс';
														|en = 'Prepayment'; fa = 'پیش‌پرداخت';
														|it = 'Аванс';
														|pl = 'Prepayment';
														|tr = 'Ön ödeme'");
	DescriptionOfAccountingObject_.TitleOfTheInvoiceSetupTable = NStr("vi = 'Tài khoản kế toán ứng trước đã nhận của khách hàng';
																		|ru = 'Счета учета авансов, полученных от клиентов';
																		|en = 'Ledger accounts of prepayments from customers'; fa = 'Ledger accounts of prepayments from customers';
																		|it = 'Счета учета авансов, полученных от клиентов';
																		|pl = 'Konta księgowe zaliczek, otrzymanych od klientów';
																		|tr = 'Müşterilerden alınmış avansların defterikebir hesabı'");
	DescriptionOfAccountingObject_.DescriptionOfTheConfigurationObjectTypes = New TypeDescription("CatalogRef.FinancialAccountingGroupsOfARAP");
	DescriptionOfAccountingObject_.SelectingConfigurationObjects = SelectionOfFinancialAccountingGroupsForSettlementsWithClients;
	DescriptionOfAccountingObject_.DescriptionOfTheAccountingLocationTypes = New TypeDescription();
	DescriptionOfAccountingObjectsForConfiguringForms.Insert(Enums.DeleteFinancialAccountingObjects.PrepaymentsFromCustomers, DescriptionOfAccountingObject_);
	
	DescriptionOfAccountingObject_ = DescriptionOfAccountingObjectForConfiguringForms();
	DescriptionOfAccountingObject_.Group = GroupsOfAccountingObjects.CustomersARAPAccounting;
	DescriptionOfAccountingObject_.Presentation = NStr("vi = 'Công nợ';
														|ru = 'Задолженность';
														|en = 'Debt'; fa = 'بدهی';
														|it = 'Задолженность';
														|pl = 'Debt';
														|tr = 'Borç'");
	DescriptionOfAccountingObject_.TitleOfTheInvoiceSetupTable = NStr("vi = 'Tài khoản kế toán công nợ phải thu khách hàng';
																		|ru = 'Счета учета задолженности клиентов';
																		|en = 'Ledger accounts of customer receivables'; fa = 'Ledger accounts of customer receivables';
																		|it = 'Счета учета задолженности клиентов';
																		|pl = 'Konta księgowe zadłużenia klientów';
																		|tr = 'Müşteri alacakları/borçlarının defterikebir hesabı'");
	DescriptionOfAccountingObject_.DescriptionOfTheConfigurationObjectTypes = New TypeDescription("CatalogRef.FinancialAccountingGroupsOfARAP");
	DescriptionOfAccountingObject_.SelectingConfigurationObjects = SelectionOfFinancialAccountingGroupsForSettlementsWithClients;
	DescriptionOfAccountingObject_.DescriptionOfTheAccountingLocationTypes = New TypeDescription();
	DescriptionOfAccountingObjectsForConfiguringForms.Insert(Enums.DeleteFinancialAccountingObjects.CustomersAccountsReceivable, DescriptionOfAccountingObject_);
	
	DescriptionOfAccountingObject_ = DescriptionOfAccountingObjectForConfiguringForms();
	DescriptionOfAccountingObject_.Group = GroupsOfAccountingObjects.CustomersARAPAccounting;
	DescriptionOfAccountingObject_.Presentation = NStr("vi = 'Phiếu quà tặng';
														|ru = 'Подарочные сертификаты';
														|en = 'Gift cards'; fa = 'کارت‌های هدیه';
														|it = 'Подарочные сертификаты';
														|pl = 'Certyfikaty podarunkowe';
														|tr = 'Hediye kartları'");
	DescriptionOfAccountingObject_.TitleOfTheInvoiceSetupTable = NStr("vi = 'Tài khoản hạch toán phiếu quà tặng';
																		|ru = 'Счета учета подарочных сертификатов';
																		|en = 'Ledger accounts of gift cards'; fa = 'Ledger accounts of gift cards';
																		|it = 'Счета учета подарочных сертификатов';
																		|pl = 'Konta księgowe certyfikatów podarunkowych';
																		|tr = 'Hediye kartlarının defterikebir hesabı'");
	DescriptionOfAccountingObject_.DescriptionOfTheConfigurationObjectTypes = Undefined;
	DescriptionOfAccountingObject_.DescriptionOfTheAccountingLocationTypes = New TypeDescription();
	DescriptionOfAccountingObjectsForConfiguringForms.Insert(Enums.DeleteFinancialAccountingObjects.GiftCertificates, DescriptionOfAccountingObject_);
	
	If TransactionSettings.OptionForGeneratingTransactions = Undefined
	 Or TransactionSettings.OptionForGeneratingTransactions = Enums.EntryGenerationOptions.WithCorrespondence Then
		DescriptionOfAccountingObject_ = DescriptionOfAccountingObjectForConfiguringForms();
		DescriptionOfAccountingObject_.Group = GroupsOfAccountingObjects.CustomersARAPAccounting;
		DescriptionOfAccountingObject_.Presentation = NStr("vi = 'Hạch toán công nợ với khách mua lẻ';
															|ru = 'Расчеты с розничными покупателями';
															|en = 'AR/AP accounting for retail customers'; fa = 'حسابداری دریافتنی/پرداختنی مشتریان خرده‌فروشی';
															|it = 'Расчеты с розничными покупателями';
															|pl = 'Rozliczenia z nabywcami detalicznymi';
															|tr = 'Perakende müşterilere ilişkin hesaplamalar'");
		DescriptionOfAccountingObject_.TitleOfTheInvoiceSetupTable = NStr("vi = 'Tài khoản hạch toán với khách mua lẻ';
																			|ru = 'Счета учета расчетов с розничными покупателями';
																			|en = 'Ledger accounts of AR/AP accounting for retail customers'; fa = 'Ledger accounts of AR/AP accounting for retail customers';
																			|it = 'Счета учета расчетов с розничными покупателями';
																			|pl = 'Konta księgowe z nabywcami detalicznymi';
																			|tr = 'Perakende müşterilere ilişkin hesaplamaların defterikebir hesabı'");
		DescriptionOfAccountingObject_.DescriptionOfTheConfigurationObjectTypes = Undefined;
		DescriptionOfAccountingObject_.DescriptionOfTheAccountingLocationTypes = New TypeDescription();
		DescriptionOfAccountingObjectsForConfiguringForms.Insert(Enums.DeleteFinancialAccountingObjects.RetailCustomerAccountsReceivables, DescriptionOfAccountingObject_);
	EndIf;
	
	DescriptionOfAccountingObject_ = DescriptionOfAccountingObjectForConfiguringForms();
	DescriptionOfAccountingObject_.Group = GroupsOfAccountingObjects.CustomersARAPAccounting;
	DescriptionOfAccountingObject_.Presentation = NStr("vi = 'Nợ phải trả người nhận ký gửi theo dữ liệu mua hàng';
														|ru = 'Обязательства перед комитентом по закупкам';
														|en = 'Liabilities to vendor for purchasing'; fa = 'بدهی‌ها به تأمین‌کننده بابت خرید';
														|it = 'Обязательства перед комитентом по закупкам';
														|pl = 'Zobowiązania przed komitentem według zakupów';
														|tr = 'Satın almaya ilişkin göndericiye karşı sorumluluklar'");
	DescriptionOfAccountingObject_.TitleOfTheInvoiceSetupTable = NStr("vi = 'Tài khoản hạch toán nợ với người nhận ký gửi theo mua hàng';
																		|ru = 'Счета учета обязательств перед комитентом по закупкам';
																		|en = 'Ledger accounts of liabilities to vendor for purchasing'; fa = 'Ledger accounts of liabilities to vendor for purchasing';
																		|it = 'Счета учета обязательств перед комитентом по закупкам';
																		|pl = 'Konta księgowe przed komitentem według zakupów';
																		|tr = 'Satın almaya ilişkin göndericiye karşı sorumluluklarının defterikebir hesabı'");
	DescriptionOfAccountingObject_.DescriptionOfTheConfigurationObjectTypes = Undefined;
	DescriptionOfAccountingObject_.DescriptionOfTheAccountingLocationTypes = New TypeDescription();
	DescriptionOfAccountingObjectsForConfiguringForms.Insert(Enums.DeleteFinancialAccountingObjects.ObligationsToProcurementCommittee, DescriptionOfAccountingObject_);
	
	#EndRegion
	
	#Region VendorsARAPAccounting
	
	DetailsOfHFCCalculations = Metadata.Catalogs.FinancialAccountingGroupsOfARAP.Attributes;
	SelectionOfFinancialAccountingGroupsForSettlementsWithSuppliers = New Array();
	SelectionOfFinancialAccountingGroupsForSettlementsWithSuppliers.Add(New Structure(DetailsOfHFCCalculations.VendorsARAPAccounting.Name, True));
	SelectionOfFinancialAccountingGroupsForSettlementsWithSuppliers.Add(New Structure(DetailsOfHFCCalculations.ConsignorsARAPAccounting.Name, True));
	SelectionOfFinancialAccountingGroupsForSettlementsWithSuppliers.Add(New Structure(DetailsOfHFCCalculations.CommissionAgentsARAPAccounting.Name, True));
	SelectionOfFinancialAccountingGroupsForSettlementsWithSuppliers.Add(New Structure(DetailsOfHFCCalculations.SettlementsWithSubcontractor.Name, True));
	SelectionOfFinancialAccountingGroupsForSettlementsWithSuppliers.Add(New Structure(DetailsOfHFCCalculations.ProvidersARAP.Name, True));
	
	DescriptionOfAccountingObject_ = DescriptionOfAccountingObjectForConfiguringForms();
	DescriptionOfAccountingObject_.Group = GroupsOfAccountingObjects.VendorsARAPAccounting;
	DescriptionOfAccountingObject_.Presentation = NStr("vi = 'Ứng trước';
														|ru = 'Аванс';
														|en = 'Prepayment'; fa = 'پیش‌پرداخت';
														|it = 'Аванс';
														|pl = 'Prepayment';
														|tr = 'Ön ödeme'");
	DescriptionOfAccountingObject_.TitleOfTheInvoiceSetupTable = NStr("vi = 'Tài khoản kế toán ứng trước đã chi cho nhà cung cấp';
																		|ru = 'Счета учета авансов, выплаченных поставщикам';
																		|en = 'Ledger accounts of prepayments to vendors'; fa = 'Ledger accounts of prepayments to vendors';
																		|it = 'Счета учета авансов, выплаченных поставщикам';
																		|pl = 'Konta księgowe zaliczek, wypłaconych dostawcom';
																		|tr = 'Tedarikçilere ödenmiş avansların defterikebir hesabı'");
	DescriptionOfAccountingObject_.DescriptionOfTheConfigurationObjectTypes = New TypeDescription("CatalogRef.FinancialAccountingGroupsOfARAP");
	DescriptionOfAccountingObject_.SelectingConfigurationObjects = SelectionOfFinancialAccountingGroupsForSettlementsWithSuppliers;
	DescriptionOfAccountingObject_.DescriptionOfTheAccountingLocationTypes = New TypeDescription();
	DescriptionOfAccountingObjectsForConfiguringForms.Insert(Enums.DeleteFinancialAccountingObjects.PrepaymentsToVendors, DescriptionOfAccountingObject_);
	
	DescriptionOfAccountingObject_ = DescriptionOfAccountingObjectForConfiguringForms();
	DescriptionOfAccountingObject_.Group = GroupsOfAccountingObjects.VendorsARAPAccounting;
	DescriptionOfAccountingObject_.Presentation = NStr("vi = 'Công nợ';
														|ru = 'Задолженность';
														|en = 'Debt'; fa = 'بدهی';
														|it = 'Задолженность';
														|pl = 'Debt';
														|tr = 'Borç'");
	DescriptionOfAccountingObject_.TitleOfTheInvoiceSetupTable = NStr("vi = 'Tài khoản kế toán công nợ phải trả nhà cung cấp';
																		|ru = 'Счета учета задолженности перед поставщиками';
																		|en = 'Ledger accounts of vendor payables'; fa = 'Ledger accounts of vendor payables';
																		|it = 'Счета учета задолженности перед поставщиками';
																		|pl = 'Konta księgowe zadłużenia przed dostawcami';
																		|tr = 'Tedarikçilere karşı borçların defterikebir hesabı'");
	DescriptionOfAccountingObject_.DescriptionOfTheConfigurationObjectTypes = New TypeDescription("CatalogRef.FinancialAccountingGroupsOfARAP");
	DescriptionOfAccountingObject_.SelectingConfigurationObjects = SelectionOfFinancialAccountingGroupsForSettlementsWithSuppliers;
	DescriptionOfAccountingObject_.DescriptionOfTheAccountingLocationTypes = New TypeDescription();
	DescriptionOfAccountingObjectsForConfiguringForms.Insert(Enums.DeleteFinancialAccountingObjects.VendorAccountsReceivable, DescriptionOfAccountingObject_);
	
	DescriptionOfAccountingObject_ = DescriptionOfAccountingObjectForConfiguringForms();
	DescriptionOfAccountingObject_.Group = GroupsOfAccountingObjects.VendorsARAPAccounting;
	DescriptionOfAccountingObject_.Presentation = NStr("vi = 'Vé và đặt chỗ';
														|ru = 'Билеты и бронирование';
														|en = 'Tickets and booking'; fa = 'بلیت‌ها و رزرو';
														|it = 'Билеты и бронирование';
														|pl = 'Bilety i rezerwacja';
														|tr = 'Biletler ve rezervasyon'");
	DescriptionOfAccountingObject_.TitleOfTheInvoiceSetupTable = NStr("vi = 'Tài khoản kế toán công nợ tiền vé và đặt phòng';
																		|ru = 'Счета учета задолженности по билетам и бронированию';
																		|en = 'Ledger accounts of payables by tickets and booking'; fa = 'Ledger accounts of payables by tickets and booking';
																		|it = 'Счета учета задолженности по билетам и бронированию';
																		|pl = 'Konta księgowe zadłużenia według biletów i rezerwacji';
																		|tr = 'Biletler ve rezervasyona ilişkin borçların defterikebir hesabı'");
	DescriptionOfAccountingObject_.DescriptionOfTheConfigurationObjectTypes = New TypeDescription("CatalogRef.FinancialAccountingGroupsOfARAP");
	DescriptionOfAccountingObject_.SelectingConfigurationObjects = New Structure(DetailsOfHFCCalculations.BookingARAPAccounting.Name, True);
	DescriptionOfAccountingObject_.DescriptionOfTheAccountingLocationTypes = New TypeDescription();
	DescriptionOfAccountingObjectsForConfiguringForms.Insert(Enums.DeleteFinancialAccountingObjects.TicketsAndBooking, DescriptionOfAccountingObject_);
	
	DescriptionOfAccountingObject_ = DescriptionOfAccountingObjectForConfiguringForms();
	DescriptionOfAccountingObject_.Group = GroupsOfAccountingObjects.VendorsARAPAccounting;
	DescriptionOfAccountingObject_.Presentation = NStr("vi = 'Tỷ lệ phần trăm chiết khấu hạch toán';
														|ru = 'Проценты дисконтирования расчетов';
														|en = 'AR/AP discounting interest'; fa = 'سود تنزیل دریافتنی/پرداختنی';
														|it = 'Проценты дисконтирования расчетов';
														|pl = 'AR/AP discounting interest';
														|tr = 'Diskonto hesaplamalarının yüzdesi'");
	DescriptionOfAccountingObject_.TitleOfTheInvoiceSetupTable = NStr("vi = 'Tài khoản kế toán tỷ lệ phần trăm chiết khấu hạch toán';
																		|ru = 'Счета учета процентов дисконтирования расчетов';
																		|en = 'Ledger accounts of AR/AP discounting interest'; fa = 'Ledger accounts of AR/AP discounting interest';
																		|it = 'Счета учета процентов дисконтирования расчетов';
																		|pl = 'Ledger accounts of AR/AP discounting interest';
																		|tr = 'İskonto hesaplamalarının yüzdesinin defterikebir hesabı'");
	DescriptionOfAccountingObject_.DescriptionOfTheConfigurationObjectTypes = New TypeDescription("CatalogRef.FinancialAccountingGroupsOfARAP");
	DescriptionOfAccountingObject_.SelectingConfigurationObjects = SelectionOfFinancialAccountingGroupsForSettlementsWithSuppliers;
	DescriptionOfAccountingObject_.DescriptionOfTheAccountingLocationTypes = New TypeDescription();
	DescriptionOfAccountingObjectsForConfiguringForms.Insert(Enums.DeleteFinancialAccountingObjects.DiscountInterestExpense, DescriptionOfAccountingObject_);
	
	DescriptionOfAccountingObject_ = DescriptionOfAccountingObjectForConfiguringForms();
	DescriptionOfAccountingObject_.Group = GroupsOfAccountingObjects.VendorsARAPAccounting;
	DescriptionOfAccountingObject_.Presentation = NStr("vi = 'Nợ phải trả người nhận ký gửi theo dữ liệu bán hàng';
														|ru = 'Обязательства перед комитентом по реализованным товарам';
														|en = 'Liabilities to vendor for goods sold'; fa = 'بدهی‌ها به تأمین‌کننده بابت کالای فروخته‌شده';
														|it = 'Обязательства перед комитентом по реализованным товарам';
														|pl = 'Zobowiązania przed komitentem według realizowanych towarów';
														|tr = 'Uygulanmış ürünlere ilişkin göndericiye karşı sorumluluklar'");
	DescriptionOfAccountingObject_.TitleOfTheInvoiceSetupTable = NStr("vi = 'Tài khoản hạch toán nợ phải trả người đặt ký gửi theo dữ liệu bán hàng';
																		|ru = 'Счета учета обязательств перед комитентом по реализованным товарам';
																		|en = 'Ledger accounts of liabilities to vendor for goods sold'; fa = 'Ledger accounts of liabilities to vendor for goods sold';
																		|it = 'Счета учета обязательств перед комитентом по реализованным товарам';
																		|pl = 'Konta księgowe zobowiązań przed komitentem według realizowanych towarów';
																		|tr = 'Uygulanmış ürünlere ilişkin göndericiye karşı sorumlulukların defterikebir hesabı'");
	DescriptionOfAccountingObject_.DescriptionOfTheConfigurationObjectTypes = Undefined;
	DescriptionOfAccountingObject_.DescriptionOfTheAccountingLocationTypes = New TypeDescription();
	DescriptionOfAccountingObjectsForConfiguringForms.Insert(Enums.DeleteFinancialAccountingObjects.ObligationsToCommiteeForGoodsSold, DescriptionOfAccountingObject_);
	
	DescriptionOfAccountingObject_ = DescriptionOfAccountingObjectForConfiguringForms();
	DescriptionOfAccountingObject_.Group = GroupsOfAccountingObjects.VendorsARAPAccounting;
	DescriptionOfAccountingObject_.Presentation = NStr("vi = 'Nợ phải trả bên đặt ký gửi cho dịch vụ được cung cấp';
														|ru = 'Обязательства перед принципалом по реализованным услугам';
														|en = 'Liabilities to principal for services provided'; fa = 'بدهی‌ها به مالک بابت خدمات ارائه‌شده';
														|it = 'Обязательства перед принципалом по реализованным услугам';
														|pl = 'Zobowiązania przed zleceniodawcami według realizowanych usług';
														|tr = 'Uygulanmış ürünlere ilişkin müdüre karşı sorumluluklar'");
	DescriptionOfAccountingObject_.TitleOfTheInvoiceSetupTable = NStr("vi = 'Tài khoản hạch toán nợ với người đặt ký gửi theo dịch vụ đã cung cấp';
																		|ru = 'Счета учета обязательств перед принципалом по реализованным услугам';
																		|en = 'Ledger accounts of liabilities to principal for services sold'; fa = 'Ledger accounts of liabilities to principal for services sold';
																		|it = 'Счета учета обязательств перед принципалом по реализованным услугам';
																		|pl = 'Konta księgowe zobowiązań przed zleceniodawcą według realizowanych usług';
																		|tr = 'Uygulanmış ürünlere ilişkin müdüre karşı sorumlulukların defterikebir hesabı'");
	DescriptionOfAccountingObject_.DescriptionOfTheConfigurationObjectTypes = Undefined;
	DescriptionOfAccountingObject_.DescriptionOfTheAccountingLocationTypes = New TypeDescription();
	DescriptionOfAccountingObjectsForConfiguringForms.Insert(Enums.DeleteFinancialAccountingObjects.ObligationsToPrincipalForServicesProvided, DescriptionOfAccountingObject_);
	
	#EndRegion
	
	#Region LoansAndBorrowingsIssued
	
	DetailsSettlementsWithDebtors = Metadata.Catalogs.FinancialAccountingGroupsOfARAP.Attributes.DebtorsARAPAccounting.Name;
	SelectionOfFinancialAccountingGroupsSettlementsWithDebtors = New Structure(DetailsSettlementsWithDebtors, True);
	
	DescriptionOfAccountingObject_ = DescriptionOfAccountingObjectForConfiguringForms();
	DescriptionOfAccountingObject_.Group = GroupsOfAccountingObjects.LoansAndBorrowingsIssued;
	DescriptionOfAccountingObject_.Presentation = NStr("vi = 'Nợ gốc';
														|ru = 'Основной долг';
														|en = 'Principal debt'; fa = 'اصل بدهی';
														|it = 'Основной долг';
														|pl = 'Dług zasadniczy';
														|tr = 'Ana borç'");
	DescriptionOfAccountingObject_.TitleOfTheInvoiceSetupTable = NStr("vi = 'Tài khoản kế toán nợ gốc theo các khoản tín dụng và vay nợ đã chi';
																		|ru = 'Счета учета основного долга по кредитам и займам выданным';
																		|en = 'Ledger accounts of principal debt on issued credits and loans'; fa = 'Ledger accounts of principal debt on issued credits and loans';
																		|it = 'Счета учета основного долга по кредитам и займам выданным';
																		|pl = 'Konta księgowe podstawowego długu według wydanych kredytów i pożyczek';
																		|tr = 'Krediler ve verilen borçlara ilişkin anapara borcun defterikebir hesabı'");
	DescriptionOfAccountingObject_.DescriptionOfTheConfigurationObjectTypes = New TypeDescription("CatalogRef.FinancialAccountingGroupsOfARAP");
	DescriptionOfAccountingObject_.SelectingConfigurationObjects = SelectionOfFinancialAccountingGroupsSettlementsWithDebtors;
	DescriptionOfAccountingObject_.DescriptionOfTheAccountingLocationTypes = New TypeDescription();
	DescriptionOfAccountingObjectsForConfiguringForms.Insert(Enums.DeleteFinancialAccountingObjects.LoansAndBorrowingsIssuedDebt, DescriptionOfAccountingObject_);
	
	DescriptionOfAccountingObject_ = DescriptionOfAccountingObjectForConfiguringForms();
	DescriptionOfAccountingObject_.Group = GroupsOfAccountingObjects.LoansAndBorrowingsIssued;
	DescriptionOfAccountingObject_.Presentation = NStr("vi = 'Công nợ ký gửi';
														|ru = 'Задолженность по комиссии';
														|en = 'Commission debt'; fa = 'Commission debt';
														|it = 'Задолженность по комиссии';
														|pl = 'Zadłużenie z tytułu prowizji';
														|tr = 'Komisyona göre borç'");
	DescriptionOfAccountingObject_.TitleOfTheInvoiceSetupTable = NStr("vi = 'Tài khoản kế toán hoa hồng theo các khoản tín dụng và vay nợ đã chi';
																		|ru = 'Счета учета комиссии по кредитам и займам выданным';
																		|en = 'Ledger accounts of commission on issued credits and loans'; fa = 'Ledger accounts of commission on issued credits and loans';
																		|it = 'Счета учета комиссии по кредитам и займам выданным';
																		|pl = 'Konta księgowe prowizji według wydanych kredytów i pożyczek';
																		|tr = 'Krediler ve verilen borçlara ilişkin komisyonun defterikebir hesabı'");
	DescriptionOfAccountingObject_.DescriptionOfTheConfigurationObjectTypes = New TypeDescription("CatalogRef.FinancialAccountingGroupsOfARAP");
	DescriptionOfAccountingObject_.SelectingConfigurationObjects = SelectionOfFinancialAccountingGroupsSettlementsWithDebtors;
	DescriptionOfAccountingObject_.DescriptionOfTheAccountingLocationTypes = New TypeDescription();
	DescriptionOfAccountingObjectsForConfiguringForms.Insert(Enums.DeleteFinancialAccountingObjects.LoansAndBorrowingsIssuedFee, DescriptionOfAccountingObject_);
	
	DescriptionOfAccountingObject_ = DescriptionOfAccountingObjectForConfiguringForms();
	DescriptionOfAccountingObject_.Group = GroupsOfAccountingObjects.LoansAndBorrowingsIssued;
	DescriptionOfAccountingObject_.Presentation = NStr("vi = 'Nợ lãi';
														|ru = 'Процентная задолженность';
														|en = 'Interest on debt'; fa = 'Interest on debt';
														|it = 'Процентная задолженность';
														|pl = 'Dług odsetkowe';
														|tr = 'Yüzde borç'");
	DescriptionOfAccountingObject_.TitleOfTheInvoiceSetupTable = NStr("vi = 'Tài khoản kế toán lãi suất đã tính theo các khoản tín dụng và vay nợ đã chi';
																		|ru = 'Счета учета начисленных процентов  по кредитам и займам выданным';
																		|en = 'Ledger accounts of charged interest on issued credits and loans'; fa = 'Ledger accounts of charged interest on issued credits and loans';
																		|it = 'Счета учета начисленных процентов  по кредитам и займам выданным';
																		|pl = 'Konta księgowe naliczonych odsetek według wydanych kredytów i pożyczek';
																		|tr = 'Krediler ve verilen borçlara ilişkin yüzde tahakkukların defterikebir hesabı'");
	DescriptionOfAccountingObject_.DescriptionOfTheConfigurationObjectTypes = New TypeDescription("CatalogRef.FinancialAccountingGroupsOfARAP");
	DescriptionOfAccountingObject_.SelectingConfigurationObjects = SelectionOfFinancialAccountingGroupsSettlementsWithDebtors;
	DescriptionOfAccountingObject_.DescriptionOfTheAccountingLocationTypes = New TypeDescription();
	DescriptionOfAccountingObjectsForConfiguringForms.Insert(Enums.DeleteFinancialAccountingObjects.LoansAndBorrowingsIssuedInterest, DescriptionOfAccountingObject_);
	
	#EndRegion
	
	#Region LoansAndBorrowingsReceived
	
	DetailsSettlementsWithCreditors = Metadata.Catalogs.FinancialAccountingGroupsOfARAP.Attributes.CreditorsARAPAccounting.Name;
	SelectionOfFinancialAccountingGroupsSettlementsWithCreditors = New Structure(DetailsSettlementsWithCreditors, True);
	
	DescriptionOfAccountingObject_ = DescriptionOfAccountingObjectForConfiguringForms();
	DescriptionOfAccountingObject_.Group = GroupsOfAccountingObjects.LoansAndBorrowingsReceived;
	DescriptionOfAccountingObject_.Presentation = NStr("vi = 'Nợ gốc';
														|ru = 'Основной долг';
														|en = 'Principal debt'; fa = 'اصل بدهی';
														|it = 'Основной долг';
														|pl = 'Dług zasadniczy';
														|tr = 'Ana borç'");
	DescriptionOfAccountingObject_.TitleOfTheInvoiceSetupTable = NStr("vi = 'Tài khoản kế toán nợ gốc theo các khoản tín dụng và vay nợ đã nhận';
																		|ru = 'Счета учета основного долга по по кредитам и займам полученным';
																		|en = 'Ledger accounts of principal debt on received credits and loans'; fa = 'Ledger accounts of principal debt on received credits and loans';
																		|it = 'Счета учета основного долга по по кредитам и займам полученным';
																		|pl = 'Konta księgowe podstawowego długu według otrzymanych kredytów i pożyczek';
																		|tr = 'Krediler ve alınan borçlara ilişkin anapara borcun defterikebir hesabı'");
	DescriptionOfAccountingObject_.DescriptionOfTheConfigurationObjectTypes = New TypeDescription("CatalogRef.FinancialAccountingGroupsOfARAP");
	DescriptionOfAccountingObject_.SelectingConfigurationObjects = SelectionOfFinancialAccountingGroupsSettlementsWithCreditors;
	DescriptionOfAccountingObject_.DescriptionOfTheAccountingLocationTypes = New TypeDescription();
	DescriptionOfAccountingObjectsForConfiguringForms.Insert(Enums.DeleteFinancialAccountingObjects.LoansAndBorrowingsReceivedDebt, DescriptionOfAccountingObject_);
	
	DescriptionOfAccountingObject_ = DescriptionOfAccountingObjectForConfiguringForms();
	DescriptionOfAccountingObject_.Group = GroupsOfAccountingObjects.LoansAndBorrowingsReceived;
	DescriptionOfAccountingObject_.Presentation = NStr("vi = 'Công nợ ký gửi';
														|ru = 'Задолженность по комиссии';
														|en = 'Commission debt'; fa = 'Commission debt';
														|it = 'Задолженность по комиссии';
														|pl = 'Zadłużenie z tytułu prowizji';
														|tr = 'Komisyona göre borç'");
	DescriptionOfAccountingObject_.TitleOfTheInvoiceSetupTable = NStr("vi = 'Tài khoản kế toán ký gửi theo các khoản tín dụng và vay nợ đã nhận';
																		|ru = 'Счета учета комиссии по кредитам и займам полученным';
																		|en = 'Ledger accounts of commission on received credits and loans'; fa = 'Ledger accounts of commission on received credits and loans';
																		|it = 'Счета учета комиссии по кредитам и займам полученным';
																		|pl = 'Konta księgowe prowizji według otrzymanych kredytów i pożyczek';
																		|tr = 'Krediler ve alınan borçlara ilişkin komisyonun defterikebir hesabı'");
	DescriptionOfAccountingObject_.DescriptionOfTheConfigurationObjectTypes = New TypeDescription("CatalogRef.FinancialAccountingGroupsOfARAP");
	DescriptionOfAccountingObject_.SelectingConfigurationObjects = SelectionOfFinancialAccountingGroupsSettlementsWithCreditors;
	DescriptionOfAccountingObject_.DescriptionOfTheAccountingLocationTypes = New TypeDescription();
	DescriptionOfAccountingObjectsForConfiguringForms.Insert(Enums.DeleteFinancialAccountingObjects.LoansAndBorrowingsReceivedFee, DescriptionOfAccountingObject_);
	
	DescriptionOfAccountingObject_ = DescriptionOfAccountingObjectForConfiguringForms();
	DescriptionOfAccountingObject_.Group = GroupsOfAccountingObjects.LoansAndBorrowingsReceived;
	DescriptionOfAccountingObject_.Presentation = NStr("vi = 'Nợ lãi';
														|ru = 'Процентная задолженность';
														|en = 'Interest on debt'; fa = 'Interest on debt';
														|it = 'Процентная задолженность';
														|pl = 'Dług odsetkowe';
														|tr = 'Yüzde borç'");
	DescriptionOfAccountingObject_.TitleOfTheInvoiceSetupTable = NStr("vi = 'Tài khoản kế toán lãi suất đã tính theo các khoản tín dụng và vay nợ đã nhận';
																		|ru = 'Счета учета начисленных процентов  по кредитам и займам полученным';
																		|en = 'Ledger accounts of accrued interest on received credits and loans'; fa = 'Ledger accounts of accrued interest on received credits and loans';
																		|it = 'Счета учета начисленных процентов  по кредитам и займам полученным';
																		|pl = 'Konta księgowe naliczonych odsetek według otrzymanych kredytów i pożyczek';
																		|tr = 'Krediler ve alınan borçlara ilişkin yüzde tahakkukların defterikebir hesabı'");
	DescriptionOfAccountingObject_.DescriptionOfTheConfigurationObjectTypes = New TypeDescription("CatalogRef.FinancialAccountingGroupsOfARAP");
	DescriptionOfAccountingObject_.SelectingConfigurationObjects = SelectionOfFinancialAccountingGroupsSettlementsWithCreditors;
	DescriptionOfAccountingObject_.DescriptionOfTheAccountingLocationTypes = New TypeDescription();
	DescriptionOfAccountingObjectsForConfiguringForms.Insert(Enums.DeleteFinancialAccountingObjects.LoansAndBorrowingsInterestReceived, DescriptionOfAccountingObject_);
	
	#EndRegion
	
	#Region SettlementsWithEmployees
	
	DescriptionOfAccountingObject_ = DescriptionOfAccountingObjectForConfiguringForms();
	DescriptionOfAccountingObject_.Group = GroupsOfAccountingObjects.SettlementsWithEmployees;
	DescriptionOfAccountingObject_.Presentation = NStr("vi = 'Theo tiền lương';
														|ru = 'По заработной плате';
														|en = 'Payroll'; fa = 'حقوق و دستمزد';
														|it = 'По заработной плате';
														|pl = 'Wg wynagrodzenia';
														|tr = 'Bordro hesaplamasına ilişkin'");
	DescriptionOfAccountingObject_.TitleOfTheInvoiceSetupTable = NStr("vi = 'Tài khoản kế toán hạch toán tiền lương với nhân viên';
																		|ru = 'Счета учета расчетов с сотрудниками по зарплате';
																		|en = 'Ledger accounts of employee AR/AP for payroll'; fa = 'Ledger accounts of employee AR/AP for payroll';
																		|it = 'Счета учета расчетов с сотрудниками по зарплате';
																		|pl = 'Konta księgowe rozliczenia wynagrodzenia pracownikom';
																		|tr = 'Maaşa ilişkin çalışanlarla hesaplama defterikebir hesabı'");
	DescriptionOfAccountingObject_.DescriptionOfTheAccountingLocationTypes = New TypeDescription();
	DescriptionOfAccountingObjectsForConfiguringForms.Insert(Enums.DeleteFinancialAccountingObjects.PayrollAccountsPayable, DescriptionOfAccountingObject_);
	
	DescriptionOfAccountingObject_ = DescriptionOfAccountingObjectForConfiguringForms();
	DescriptionOfAccountingObject_.Group = GroupsOfAccountingObjects.SettlementsWithEmployees;
	DescriptionOfAccountingObject_.Presentation = NStr("vi = 'Với người nhận tạm ứng';
														|ru = 'С подотчетниками';
														|en = 'With advance holders'; fa = 'With advance holders';
														|it = 'С подотчетниками';
														|pl = 'Z zaliczkobiorcami';
														|tr = 'Avans sahibi ile'");
	DescriptionOfAccountingObject_.TitleOfTheInvoiceSetupTable = NStr("vi = 'Tài khoản kế toán hạch toán với người nhận tạm ứng';
																		|ru = 'Счета учета расчетов с подотчетными лицами';
																		|en = 'Ledger accounts of AR/AP accounting for advance holders'; fa = 'Ledger accounts of AR/AP accounting for advance holders';
																		|it = 'Счета учета расчетов с подотчетными лицами';
																		|pl = 'Konta księgowe rozliczeni z zaliczkobiorcami';
																		|tr = 'Avans sahibi ile hesaplama defterikebir hesabı'");
	DescriptionOfAccountingObject_.DescriptionOfTheAccountingLocationTypes = New TypeDescription();
	DescriptionOfAccountingObjectsForConfiguringForms.Insert(Enums.DeleteFinancialAccountingObjects.AdvanceHoldersARAPAccounting, DescriptionOfAccountingObject_);
	
	DescriptionOfAccountingObject_ = DescriptionOfAccountingObjectForConfiguringForms();
	DescriptionOfAccountingObject_.Group = GroupsOfAccountingObjects.SettlementsWithEmployees;
	DescriptionOfAccountingObject_.Presentation = NStr("vi = 'Hạch toán theo các khoản vay đã chi';
														|ru = 'Расчеты по выданным займам';
														|en = 'AR/AP accounting for loans issued'; fa = 'AR/AP accounting for loans issued';
														|it = 'Расчеты по выданным займам';
														|pl = 'Rozliczenia z tytułu wydanych pożyczek';
														|tr = 'Verilen borçlara ilişkin hesaplar'");
	DescriptionOfAccountingObject_.TitleOfTheInvoiceSetupTable = NStr("vi = 'Tài khoản kế toán hạch toán tiền vay với nhân viên';
																		|ru = 'Счета учета расчетов с сотрудниками по займам';
																		|en = 'Ledger accounts of employee AR/AP for loans'; fa = 'Ledger accounts of employee AR/AP for loans';
																		|it = 'Счета учета расчетов с сотрудниками по займам';
																		|pl = 'Konta księgowe rozliczeń z pracownikami z tytułu pożyczek';
																		|tr = 'Borçlara ilişkin çalışanlarla hesaplama defterikebir hesabı'");
	DescriptionOfAccountingObject_.DescriptionOfTheAccountingLocationTypes = New TypeDescription();
	DescriptionOfAccountingObjectsForConfiguringForms.Insert(Enums.DeleteFinancialAccountingObjects.EmployeeARAPAccounting, DescriptionOfAccountingObject_);
	
	#EndRegion
	
	#Region ExpendableRent
	
	DetailsSettlementsWithLandlords = Metadata.Catalogs.FinancialAccountingGroupsOfARAP.Attributes.LeaseContractARAPWithLessors.Name;
	SelectionOfFinancialAccountingGroupsSettlementsWithLandlords = New Structure(DetailsSettlementsWithLandlords, True);
	
	DescriptionOfAccountingObject_ = DescriptionOfAccountingObjectForConfiguringForms();
	DescriptionOfAccountingObject_.Group = GroupsOfAccountingObjects.ExpendableRent;
	DescriptionOfAccountingObject_.Presentation = NStr("vi = 'Thanh toán đảm bảo';
														|ru = 'Обеспечительный платеж';
														|en = 'Security deposit'; fa = 'سپرده تضمین';
														|it = 'Обеспечительный платеж';
														|pl = 'Płatność zabezpieczająca';
														|tr = 'Teminat ödemesi'");
	DescriptionOfAccountingObject_.TitleOfTheInvoiceSetupTable = NStr("vi = 'Tài khoản kế toán hạch toán tiền thanh toán đảm bảo';
																		|ru = 'Счета учета расчетов по обеспечительным платежам';
																		|en = 'Ledger accounts of AR/AP accounting for security deposits'; fa = 'Ledger accounts of AR/AP accounting for security deposits';
																		|it = 'Счета учета расчетов по обеспечительным платежам';
																		|pl = 'Konta księgowe rozliczeń z tytułu płatności zabezpieczających';
																		|tr = 'Kira güvence ödemesine ilişkin hesapların defterikebir hesabı'");
	DescriptionOfAccountingObject_.DescriptionOfTheConfigurationObjectTypes = New TypeDescription("CatalogRef.FinancialAccountingGroupsOfARAP");
	DescriptionOfAccountingObject_.SelectingConfigurationObjects = SelectionOfFinancialAccountingGroupsSettlementsWithLandlords;
	DescriptionOfAccountingObject_.DescriptionOfTheAccountingLocationTypes = New TypeDescription();
	DescriptionOfAccountingObjectsForConfiguringForms.Insert(Enums.DeleteFinancialAccountingObjects.SecurityPaymentForLease, DescriptionOfAccountingObject_);
	
	DescriptionOfAccountingObject_ = DescriptionOfAccountingObjectForConfiguringForms();
	DescriptionOfAccountingObject_.Group = GroupsOfAccountingObjects.ExpendableRent;
	DescriptionOfAccountingObject_.Presentation = NStr("vi = 'Dịch vụ thuê';
														|ru = 'Услуги по аренде';
														|en = 'Rental services'; fa = 'خدمات اجاره';
														|it = 'Услуги по аренде';
														|pl = 'Usługi dotyczące dzierżawy';
														|tr = 'Kiralama hizmetleri'");
	DescriptionOfAccountingObject_.TitleOfTheInvoiceSetupTable = NStr("vi = 'Tài khoản kế toán hạch toán tiền dịch vụ thuê';
																		|ru = 'Счета учета расчетов по услугам аренды';
																		|en = 'Ledger accounts of AR/AP accounting for rental services'; fa = 'Ledger accounts of AR/AP accounting for rental services';
																		|it = 'Счета учета расчетов по услугам аренды';
																		|pl = 'Konta księgowe rozliczeń z tytułu usług dzierżawy';
																		|tr = 'Kiralama hizmetlerine ilişkin defterikebir hesabı'");
	DescriptionOfAccountingObject_.DescriptionOfTheConfigurationObjectTypes = New TypeDescription("CatalogRef.FinancialAccountingGroupsOfARAP");
	DescriptionOfAccountingObject_.SelectingConfigurationObjects = SelectionOfFinancialAccountingGroupsSettlementsWithLandlords;
	DescriptionOfAccountingObject_.DescriptionOfTheAccountingLocationTypes = New TypeDescription();
	DescriptionOfAccountingObjectsForConfiguringForms.Insert(Enums.DeleteFinancialAccountingObjects.RentalServices, DescriptionOfAccountingObject_);
	
	DescriptionOfAccountingObject_ = DescriptionOfAccountingObjectForConfiguringForms();
	DescriptionOfAccountingObject_.Group = GroupsOfAccountingObjects.ExpendableRent;
	DescriptionOfAccountingObject_.Presentation = NStr("vi = 'Nợ tiền thuê';
														|ru = 'Арендные обязательства';
														|en = 'Rental obligations'; fa = 'تعهدات اجاره';
														|it = 'Арендные обязательства';
														|pl = 'Zobowiązania dzierżawne';
														|tr = 'Kiralama yükümlülükleri'");
	DescriptionOfAccountingObject_.TitleOfTheInvoiceSetupTable = NStr("vi = 'Tài khoản hạch toán tiền thuê';
																		|ru = 'Счета учета расчетов  по арендным  обязательствам';
																		|en = 'Ledger accounts of AR/AP accounting for rental obligations'; fa = 'Ledger accounts of AR/AP accounting for rental obligations';
																		|it = 'Счета учета расчетов  по арендным  обязательствам';
																		|pl = 'Konta księgowe rozliczeń z tytułu zobowiązań dzierżawnych';
																		|tr = 'Kira yükümlülüğüne ilişkin hesaplamaların defterikebir hesabı'");
	DescriptionOfAccountingObject_.DescriptionOfTheConfigurationObjectTypes = New TypeDescription("CatalogRef.FinancialAccountingGroupsOfARAP");
	DescriptionOfAccountingObject_.SelectingConfigurationObjects = SelectionOfFinancialAccountingGroupsSettlementsWithLandlords;
	DescriptionOfAccountingObject_.DescriptionOfTheAccountingLocationTypes = New TypeDescription();
	DescriptionOfAccountingObjectsForConfiguringForms.Insert(Enums.DeleteFinancialAccountingObjects.LeaseObligations, DescriptionOfAccountingObject_);
	
	DescriptionOfAccountingObject_ = DescriptionOfAccountingObjectForConfiguringForms();
	DescriptionOfAccountingObject_.Group = GroupsOfAccountingObjects.ExpendableRent;
	DescriptionOfAccountingObject_.Presentation = NStr("vi = 'Mua lại đối tượng thuê';
														|ru = 'Выкуп предмета аренды';
														|en = 'Rental object redemption'; fa = 'Rental object redemption';
														|it = 'Выкуп предмета аренды';
														|pl = 'Wykup przedmiotu dzierżawy';
														|tr = 'Kiralanan varlığın itfası'");
	DescriptionOfAccountingObject_.TitleOfTheInvoiceSetupTable = NStr("vi = 'Tài khoản kế toán hạch toán mua lại đối tượng thuê';
																		|ru = 'Счета учета расчетов по выкупу предмета аренды';
																		|en = 'Ledger accounts of rental buyback AR/AP'; fa = 'Ledger accounts of rental buyback AR/AP';
																		|it = 'Счета учета расчетов по выкупу предмета аренды';
																		|pl = 'Konta księgowe rozliczeń według wykupu przedmiotu dzierżawy';
																		|tr = 'Kiralanan varlığın itfası hesaplama defterikebir hesabı'");
	DescriptionOfAccountingObject_.DescriptionOfTheConfigurationObjectTypes = New TypeDescription("CatalogRef.FinancialAccountingGroupsOfARAP");
	DescriptionOfAccountingObject_.SelectingConfigurationObjects = SelectionOfFinancialAccountingGroupsSettlementsWithLandlords;
	DescriptionOfAccountingObject_.DescriptionOfTheAccountingLocationTypes = New TypeDescription();
	DescriptionOfAccountingObjectsForConfiguringForms.Insert(Enums.DeleteFinancialAccountingObjects.LeaseBuyoutValue, DescriptionOfAccountingObject_);
	
	DescriptionOfAccountingObject_ = DescriptionOfAccountingObjectForConfiguringForms();
	DescriptionOfAccountingObject_.Group = GroupsOfAccountingObjects.ExpendableRent;
	DescriptionOfAccountingObject_.Presentation = NStr("vi = 'Ứng trước để mua lại đối tượng thuê';
														|ru = 'Аванс за выкуп предмета аренды';
														|en = 'Prepayment for rental object redemption'; fa = 'Prepayment for rental object redemption';
														|it = 'Аванс за выкуп предмета аренды';
														|pl = 'Zaliczka za wykup przedmiotu dzierżawy';
														|tr = 'Kiralanan varlığı satın almanın avansı'");
	DescriptionOfAccountingObject_.TitleOfTheInvoiceSetupTable = NStr("vi = 'Tài khoản hạch toán ứng trước để mua lại đối tượng thuê';
																		|ru = 'Счета учета расчетов по авансам за выкуп предмета аренды';
																		|en = 'Ledger accounts of AR/AP for rental buyback prepayments'; fa = 'Ledger accounts of AR/AP for rental buyback prepayments';
																		|it = 'Счета учета расчетов по авансам за выкуп предмета аренды';
																		|pl = 'Konta księgowe rozliczeń według zaliczek za wykup przedmiotu dzierżawy';
																		|tr = 'Kiralanan varlığı satın almanın avansını hesaplama defterikebir hesabı'");
	DescriptionOfAccountingObject_.DescriptionOfTheConfigurationObjectTypes = New TypeDescription("CatalogRef.FinancialAccountingGroupsOfARAP");
	DescriptionOfAccountingObject_.SelectingConfigurationObjects = SelectionOfFinancialAccountingGroupsSettlementsWithLandlords;
	DescriptionOfAccountingObject_.DescriptionOfTheAccountingLocationTypes = New TypeDescription();
	DescriptionOfAccountingObjectsForConfiguringForms.Insert(Enums.DeleteFinancialAccountingObjects.PrepaymentLeaseBuyoutValue, DescriptionOfAccountingObject_);
	
	DescriptionOfAccountingObject_ = DescriptionOfAccountingObjectForConfiguringForms();
	DescriptionOfAccountingObject_.Group = GroupsOfAccountingObjects.ExpendableRent;
	DescriptionOfAccountingObject_.Presentation = NStr("vi = 'Lãi tiền thuê';
														|ru = 'Проценты по аренде';
														|en = 'Rental interest'; fa = 'سود اجاره';
														|it = 'Проценты по аренде';
														|pl = 'Odsetki z tytułu dzierżawy';
														|tr = 'Kiraya ilişkin yüzde'");
	DescriptionOfAccountingObject_.TitleOfTheInvoiceSetupTable = NStr("vi = 'Tài khoản hạch toán lãi tiền thuê';
																		|ru = 'Счета учета расчетов по процентам по аренде';
																		|en = 'Ledger accounts of AR/AP accounting for rental interest'; fa = 'Ledger accounts of AR/AP accounting for rental interest';
																		|it = 'Счета учета расчетов по процентам по аренде';
																		|pl = 'Konta księgowe rozliczeń według odsetek z dzierżawy';
																		|tr = 'Kiraya ilişkin yüzde hesaplamaların defterikebir hesabı'");
	DescriptionOfAccountingObject_.DescriptionOfTheConfigurationObjectTypes = New TypeDescription("CatalogRef.FinancialAccountingGroupsOfARAP");
	DescriptionOfAccountingObject_.SelectingConfigurationObjects = SelectionOfFinancialAccountingGroupsSettlementsWithLandlords;
	DescriptionOfAccountingObject_.DescriptionOfTheAccountingLocationTypes = New TypeDescription();
	DescriptionOfAccountingObjectsForConfiguringForms.Insert(Enums.DeleteFinancialAccountingObjects.RentalInterest, DescriptionOfAccountingObject_);
	
	DescriptionOfAccountingObject_ = DescriptionOfAccountingObjectForConfiguringForms();
	DescriptionOfAccountingObject_.Group = GroupsOfAccountingObjects.ExpendableRent;
	DescriptionOfAccountingObject_.Presentation = NStr("vi = 'Thuế GTGT tiền thuê';
														|ru = 'НДС по аренде';
														|en = 'Rental VAT'; fa = 'مالیات بر ارزش افزوده اجاره';
														|it = 'НДС по аренде';
														|pl = 'VAT z dzierżawy';
														|tr = 'Kiraya ilişkin KDV'");
	DescriptionOfAccountingObject_.TitleOfTheInvoiceSetupTable = NStr("vi = 'Tài khoản hạch toán thuế GTGT tiền thuê';
																		|ru = 'Счета учета расчетов по НДС по аренде';
																		|en = 'Ledger accounts of AR/AP accounting for rental VAT'; fa = 'Ledger accounts of AR/AP accounting for rental VAT';
																		|it = 'Счета учета расчетов по НДС по аренде';
																		|pl = 'Konto księgowe rozliczeń z VAT według dzierżawy';
																		|tr = 'Kiraya ilişkin KDV hesaplamaların defterikebir hesabı'");
	DescriptionOfAccountingObject_.DescriptionOfTheConfigurationObjectTypes = New TypeDescription("CatalogRef.FinancialAccountingGroupsOfARAP");
	DescriptionOfAccountingObject_.SelectingConfigurationObjects = SelectionOfFinancialAccountingGroupsSettlementsWithLandlords;
	DescriptionOfAccountingObject_.DescriptionOfTheAccountingLocationTypes = New TypeDescription();
	DescriptionOfAccountingObjectsForConfiguringForms.Insert(Enums.DeleteFinancialAccountingObjects.VATForLease, DescriptionOfAccountingObject_);
	
	#EndRegion

	#Region ProfitableRent
	
	DetailsAssetType = Metadata.Catalogs.NonCurrentAssetsAccountingGroups.Attributes.AssetKind.Name;
	ArrayOfAssetTypes = New Array;
	ArrayOfAssetTypes.Add(Enums.KindsOfNonCurrentAssets.FixedAsset);
	ArrayOfAssetTypes.Add(Enums.KindsOfNonCurrentAssets.InvestmentProperty);
	ArrayOfAssetTypes.Add(Enums.KindsOfNonCurrentAssets.FixedAssetsProvidedToLessee);
	SelectionOfFinancialAccountingGroupsFA = New Structure(DetailsAssetType, ArrayOfAssetTypes);
	
	DescriptionOfAccountingObject_ = DescriptionOfAccountingObjectForConfiguringForms();
	DescriptionOfAccountingObject_.Group = GroupsOfAccountingObjects.ProfitableRent;
	DescriptionOfAccountingObject_.Presentation = NStr("vi = 'Thanh toán tiền thuê';
														|ru = 'Арендные платежи';
														|en = 'Rental payments'; fa = 'اجاره‌بها';
														|it = 'Арендные платежи';
														|pl = 'Płatności dzierżawne';
														|tr = 'Kira ödemeleri'");
	DescriptionOfAccountingObject_.TitleOfTheInvoiceSetupTable = NStr("vi = 'Tài sản hạch toán tiền thuê theo thuê tài chính';
																		|ru = 'Счета учета арендных платежей по финансовой аренде';
																		|en = 'Ledger accounts of rental payments for financial lease'; fa = 'Ledger accounts of rental payments for financial lease';
																		|it = 'Счета учета арендных платежей по финансовой аренде';
																		|pl = 'Ledger accounts of rental payments for financial lease';
																		|tr = 'Finansal kiralama kapsamında kira ödemelerinin defterikebir hesabı'");
	DescriptionOfAccountingObject_.DescriptionOfTheConfigurationObjectTypes = New TypeDescription("CatalogRef.NonCurrentAssetsAccountingGroups");
	DescriptionOfAccountingObject_.SelectingConfigurationObjects = SelectionOfFinancialAccountingGroupsFA;
	DescriptionOfAccountingObject_.DescriptionOfTheAccountingLocationTypes = New TypeDescription("CatalogRef.BusinessStructure");
	DescriptionOfAccountingObjectsForConfiguringForms.Insert(Enums.DeleteFinancialAccountingObjects.RentalPayments, DescriptionOfAccountingObject_);
	
	DescriptionOfAccountingObject_ = DescriptionOfAccountingObjectForConfiguringForms();
	DescriptionOfAccountingObject_.Group = GroupsOfAccountingObjects.ProfitableRent;
	DescriptionOfAccountingObject_.Presentation = NStr("vi = 'Giá trị thanh lý không được đảm bảo';
														|ru = 'Негарантированная ликвидационная стоимость';
														|en = 'Non-guaranteed residual value'; fa = 'ارزش باقی‌مانده تضمین‌نشده';
														|it = 'Негарантированная ликвидационная стоимость';
														|pl = 'Non-guaranteed residual value';
														|tr = 'Garanti edilmeyen artık değer'");
	DescriptionOfAccountingObject_.TitleOfTheInvoiceSetupTable = NStr("vi = 'Tài khoản hạch toán giá trị thanh lý không được đảm bảo';
																		|ru = 'Счета учета негарантированной ликвидационной стоимости';
																		|en = 'Ledger accounts of non-guaranteed residual value'; fa = 'Ledger accounts of non-guaranteed residual value';
																		|it = 'Счета учета негарантированной ликвидационной стоимости';
																		|pl = 'Ledger accounts of non-guaranteed residual value';
																		|tr = 'Garanti edilmeyen artık değerin defterikebir hesabı'");
	DescriptionOfAccountingObject_.DescriptionOfTheConfigurationObjectTypes = New TypeDescription("CatalogRef.NonCurrentAssetsAccountingGroups");
	DescriptionOfAccountingObject_.SelectingConfigurationObjects = SelectionOfFinancialAccountingGroupsFA;
	DescriptionOfAccountingObject_.DescriptionOfTheAccountingLocationTypes = New TypeDescription("CatalogRef.BusinessStructure");
	DescriptionOfAccountingObjectsForConfiguringForms.Insert(Enums.DeleteFinancialAccountingObjects.NonGuaranteedResidualValueFinancialLease, DescriptionOfAccountingObject_);
	
	DescriptionOfAccountingObject_ = DescriptionOfAccountingObjectForConfiguringForms();
	DescriptionOfAccountingObject_.Group = GroupsOfAccountingObjects.ProfitableRent;
	DescriptionOfAccountingObject_.Presentation = NStr("vi = 'Phần trăm chiết khấu thanh toán';
														|ru = 'Проценты дисконтирования платежей';
														|en = 'Payment discounting interest'; fa = 'Payment discounting interest';
														|it = 'Проценты дисконтирования платежей';
														|pl = 'Payment discounting interest';
														|tr = 'Ödemelerin iskonto yüzdesi'");
	DescriptionOfAccountingObject_.TitleOfTheInvoiceSetupTable = NStr("vi = 'Tài khoản hạch toán phần trăm chiết khấu thanh toán tiền thuê';
																		|ru = 'Счета учета процентов дисконтирования арендных платежей';
																		|en = 'Ledger accounts of rental payment discounting interest'; fa = 'Ledger accounts of rental payment discounting interest';
																		|it = 'Счета учета процентов дисконтирования арендных платежей';
																		|pl = 'Ledger accounts of rental payment discounting interest';
																		|tr = 'Kira ödemelerinin iskonto yüzdesinin defterikebir hesabı'");
	DescriptionOfAccountingObject_.DescriptionOfTheConfigurationObjectTypes = New TypeDescription("CatalogRef.NonCurrentAssetsAccountingGroups");
	DescriptionOfAccountingObject_.SelectingConfigurationObjects = SelectionOfFinancialAccountingGroupsFA;
	DescriptionOfAccountingObject_.DescriptionOfTheAccountingLocationTypes = New TypeDescription("CatalogRef.BusinessStructure");
	DescriptionOfAccountingObjectsForConfiguringForms.Insert(Enums.DeleteFinancialAccountingObjects.InterestOnDiscountingRentalPaymentsFinancialLease, DescriptionOfAccountingObject_);
	
	#EndRegion

	#Region WorkInProgress
	
	DescriptionOfAccountingObject_ = DescriptionOfAccountingObjectForConfiguringForms();
	DescriptionOfAccountingObject_.Group = GroupsOfAccountingObjects.WorkInProgress;
	DescriptionOfAccountingObject_.Presentation = NStr("vi = 'Chi phí nguyên vật liệu và nhân công';
														|ru = 'Материальные затраты и работы';
														|en = 'Material costs and works'; fa = 'Material costs and works';
														|it = 'Материальные затраты и работы';
														|pl = 'Koszty materialne i prace';
														|tr = 'Malzeme giderleri ve iş'");
	DescriptionOfAccountingObject_.TitleOfTheInvoiceSetupTable = NStr("vi = 'Tài khoản hạch toán chi phí nguyên vật liệu và nhân công trong sản xuất dở dang';
																		|ru = 'Счета учета материалов и работ в незавершенном производстве';
																		|en = 'Ledger accounts of materials and works in work-in-progress'; fa = 'Ledger accounts of materials and works in work-in-progress';
																		|it = 'Счета учета материалов и работ в незавершенном производстве';
																		|pl = 'Konta księgowe materiałów i prac w produkcji niezakończonej';
																		|tr = 'Devam eden imalatta malzeme ve işlerin defterikebir hesabı'");
	DescriptionOfAccountingObject_.DescriptionOfTheConfigurationObjectTypes = New TypeDescription("CatalogRef.AnalyticalInventoryGroups");
	DescriptionOfAccountingObject_.DescriptionOfTheAccountingLocationTypes = New TypeDescription("CatalogRef.BusinessStructure");
	DescriptionOfAccountingObjectsForConfiguringForms.Insert(Enums.DeleteFinancialAccountingObjects.MaterialsAndWorksInProgress, DescriptionOfAccountingObject_);
	
	DescriptionOfAccountingObject_ = DescriptionOfAccountingObjectForConfiguringForms();
	DescriptionOfAccountingObject_.Group = GroupsOfAccountingObjects.WorkInProgress;
	DescriptionOfAccountingObject_.Presentation = NStr("vi = 'Công lao động';
														|ru = 'Трудозатраты';
														|en = 'Labor costs'; fa = 'هزینه‌های دستمزد';
														|it = 'Трудозатраты';
														|pl = 'Labor costs';
														|tr = 'İş gücü maliyetleri'");
	DescriptionOfAccountingObject_.TitleOfTheInvoiceSetupTable = NStr("vi = 'Tài khoản hạch toán chi phí nhân công trong sản xuất dở dang';
																		|ru = 'Счета учета трудозатрат в незавершенном производстве';
																		|en = 'Ledger accounts of WIP labor costs'; fa = 'Ledger accounts of WIP labor costs';
																		|it = 'Счета учета трудозатрат в незавершенном производстве';
																		|pl = 'Konta księgowe nakładów pracy w niezakończonej produkcji';
																		|tr = 'Devam eden imalatta iş gücü maliyetleri defterikebir hesabı'");
	DescriptionOfAccountingObject_.DescriptionOfTheConfigurationObjectTypes = New TypeDescription("CatalogRef.AnalyticalInventoryGroups");
	DescriptionOfAccountingObject_.DescriptionOfTheAccountingLocationTypes = New TypeDescription("CatalogRef.BusinessStructure");
	DescriptionOfAccountingObjectsForConfiguringForms.Insert(Enums.DeleteFinancialAccountingObjects.LaborCostsInWorkInProgress, DescriptionOfAccountingObject_);
	
	DescriptionOfAccountingObject_ = DescriptionOfAccountingObjectForConfiguringForms();
	DescriptionOfAccountingObject_.Group = GroupsOfAccountingObjects.WorkInProgress;
	DescriptionOfAccountingObject_.Presentation = NStr("vi = 'Chi phí khác';
														|ru = 'Прочие затраты';
														|en = 'Other costs'; fa = 'سایر هزینه‌ها';
														|it = 'Прочие затраты';
														|pl = 'Pozostałe koszty';
														|tr = 'Diğer giderler'");
	DescriptionOfAccountingObject_.TitleOfTheInvoiceSetupTable = NStr("vi = 'Tài khoản hạch toán chi phí khác trong sản xuất dở dang';
																		|ru = 'Счета учета прочих затрат в незавершенном производстве';
																		|en = 'Ledger accounts of other expenses in work-in-progress'; fa = 'Ledger accounts of other expenses in work-in-progress';
																		|it = 'Счета учета прочих затрат в незавершенном производстве';
																		|pl = 'Konta księgowe pozostałych kosztów w niezakończonej produkcji';
																		|tr = 'Devam eden imalatta diğer giderlerin defterikebir hesabı'");
	DescriptionOfAccountingObject_.DescriptionOfTheConfigurationObjectTypes = New TypeDescription("CatalogRef.AnalyticalInventoryGroups");
	DescriptionOfAccountingObject_.DescriptionOfTheAccountingLocationTypes = New TypeDescription("CatalogRef.BusinessStructure");
	DescriptionOfAccountingObjectsForConfiguringForms.Insert(Enums.DeleteFinancialAccountingObjects.ItemizedCostsInWorkInProgress, DescriptionOfAccountingObject_);
	
	If TransactionSettings.MethodOfAccountingForImproperValues <> Enums.MethodsOfNotOwnedControlledValuesAccounting.NotRecordedOnAccounts
	   And TransactionSettings.MethodOfAccountingForImproperValues <> Enums.MethodsOfNotOwnedControlledValuesAccounting.EmptyRef() Then
		DescriptionOfAccountingObject_ = DescriptionOfAccountingObjectForConfiguringForms();
		DescriptionOfAccountingObject_.Group = GroupsOfAccountingObjects.WorkInProgress;
		DescriptionOfAccountingObject_.Presentation = NStr("vi = 'Nguyên vật liệu được tiếp nhận vào gia công';
															|ru = 'Материалы принятые в переработку';
															|en = 'Materials received for subcontracting'; fa = 'مواد دریافت‌شده برای پیمانکاری فرعی';
															|it = 'Материалы принятые в переработку';
															|pl = 'Materiały przyjęte do przetwarzania';
															|tr = 'Geri dönüşüme alınan malzemeler'");
		DescriptionOfAccountingObject_.TitleOfTheInvoiceSetupTable = NStr("vi = 'Tài khoản kế toán nguyên vật liệu được tiếp nhận vào gia công để sản xuất dở dang';
																			|ru = 'Счета учета материалов принятых в переработку в незавершенном производстве';
																			|en = 'Ledger accounts of materials for subcontracting in work-in-progress'; fa = 'Ledger accounts of materials for subcontracting in work-in-progress';
																			|it = 'Счета учета материалов принятых в переработку в незавершенном производстве';
																			|pl = 'Konta księgowe materiałów przyjętych do przetwarzania w produkcji niezakończonej';
																			|tr = 'Devam eden imalatta yeniden işlemek için kabul edilmiş ürünlerin defterikebir hesabı'");
		DescriptionOfAccountingObject_.DescriptionOfTheConfigurationObjectTypes = New TypeDescription("CatalogRef.AnalyticalInventoryGroups");
		DescriptionOfAccountingObject_.DescriptionOfTheAccountingLocationTypes = New TypeDescription("CatalogRef.BusinessStructure");
		DescriptionOfAccountingObjectsForConfiguringForms.Insert(Enums.DeleteFinancialAccountingObjects.ItemReceivedForSubcontractingInProduction, DescriptionOfAccountingObject_);
		
		DescriptionOfAccountingObject_ = DescriptionOfAccountingObjectForConfiguringForms();
		DescriptionOfAccountingObject_.Group = GroupsOfAccountingObjects.WorkInProgress;
		DescriptionOfAccountingObject_.Presentation = NStr("vi = 'Hàng hóa được tiếp nhận vào lưu kho';
															|ru = 'Товары принятые на хранение';
															|en = 'Vendor-managed inventory'; fa = 'موجودی تحت مدیریت فروشنده';
															|it = 'Товары принятые на хранение';
															|pl = 'Towary przyjęte do przechowania';
															|tr = 'Saklamak için kabul edilen ürünler'");
		DescriptionOfAccountingObject_.TitleOfTheInvoiceSetupTable = NStr("vi = 'Tài khoản kế toán hàng hóa được tiếp nhận vào lưu kho để sản xuất dở dang';
																			|ru = 'Счета учета товаров принятых на хранение в незавершенном производстве';
																			|en = 'Ledger accounts of vendor-managed inventory in work-in-progress'; fa = 'Ledger accounts of vendor-managed inventory in work-in-progress';
																			|it = 'Счета учета товаров принятых на хранение в незавершенном производстве';
																			|pl = 'Konta księgowe towarów przyjętych do przechowywania w produkcji niezakończonej';
																			|tr = 'Devam eden imalatta saklamak için kabul edilmiş ürünlerin defterikebir hesabı'");
		DescriptionOfAccountingObject_.DescriptionOfTheConfigurationObjectTypes = New TypeDescription("CatalogRef.AnalyticalInventoryGroups");
		DescriptionOfAccountingObject_.DescriptionOfTheAccountingLocationTypes = New TypeDescription("CatalogRef.BusinessStructure");
		DescriptionOfAccountingObjectsForConfiguringForms.Insert(Enums.DeleteFinancialAccountingObjects.ItemReceivedForStorageInProduction, DescriptionOfAccountingObject_);
	EndIf;
	
	#EndRegion

	#Region IncomeAndExpenses
	
	If TransactionSettings.RevenueExcludingVAT = False
	 Or TransactionSettings.RevenueExcludingVAT = Undefined Then
		DescriptionOfAccountingObject_ = DescriptionOfAccountingObjectForConfiguringForms();
		DescriptionOfAccountingObject_.Group = GroupsOfAccountingObjects.IncomeAndExpenses;
		DescriptionOfAccountingObject_.Presentation = NStr("vi = 'Doanh thu gồm thuế GTGT từ bán hàng và dịch vụ';
															|ru = 'Выручка с НДС от продаж товаров и услуг';
															|en = 'Goods and service sales revenue including VAT'; fa = 'Goods and service sales revenue including VAT';
															|it = 'Выручка с НДС от продаж товаров и услуг';
															|pl = 'Przychody brutto od sprzedaży towarów i usług';
															|tr = 'Ürün ve hizmet satışından KDV geliri'");
		DescriptionOfAccountingObject_.TitleOfTheInvoiceSetupTable = NStr("vi = 'Tài khoản hạch toán doanh thu từ bán hàng hóa và dịch vụ';
																			|ru = 'Счета учета выручки от продаж товаров и услуг';
																			|en = 'Ledger accounts of revenue from sales of goods and services'; fa = 'Ledger accounts of revenue from sales of goods and services';
																			|it = 'Счета учета выручки от продаж товаров и услуг';
																			|pl = 'Konta księgowe przychodu od sprzedaży towarów i usług';
																			|tr = 'Ürün ve hizmet satışından gelirin defterikebir hesabı'");
		DescriptionOfAccountingObject_.DescriptionOfTheConfigurationObjectTypes = New TypeDescription("CatalogRef.InventoryAccountingGroups");
		DescriptionOfAccountingObject_.DescriptionOfTheAccountingLocationTypes = New TypeDescription();
		DescriptionOfAccountingObjectsForConfiguringForms.Insert(Enums.DeleteFinancialAccountingObjects.SalesRevenue, DescriptionOfAccountingObject_);
	EndIf;
	
	If TransactionSettings.RevenueExcludingVAT = True
	 Or TransactionSettings.RevenueExcludingVAT = Undefined Then
		DescriptionOfAccountingObject_ = DescriptionOfAccountingObjectForConfiguringForms();
		DescriptionOfAccountingObject_.Group = GroupsOfAccountingObjects.IncomeAndExpenses;
		DescriptionOfAccountingObject_.Presentation = NStr("vi = 'Doanh thu từ bán hàng hóa và dịch vụ';
															|ru = 'Выручка от продаж товаров и услуг';
															|en = 'Revenue from sales of goods and services'; fa = 'Revenue from sales of goods and services';
															|it = 'Выручка от продаж товаров и услуг';
															|pl = 'Przychody od sprzedaży towarów i usług';
															|tr = 'Ürün ve hizmet satışından gelir'");
		DescriptionOfAccountingObject_.TitleOfTheInvoiceSetupTable = NStr("vi = 'Tài khoản hạch toán doanh thu từ bán hàng hóa và dịch vụ';
																			|ru = 'Счета учета выручки от продаж товаров и услуг';
																			|en = 'Ledger accounts of revenue from sales of goods and services'; fa = 'Ledger accounts of revenue from sales of goods and services';
																			|it = 'Счета учета выручки от продаж товаров и услуг';
																			|pl = 'Konta księgowe przychodu od sprzedaży towarów i usług';
																			|tr = 'Ürün ve hizmet satışından gelirin defterikebir hesabı'");
		DescriptionOfAccountingObject_.DescriptionOfTheConfigurationObjectTypes = New TypeDescription("CatalogRef.InventoryAccountingGroups");
		DescriptionOfAccountingObject_.DescriptionOfTheAccountingLocationTypes = New TypeDescription();
		DescriptionOfAccountingObjectsForConfiguringForms.Insert(Enums.DeleteFinancialAccountingObjects.SalesRevenueExcludingVAT, DescriptionOfAccountingObject_);
	EndIf;
	
	DescriptionOfAccountingObject_ = DescriptionOfAccountingObjectForConfiguringForms();
	DescriptionOfAccountingObject_.Group = GroupsOfAccountingObjects.IncomeAndExpenses;
	DescriptionOfAccountingObject_.Presentation = NStr("vi = 'Giá vốn hàng bán và dịch vụ';
														|ru = 'Себестоимость продаж товаров и услуг';
														|en = 'Cost of goods and services sold'; fa = 'Cost of goods and services sold';
														|it = 'Себестоимость продаж товаров и услуг';
														|pl = 'Koszt własny sprzedaży towarów i usług';
														|tr = 'Satılan malların ve hizmetlerin maliyeti'");
	DescriptionOfAccountingObject_.TitleOfTheInvoiceSetupTable = NStr("vi = 'Tài khoản hạch toán giá vốn hàng bán và dịch vụ';
																		|ru = 'Счета учета себестоимости продаж товаров и услуг';
																		|en = 'Ledger accounts of cost of goods and services sold'; fa = 'Ledger accounts of cost of goods and services sold';
																		|it = 'Счета учета себестоимости продаж товаров и услуг';
																		|pl = 'Konta księgowe kosztu własnego sprzedaży towarów i usług';
																		|tr = 'Ürün ve hizmet satışının maliyetinin defterikebir hesabı'");
	DescriptionOfAccountingObject_.DescriptionOfTheConfigurationObjectTypes = New TypeDescription("CatalogRef.InventoryAccountingGroups");
	DescriptionOfAccountingObject_.DescriptionOfTheAccountingLocationTypes = New TypeDescription();
	DescriptionOfAccountingObjectsForConfiguringForms.Insert(Enums.DeleteFinancialAccountingObjects.SaleCost, DescriptionOfAccountingObject_);
	
	If TransactionSettings.RevenueExcludingVAT = False
	 Or TransactionSettings.RevenueExcludingVAT = Undefined Then
		DescriptionOfAccountingObject_ = DescriptionOfAccountingObjectForConfiguringForms();
		DescriptionOfAccountingObject_.Group = GroupsOfAccountingObjects.IncomeAndExpenses;
		DescriptionOfAccountingObject_.Presentation = NStr("vi = 'Doanh thu khác gồm thuế GTGT';
															|ru = 'Прочая выручка с НДС';
															|en = 'Other revenue including VAT'; fa = 'سایر درآمد شامل مالیات بر ارزش افزوده';
															|it = 'Прочая выручка с НДС';
															|pl = 'Utarg pozostały';
															|tr = 'Diğer KDV dahil gelir'");
		DescriptionOfAccountingObject_.TitleOfTheInvoiceSetupTable = NStr("vi = 'Tài khoản hạch toán doanh thu khác';
																			|ru = 'Счета учета прочей выручки';
																			|en = 'Ledger accounts of other revenue'; fa = 'Ledger accounts of other revenue';
																			|it = 'Счета учета прочей выручки';
																			|pl = 'Konta księgowe pozostałych przychodów';
																			|tr = 'Diğer gelirin defterikebir hesabı'");
		DescriptionOfAccountingObject_.SelectingConfigurationObjects = New Structure("Income", True);
		DescriptionOfAccountingObject_.DescriptionOfTheConfigurationObjectTypes = New TypeDescription("CatalogRef.IncomeExpensesAccountingGroups");
		DescriptionOfAccountingObject_.DescriptionOfTheAccountingLocationTypes = New TypeDescription();
		DescriptionOfAccountingObjectsForConfiguringForms.Insert(Enums.DeleteFinancialAccountingObjects.RevenueServicesAndAssets, DescriptionOfAccountingObject_);
	EndIf;
	
	If TransactionSettings.RevenueExcludingVAT = True
	 Or TransactionSettings.RevenueExcludingVAT = Undefined Then
		DescriptionOfAccountingObject_ = DescriptionOfAccountingObjectForConfiguringForms();
		DescriptionOfAccountingObject_.Group = GroupsOfAccountingObjects.IncomeAndExpenses;
		DescriptionOfAccountingObject_.Presentation = NStr("vi = 'Doanh thu khác';
															|ru = 'Прочая выручка';
															|en = 'Revenue — Services and Assets'; fa = 'درآمد — خدمات و دارایی‌ها';
															|it = 'Прочая выручка';
															|pl = 'Utarg pozostały';
															|tr = 'Diğer gelir'");
		DescriptionOfAccountingObject_.TitleOfTheInvoiceSetupTable = NStr("vi = 'Tài khoản hạch toán doanh thu khác';
																			|ru = 'Счета учета прочей выручки';
																			|en = 'Ledger accounts of other revenue'; fa = 'Ledger accounts of other revenue';
																			|it = 'Счета учета прочей выручки';
																			|pl = 'Konta księgowe pozostałych przychodów';
																			|tr = 'Diğer gelirin defterikebir hesabı'");
		DescriptionOfAccountingObject_.SelectingConfigurationObjects = New Structure("Income", True);
		DescriptionOfAccountingObject_.DescriptionOfTheConfigurationObjectTypes = New TypeDescription("CatalogRef.IncomeExpensesAccountingGroups");
		DescriptionOfAccountingObject_.DescriptionOfTheAccountingLocationTypes = New TypeDescription();
		DescriptionOfAccountingObjectsForConfiguringForms.Insert(Enums.DeleteFinancialAccountingObjects.RevenueServicesAndAssetsExcludingVAT, DescriptionOfAccountingObject_);
	EndIf;
	
	DescriptionOfAccountingObject_ = DescriptionOfAccountingObjectForConfiguringForms();
	DescriptionOfAccountingObject_.Group = GroupsOfAccountingObjects.IncomeAndExpenses;
	DescriptionOfAccountingObject_.Presentation = NStr("vi = 'Chi phí khác';
														|ru = 'Прочие расходы';
														|en = 'Other expenses'; fa = 'سایر هزینه‌ها';
														|it = 'Прочие расходы';
														|pl = 'Inne rozchody';
														|tr = 'Diğer giderler'");
	DescriptionOfAccountingObject_.TitleOfTheInvoiceSetupTable = NStr("vi = 'Tài khoản hạch toán chi phí khác';
																		|ru = 'Счета учета прочих расходов';
																		|en = 'Ledger accounts of other expenses'; fa = 'Ledger accounts of other expenses';
																		|it = 'Счета учета прочих расходов';
																		|pl = 'Konta księgowe pozostałych rozchodów';
																		|tr = 'Diğer giderleri defterikebir hesabı'");
	DescriptionOfAccountingObject_.SelectingConfigurationObjects = New Structure("Expenses", True);
	DescriptionOfAccountingObject_.DescriptionOfTheConfigurationObjectTypes = New TypeDescription("CatalogRef.IncomeExpensesAccountingGroups");
	DescriptionOfAccountingObject_.DescriptionOfTheAccountingLocationTypes = New TypeDescription("CatalogRef.BusinessStructure");
	DescriptionOfAccountingObjectsForConfiguringForms.Insert(Enums.DeleteFinancialAccountingObjects.Expenses, DescriptionOfAccountingObject_);
	
	DescriptionOfAccountingObject_ = DescriptionOfAccountingObjectForConfiguringForms();
	DescriptionOfAccountingObject_.Group = GroupsOfAccountingObjects.IncomeAndExpenses;
	DescriptionOfAccountingObject_.Presentation = NStr("vi = 'Thu nhập khác';
														|ru = 'Прочие доходы';
														|en = 'Income'; fa = 'درآمد';
														|it = 'Прочие доходы';
														|pl = 'Inne dochody';
														|tr = 'Diğer gelirler'");
	DescriptionOfAccountingObject_.TitleOfTheInvoiceSetupTable = NStr("vi = 'Tài khoản hạch toán thu nhập khác';
																		|ru = 'Счета учета прочих доходов';
																		|en = 'Ledger accounts of income'; fa = 'Ledger accounts of income';
																		|it = 'Счета учета прочих доходов';
																		|pl = 'Konta księgowe pozostałych dochodów';
																		|tr = 'Diğer gelirlerin defterikebir hesabı'");
	DescriptionOfAccountingObject_.SelectingConfigurationObjects = New Structure("Income", True);
	DescriptionOfAccountingObject_.DescriptionOfTheConfigurationObjectTypes = New TypeDescription("CatalogRef.IncomeExpensesAccountingGroups");
	DescriptionOfAccountingObject_.DescriptionOfTheAccountingLocationTypes = New TypeDescription("CatalogRef.BusinessStructure");
	DescriptionOfAccountingObjectsForConfiguringForms.Insert(Enums.DeleteFinancialAccountingObjects.OtherIncome, DescriptionOfAccountingObject_);
	
	DescriptionOfAccountingObject_ = DescriptionOfAccountingObjectForConfiguringForms();
	DescriptionOfAccountingObject_.Group = GroupsOfAccountingObjects.IncomeAndExpenses;
	DescriptionOfAccountingObject_.Presentation = NStr("vi = 'Kết chuyển thu nhập';
														|ru = 'Закрытие доходов';
														|en = 'Close income'; fa = 'Close income';
														|it = 'Закрытие доходов';
														|pl = 'Zamknięcie dochodów';
														|tr = 'Gelirlerin kapatılması'");
	DescriptionOfAccountingObject_.TitleOfTheInvoiceSetupTable = NStr("vi = 'Tài khoản kết chuyển thu nhập từ các giao dịch liên tục';
																		|ru = 'Счета учета закрытия доходов от продолжающихся операций';
																		|en = 'Ledger accounts of continuing operation income closing'; fa = 'Ledger accounts of continuing operation income closing';
																		|it = 'Счета учета закрытия доходов от продолжающихся операций';
																		|pl = 'Konta księgowe zamknięcia dochodów od kontynuowanych operacji';
																		|tr = 'Devam etmekte olan işlemlerden gelirlerin kapatılmasının defterikebir hesabı'");
	DescriptionOfAccountingObject_.DescriptionOfTheConfigurationObjectTypes = Undefined;
	DescriptionOfAccountingObject_.DescriptionOfTheAccountingLocationTypes = New TypeDescription();
	DescriptionOfAccountingObjectsForConfiguringForms.Insert(Enums.DeleteFinancialAccountingObjects.ContinuingOperationIncomeClosing, DescriptionOfAccountingObject_);
	
	DescriptionOfAccountingObject_ = DescriptionOfAccountingObjectForConfiguringForms();
	DescriptionOfAccountingObject_.Group = GroupsOfAccountingObjects.IncomeAndExpenses;
	DescriptionOfAccountingObject_.Presentation = NStr("vi = 'Kết chuyển chi phí';
														|ru = 'Закрытие расходов';
														|en = 'Close expenses'; fa = 'Close expenses';
														|it = 'Закрытие расходов';
														|pl = 'Zamknięcie rozchodów';
														|tr = 'Giderlerin kapatılması'");
	DescriptionOfAccountingObject_.TitleOfTheInvoiceSetupTable = NStr("vi = 'Tài khoản kết chuyển chi phí từ các giao dịch liên tục';
																		|ru = 'Счета учета закрытия расходов от продолжающихся операций';
																		|en = 'Ledger accounts of continuing operation expense closing'; fa = 'Ledger accounts of continuing operation expense closing';
																		|it = 'Счета учета закрытия расходов от продолжающихся операций';
																		|pl = 'Konta księgowe zamknięcia rozchodów od kontynuowanych operacji';
																		|tr = 'Devam etmekte olan işlemlerden giderlerin kapatılmasının defterikebir hesabı'");
	DescriptionOfAccountingObject_.DescriptionOfTheConfigurationObjectTypes = Undefined;
	DescriptionOfAccountingObject_.DescriptionOfTheAccountingLocationTypes = New TypeDescription();
	DescriptionOfAccountingObjectsForConfiguringForms.Insert(Enums.DeleteFinancialAccountingObjects.ContinuingOperationExpenseClosing, DescriptionOfAccountingObject_);
	
	#EndRegion
	
	#Region VAT
	
	DescriptionOfAccountingObject_ = DescriptionOfAccountingObjectForConfiguringForms();
	DescriptionOfAccountingObject_.Group = GroupsOfAccountingObjects.VAT;
	DescriptionOfAccountingObject_.Presentation = NStr("vi = 'Thuế GTGT đầu vào';
														|ru = 'Входящий НДС';
														|en = 'Input VAT'; fa = 'مالیات بر ارزش افزوده ورودی';
														|it = 'Входящий НДС';
														|pl = 'Przychodzący VAT';
														|tr = 'KDV Girişi'");
	DescriptionOfAccountingObject_.TitleOfTheInvoiceSetupTable = NStr("vi = 'Tài khoản hạch toán thuế GTGT đầu vào';
																		|ru = 'Счета учета входящего НДС';
																		|en = 'Ledger accounts of input VAT'; fa = 'Ledger accounts of input VAT';
																		|it = 'Счета учета входящего НДС';
																		|pl = 'Konta księgowe wchodzącego VAT';
																		|tr = 'KDV girişi muhasebe hesapları'");
	DescriptionOfAccountingObject_.DescriptionOfTheConfigurationObjectTypes = New TypeDescription("EnumRef.VATTaxationTypes");
	DescriptionOfAccountingObject_.SelectingConfigurationObjects = New Structure("Ref", VATAccountingERP.VATActivities());
	DescriptionOfAccountingObject_.DescriptionOfTheAccountingLocationTypes = New TypeDescription("EnumRef.AssetKinds"); 
	DescriptionOfAccountingObjectsForConfiguringForms.Insert(Enums.DeleteFinancialAccountingObjects.IncomingVAT, DescriptionOfAccountingObject_);
	
	DescriptionOfAccountingObject_ = DescriptionOfAccountingObjectForConfiguringForms();
	DescriptionOfAccountingObject_.Group = GroupsOfAccountingObjects.VAT;
	DescriptionOfAccountingObject_.Presentation = NStr("vi = 'Hạch toán thuế GTGT';
														|ru = 'Расчеты по НДС';
														|en = 'VAT AR/AP accounting'; fa = 'حسابداری دریافتنی/پرداختنی مالیات بر ارزش افزوده';
														|it = 'Расчеты по НДС';
														|pl = 'Rozliczenia z tytułu VAT';
														|tr = 'KDV''ye ilişkin hesaplamalar'");
	DescriptionOfAccountingObject_.TitleOfTheInvoiceSetupTable = NStr("vi = 'Tài khoản hạch toán thuế GTGT';
																		|ru = 'Счета учета расчетов по НДС';
																		|en = 'Ledger accounts of VAT AR/AP accounting'; fa = 'Ledger accounts of VAT AR/AP accounting';
																		|it = 'Счета учета расчетов по НДС';
																		|pl = 'Konta księgowe rozliczeń z VAT';
																		|tr = 'KDV''ye ilişkin hesaplamaların defterikebir hesabı'");
	DescriptionOfAccountingObject_.DescriptionOfTheConfigurationObjectTypes = Undefined;
	DescriptionOfAccountingObject_.DescriptionOfTheAccountingLocationTypes = New TypeDescription(); 
	DescriptionOfAccountingObjectsForConfiguringForms.Insert(Enums.DeleteFinancialAccountingObjects.VATAccountsPayable, DescriptionOfAccountingObject_);
	
	If TransactionSettings.RevenueExcludingVAT = False
	 Or TransactionSettings.RevenueExcludingVAT = Undefined Then
		DescriptionOfAccountingObject_ = DescriptionOfAccountingObjectForConfiguringForms();
		DescriptionOfAccountingObject_.Group = GroupsOfAccountingObjects.VAT;
		DescriptionOfAccountingObject_.Presentation = NStr("vi = 'Thuế GTGT bán hàng hóa và dịch vụ';
															|ru = 'НДС с продаж товаров и услуг';
															|en = 'VAT on sales of goods and services'; fa = 'VAT on sales of goods and services';
															|it = 'НДС с продаж товаров и услуг';
															|pl = 'VAT od sprzedaży towarów i usług';
															|tr = 'Ürün ve hizmet satışından KDV'");
		DescriptionOfAccountingObject_.TitleOfTheInvoiceSetupTable = NStr("vi = 'Tài khoản hạch toán thuế GTGT bán hàng hóa và dịch vụ';
																			|ru = 'Счета учета НДС с продаж товаров и услуг';
																			|en = 'Ledger accounts of VAT on sales of goods and services'; fa = 'Ledger accounts of VAT on sales of goods and services';
																			|it = 'Счета учета НДС с продаж товаров и услуг';
																			|pl = 'Konta księgowe VAT od sprzedaży towarów i usług';
																			|tr = 'Ürün ve hizmet satışından KDV defterikebir hesabı'");
		DescriptionOfAccountingObject_.DescriptionOfTheConfigurationObjectTypes = New TypeDescription("CatalogRef.InventoryAccountingGroups");
		DescriptionOfAccountingObject_.DescriptionOfTheAccountingLocationTypes = New TypeDescription();
		DescriptionOfAccountingObjectsForConfiguringForms.Insert(Enums.DeleteFinancialAccountingObjects.VATFromSales, DescriptionOfAccountingObject_);
	EndIf;
	
	DescriptionOfAccountingObject_ = DescriptionOfAccountingObjectForConfiguringForms();
	DescriptionOfAccountingObject_.Group = GroupsOfAccountingObjects.VAT;
	DescriptionOfAccountingObject_.Presentation = NStr("vi = 'Thuế GTGT giao hàng mà chưa chuyển giao quyền sở hữu';
														|ru = 'НДС по отгузкам без перехода права собственности';
														|en = 'VAT on shipment without transfer of title to goods'; fa = 'VAT on shipment without transfer of title to goods';
														|it = 'НДС по отгузкам без перехода права собственности';
														|pl = 'VAT z wysyłek bez przejścia praw własności';
														|tr = 'Mülkiyet hakkı devri olmadan sevkiyatlara ilişkin KDV'");
	DescriptionOfAccountingObject_.TitleOfTheInvoiceSetupTable = NStr("vi = 'Tài khoản hạch toán thuế GTGT khi giao hàng mà chưa chuyển giao quyền sở hữu';
																		|ru = 'Счета учета НДС по отгрузкам без перехода права собственности';
																		|en = 'Ledger accounts of VAT on shipment with deferred transfer of title of goods'; fa = 'Ledger accounts of VAT on shipment with deferred transfer of title of goods';
																		|it = 'Счета учета НДС по отгрузкам без перехода права собственности';
																		|pl = 'Konta księgowe VAT według wysyłek bez przejścia praw własności';
																		|tr = 'Mülkiyet hakkı devri olmadan sevkiyatlara ilişkin defterikebir hesabı KDV''si'");
	DescriptionOfAccountingObject_.DescriptionOfTheConfigurationObjectTypes = Undefined;
	DescriptionOfAccountingObject_.DescriptionOfTheAccountingLocationTypes = New TypeDescription();
	DescriptionOfAccountingObjectsForConfiguringForms.Insert(Enums.DeleteFinancialAccountingObjects.VATForShipmentsWithDeferredTransferOfTitle, DescriptionOfAccountingObject_);
	
	If TransactionSettings.RevenueExcludingVAT = False
	 Or TransactionSettings.RevenueExcludingVAT = Undefined Then
		DescriptionOfAccountingObject_ = DescriptionOfAccountingObjectForConfiguringForms();
		DescriptionOfAccountingObject_.Group = GroupsOfAccountingObjects.VAT;
		DescriptionOfAccountingObject_.Presentation = NStr("vi = 'Thuế GTGT từ doanh thu khác';
															|ru = 'НДС с прочих продаж';
															|en = 'VAT on other sales'; fa = 'VAT on other sales';
															|it = 'НДС с прочих продаж';
															|pl = 'VAT od pozostałych operacji sprzedaży';
															|tr = 'Diğer satışlardan KDV'");
		DescriptionOfAccountingObject_.TitleOfTheInvoiceSetupTable = NStr("vi = 'Tài khoản hạch toán thuế GTGT từ doanh thu khác';
																			|ru = 'Счета учета НДС с прочих продаж';
																			|en = 'Ledger accounts of VAT on other sales'; fa = 'Ledger accounts of VAT on other sales';
																			|it = 'Счета учета НДС с прочих продаж';
																			|pl = 'Konta księgowe VAT z pozostałych operacji sprzedaży';
																			|tr = 'Ürün ve hizmet satışından KDV defterikebir hesabı'");
		DescriptionOfAccountingObject_.SelectingConfigurationObjects = New Structure("Income", True);
		DescriptionOfAccountingObject_.DescriptionOfTheConfigurationObjectTypes = New TypeDescription("CatalogRef.IncomeExpensesAccountingGroups");
		DescriptionOfAccountingObject_.DescriptionOfTheAccountingLocationTypes = New TypeDescription();
		DescriptionOfAccountingObjectsForConfiguringForms.Insert(Enums.DeleteFinancialAccountingObjects.VATFromOtherIncome, DescriptionOfAccountingObject_);
	EndIf;
	
	DescriptionOfAccountingObject_ = DescriptionOfAccountingObjectForConfiguringForms();
	DescriptionOfAccountingObject_.Group = GroupsOfAccountingObjects.VAT;
	DescriptionOfAccountingObject_.Presentation = NStr("vi = 'Thuế GTGT từ ứng trước';
														|ru = 'НДС с полученных авансов';
														|en = 'VAT on prepayments from customer'; fa = 'VAT on prepayments from customer';
														|it = 'НДС с полученных авансов';
														|pl = 'VAT z otrzymanych zaliczek';
														|tr = 'Alınan avanslardan KDV'");
	DescriptionOfAccountingObject_.TitleOfTheInvoiceSetupTable = NStr("vi = 'Tài khoản hạch toán thuế GTGT từ nhận ứng trước';
																		|ru = 'Счета учета НДС с полученных авансов';
																		|en = 'Ledger accounts of VAT on prepayments from customer'; fa = 'Ledger accounts of VAT on prepayments from customer';
																		|it = 'Счета учета НДС с полученных авансов';
																		|pl = 'Konta księgowe VAT z otrzymanych zaliczek';
																		|tr = 'Alınan avanslardan KDV defterikebir hesabı'");
	DescriptionOfAccountingObject_.DescriptionOfTheConfigurationObjectTypes = New TypeDescription("CatalogRef.FinancialAccountingGroupsOfARAP");
	DescriptionOfAccountingObject_.DescriptionOfTheAccountingLocationTypes = New TypeDescription(); 
	DescriptionOfAccountingObjectsForConfiguringForms.Insert(Enums.DeleteFinancialAccountingObjects.VATFromPrepaymentsFromCustomer, DescriptionOfAccountingObject_);
	
	DescriptionOfAccountingObject_ = DescriptionOfAccountingObjectForConfiguringForms();
	DescriptionOfAccountingObject_.Group = GroupsOfAccountingObjects.VAT;
	DescriptionOfAccountingObject_.Presentation = NStr("vi = 'Thuế GTGT từ ứng trước';
														|ru = 'НДС с выплаченных авансов';
														|en = 'VAT on prepayments to vendor'; fa = 'VAT on prepayments to vendor';
														|it = 'НДС с выплаченных авансов';
														|pl = 'VAT z wypłaconych zaliczek';
														|tr = 'Ödenen avanslardan KDV'");
	DescriptionOfAccountingObject_.TitleOfTheInvoiceSetupTable = NStr("vi = 'Tài khoản hạch toán thuế GTGT từ ứng trước';
																		|ru = 'Счета учета НДС с выплаченных авансов';
																		|en = 'Ledger accounts of VAT on prepayments to vendor'; fa = 'Ledger accounts of VAT on prepayments to vendor';
																		|it = 'Счета учета НДС с выплаченных авансов';
																		|pl = 'Konta księgowe VAT z wypłaconych zaliczek';
																		|tr = 'Ödenen avanslardan KDV defterikebir hesabı'");
	DescriptionOfAccountingObject_.DescriptionOfTheConfigurationObjectTypes = New TypeDescription("CatalogRef.FinancialAccountingGroupsOfARAP");
	DescriptionOfAccountingObject_.DescriptionOfTheAccountingLocationTypes = New TypeDescription(); 
	DescriptionOfAccountingObjectsForConfiguringForms.Insert(Enums.DeleteFinancialAccountingObjects.VATFromPrepaymentsToVendor, DescriptionOfAccountingObject_);

	#EndRegion

	#Region ProvisionsForImpairment
	
	DescriptionOfAccountingObject_ = DescriptionOfAccountingObjectForConfiguringForms();
	DescriptionOfAccountingObject_.Group = GroupsOfAccountingObjects.ProvisionsForImpairment;
	DescriptionOfAccountingObject_.Presentation = NStr("vi = 'Hàng tồn kho';
														|ru = 'Запасов';
														|en = 'Inventory'; fa = 'موجودی';
														|it = 'Запасов';
														|pl = 'Inventory';
														|tr = 'Stokların'");
	DescriptionOfAccountingObject_.TitleOfTheInvoiceSetupTable = NStr("vi = 'Tài khoản kế toán dự phòng giảm giá tài sản hữu hình';
																		|ru = 'Счета учета резервов под обесценение материальных ценностей';
																		|en = 'Ledger accounts of provisions for impairment of tangible assets'; fa = 'Ledger accounts of provisions for impairment of tangible assets';
																		|it = 'Счета учета резервов под обесценение материальных ценностей';
																		|pl = 'Konta księgowe rezerw pod utratę wartości zapasów';
																		|tr = 'Maddi duran varlıkların amortismanı altındaki rezerv defterikebir hesabı'");
	DescriptionOfAccountingObject_.DescriptionOfTheConfigurationObjectTypes = New TypeDescription("CatalogRef.InventoryAccountingGroups");
	DescriptionOfAccountingObject_.DescriptionOfTheAccountingLocationTypes = New TypeDescription();
	DescriptionOfAccountingObjectsForConfiguringForms.Insert(Enums.DeleteFinancialAccountingObjects.ProvisionsForImpairmentOfInventory, DescriptionOfAccountingObject_);
	
	DescriptionOfAccountingObject_ = DescriptionOfAccountingObjectForConfiguringForms();
	DescriptionOfAccountingObject_.Group = GroupsOfAccountingObjects.ProvisionsForImpairment;
	DescriptionOfAccountingObject_.Presentation = NStr("vi = 'Vật tư đã chuyển giao';
														|ru = 'Запасов переданных';
														|en = 'Transferred inventory'; fa = 'Transferred inventory';
														|it = 'Запасов переданных';
														|pl = 'Zapasów przekazanych';
														|tr = 'Transfer edilen rezervler'");
	DescriptionOfAccountingObject_.TitleOfTheInvoiceSetupTable = NStr("vi = 'Tài khoản kế toán dự phòng giảm giá giá trị vật liệu đã chuyển giao';
																		|ru = 'Счета учета резервов под обесценение переданных материальных ценностей';
																		|en = 'Ledger accounts of provisions for impairment of transferred tangible assets'; fa = 'Ledger accounts of provisions for impairment of transferred tangible assets';
																		|it = 'Счета учета резервов под обесценение переданных материальных ценностей';
																		|pl = 'Konta księgowe rezerw przekazanych pod utratę wartości zapasów';
																		|tr = 'Transfer edilen maddi duran varlıkların amortismanı altındaki rezerv defterikebir hesabı'");
	DescriptionOfAccountingObject_.DescriptionOfTheConfigurationObjectTypes = New TypeDescription("CatalogRef.InventoryAccountingGroups");
	DescriptionOfAccountingObject_.DescriptionOfTheAccountingLocationTypes = New TypeDescription();
	DescriptionOfAccountingObjectsForConfiguringForms.Insert(Enums.DeleteFinancialAccountingObjects.ProvisionsForImpairmentOfInventoriesTransferred, DescriptionOfAccountingObject_);
	
	DescriptionOfAccountingObject_ = DescriptionOfAccountingObjectForConfiguringForms();
	DescriptionOfAccountingObject_.Group = GroupsOfAccountingObjects.ProvisionsForImpairment;
	DescriptionOfAccountingObject_.Presentation = NStr("vi = 'Vật tư trong kho tại xưởng';
														|ru = 'Запасов в цеховой кладовой';
														|en = 'Inventory in shop floor stockrooms'; fa = 'Inventory in shop floor stockrooms';
														|it = 'Запасов в цеховой кладовой';
														|pl = 'Zapasów w magazynie spiżarni';
														|tr = 'Atölye deposundaki rezervler'");
	DescriptionOfAccountingObject_.TitleOfTheInvoiceSetupTable = NStr("vi = 'Tài khoản kế toán dự phòng giảm giá vật tư trong kho tại xưởng';
																		|ru = 'Счета учета резервов под обесценение материальных ценностей в цеховых кладовых';
																		|en = 'Ledger accounts of provisions for impairment of tangible assets in shop floor stockrooms'; fa = 'Ledger accounts of provisions for impairment of tangible assets in shop floor stockrooms';
																		|it = 'Счета учета резервов под обесценение материальных ценностей в цеховых кладовых';
																		|pl = 'Konta księgowe rezerw pod utratę wartości zapasów w magazynach spiżarni';
																		|tr = 'Atölye deposundaki maddi duran varlıkların amortismanı altındaki rezerv defterikebir hesabı'");
	DescriptionOfAccountingObject_.DescriptionOfTheConfigurationObjectTypes = New TypeDescription("CatalogRef.InventoryAccountingGroups");
	DescriptionOfAccountingObject_.DescriptionOfTheAccountingLocationTypes = New TypeDescription();
	DescriptionOfAccountingObjectsForConfiguringForms.Insert(Enums.DeleteFinancialAccountingObjects.ProvisionsForImpairmentOfInventoryInShopPantry, DescriptionOfAccountingObject_);
	
	DescriptionOfAccountingObject_ = DescriptionOfAccountingObjectForConfiguringForms();
	DescriptionOfAccountingObject_.Group = GroupsOfAccountingObjects.ProvisionsForImpairment;
	DescriptionOfAccountingObject_.Presentation = NStr("vi = 'Sản xuất dở dang';
														|ru = 'Незавершенного производства';
														|en = 'Work-in-progress'; fa = 'کالای در جریان ساخت';
														|it = 'Незавершенного производства';
														|pl = 'Produkcja niezakończona';
														|tr = 'Devam eden imalat'");
	DescriptionOfAccountingObject_.TitleOfTheInvoiceSetupTable = NStr("vi = 'Tài khoản kế toán dự phòng giảm giá vật tư trong sản xuất dở dang';
																		|ru = 'Счета учета резервов под обесценение материальных ценностей в незавершенном производстве';
																		|en = 'Ledger accounts of provisions for impairment of tangible assets in work-in-progress'; fa = 'Ledger accounts of provisions for impairment of tangible assets in work-in-progress';
																		|it = 'Счета учета резервов под обесценение материальных ценностей в незавершенном производстве';
																		|pl = 'Konta księgowe rezerw pod utratę wartości zapasów w produkcji niezakończonej';
																		|tr = 'Devam eden imalattaki maddi duran varlıkların değer düşüşü rezervleri defterikebir hesabı'");
	DescriptionOfAccountingObject_.DescriptionOfTheConfigurationObjectTypes = New TypeDescription("CatalogRef.AnalyticalInventoryGroups");
	DescriptionOfAccountingObject_.DescriptionOfTheAccountingLocationTypes = New TypeDescription();
	DescriptionOfAccountingObjectsForConfiguringForms.Insert(Enums.DeleteFinancialAccountingObjects.ProvisionsForImpairmentOfWorkInProgress, DescriptionOfAccountingObject_);
	
	#EndRegion

	#Region LossAllowance
	
	DescriptionOfAccountingObject_ = DescriptionOfAccountingObjectForConfiguringForms();
	DescriptionOfAccountingObject_.Group = GroupsOfAccountingObjects.LossAllowance;
	DescriptionOfAccountingObject_.Presentation = NStr("vi = 'Dự phòng nợ xấu';
														|ru = 'Резервы по сомнительным долгам';
														|en = 'Loss allowance'; fa = 'ذخیره زیان اعتباری';
														|it = 'Резервы по сомнительным долгам';
														|pl = 'Rezerwy z tytułu wątpliwych długów';
														|tr = 'Şüpheli borç karşılığı'");
	DescriptionOfAccountingObject_.TitleOfTheInvoiceSetupTable = NStr("vi = 'Tài khoản kế toán dự phòng nợ khó đòi';
																		|ru = 'Счета учета резервов по сомнительным долгам';
																		|en = 'Ledger accounts of loss allowance'; fa = 'Ledger accounts of loss allowance';
																		|it = 'Счета учета резервов по сомнительным долгам';
																		|pl = 'Konta księgowe rezerw według wątpliwych długów';
																		|tr = 'Şüpheli borç karşılığı rezervlerinin defterikebir hesabı'");
	DescriptionOfAccountingObject_.DescriptionOfTheConfigurationObjectTypes = New TypeDescription("CatalogRef.FinancialAccountingGroupsOfARAP");
	DescriptionOfAccountingObject_.DescriptionOfTheAccountingLocationTypes = New TypeDescription();
	DescriptionOfAccountingObjectsForConfiguringForms.Insert(Enums.DeleteFinancialAccountingObjects.LossAllowance, DescriptionOfAccountingObject_);
	
	#EndRegion

	#Region FutureExpenseCommitments
	
	DescriptionOfAccountingObject_ = DescriptionOfAccountingObjectForConfiguringForms();
	DescriptionOfAccountingObject_.Group = GroupsOfAccountingObjects.FutureExpenseCommitments;
	DescriptionOfAccountingObject_.Presentation = NStr("vi = 'Dự phòng chi phí trả trước';
														|ru = 'Резервы по предстоящим расходам';
														|en = 'Provisions'; fa = 'ذخایر';
														|it = 'Резервы по предстоящим расходам';
														|pl = 'Rezerwy z tytułu przyszłych rozchodów';
														|tr = 'Karşılıklar ve şarta bağlı yükümlülükler'");
	DescriptionOfAccountingObject_.TitleOfTheInvoiceSetupTable = NStr("vi = 'Tài khoản hạch toán dự phòng chi phí trả trước';
																		|ru = 'Счета учета резервов по предстоящим расходам';
																		|en = 'Ledger accounts of provisions'; fa = 'Ledger accounts of provisions';
																		|it = 'Счета учета резервов по предстоящим расходам';
																		|pl = 'Konta księgowe rezerw z tytułu przyszłych rozchodów';
																		|tr = 'Karşılıklar ve şarta bağlı yükümlülüklerin defterikebir hesabı'");
	DescriptionOfAccountingObject_.DescriptionOfTheConfigurationObjectTypes = New TypeDescription("CatalogRef.Reserves");
	DescriptionOfAccountingObject_.DescriptionOfTheAccountingLocationTypes = New TypeDescription();
	DescriptionOfAccountingObjectsForConfiguringForms.Insert(Enums.DeleteFinancialAccountingObjects.ProvisionsEstimatedLiabilities, DescriptionOfAccountingObject_);
	
	DescriptionOfAccountingObject_ = DescriptionOfAccountingObjectForConfiguringForms();
	DescriptionOfAccountingObject_.Group = GroupsOfAccountingObjects.FutureExpenseCommitments;
	DescriptionOfAccountingObject_.Presentation = NStr("vi = 'Phần trăm chiết khấu dự phòng';
														|ru = 'Проценты дисконтирования резервов';
														|en = 'Provision discounting interest'; fa = 'سود تنزیل ذخیره';
														|it = 'Проценты дисконтирования резервов';
														|pl = 'Provision discounting interest';
														|tr = 'İskonto rezervlerinin yüzdesi'");
	DescriptionOfAccountingObject_.TitleOfTheInvoiceSetupTable = NStr("vi = 'Tài khoản kế toán phần trăm chiết khấu dự phòng';
																		|ru = 'Счета учета процентов дисконтирования резервов';
																		|en = 'Ledger accounts of provision discounting interest'; fa = 'Ledger accounts of provision discounting interest';
																		|it = 'Счета учета процентов дисконтирования резервов';
																		|pl = 'Ledger accounts of provision discounting interest';
																		|tr = 'İskonto rezervlerinin yüzdesinin defterikebir hesabı'");
	DescriptionOfAccountingObject_.DescriptionOfTheConfigurationObjectTypes = New TypeDescription("CatalogRef.Reserves");
	DescriptionOfAccountingObject_.DescriptionOfTheAccountingLocationTypes = New TypeDescription();
	DescriptionOfAccountingObjectsForConfiguringForms.Insert(Enums.DeleteFinancialAccountingObjects.ProvisionDiscountingInterest, DescriptionOfAccountingObject_);
	
	#EndRegion

	#Region OtherAssetsAndLiabilities
	
	DescriptionOfAccountingObject_ = DescriptionOfAccountingObjectForConfiguringForms();
	DescriptionOfAccountingObject_.Group = GroupsOfAccountingObjects.OtherAssetsAndLiabilities;
	DescriptionOfAccountingObject_.Presentation = NStr("vi = 'Thuế và phí';
														|ru = 'Налоги и взносы';
														|en = 'Taxes and contributions'; fa = 'Taxes and contributions';
														|it = 'Налоги и взносы';
														|pl = 'Podatki i składki';
														|tr = 'Vergiler ve katkılar'");
	DescriptionOfAccountingObject_.TitleOfTheInvoiceSetupTable = NStr("vi = 'Tài khoản hạch toán thuế và bảo hiểm';
																		|ru = 'Счета учета расчетов по налогам и взносам';
																		|en = 'Ledger accounts of AR/AP accounting for taxes and contributions'; fa = 'Ledger accounts of AR/AP accounting for taxes and contributions';
																		|it = 'Счета учета расчетов по налогам и взносам';
																		|pl = 'Konta księgowe rozliczeń z tytułu podatków i składek';
																		|tr = 'Vergiler ve katkılara ilişkin hesaplamalarda defterikebir hesabı'");
	DescriptionOfAccountingObject_.DescriptionOfTheConfigurationObjectTypes = New TypeDescription("CatalogRef.TaxContributionKinds"); 
	DescriptionOfAccountingObject_.DescriptionOfTheAccountingLocationTypes = New TypeDescription(); 
	DescriptionOfAccountingObjectsForConfiguringForms.Insert(Enums.DeleteFinancialAccountingObjects.TaxesAndContributionsAccountsPayable, DescriptionOfAccountingObject_);
	
	DescriptionOfAccountingObject_ = DescriptionOfAccountingObjectForConfiguringForms();
	DescriptionOfAccountingObject_.Group = GroupsOfAccountingObjects.OtherAssetsAndLiabilities;
	DescriptionOfAccountingObject_.Presentation = NStr("vi = 'Hạch toán nội bộ (hạch toán với chi nhánh)';
														|ru = 'Внутрихозяйственные расчеты (расчеты с филиалами)';
														|en = 'Interbranch AR/AP (AR/AP accounting for branch offices)'; fa = 'Interbranch AR/AP (AR/AP accounting for branch offices)';
														|it = 'Внутрихозяйственные расчеты (расчеты с филиалами)';
														|pl = 'Rozliczenia wewnątrzgospodarcze (rozliczenia z filiami)';
														|tr = 'Yerel hesaplamalar (şubeler ile hesaplamalar)'");
	DescriptionOfAccountingObject_.TitleOfTheInvoiceSetupTable = NStr("vi = 'Tài khoản hạch toán nội bộ';
																		|ru = 'Счета учета внутрихозяйственных расчетов';
																		|en = 'Ledger accounts of interbranch AR/AP'; fa = 'Ledger accounts of interbranch AR/AP';
																		|it = 'Счета учета внутрихозяйственных расчетов';
																		|pl = 'Konta księgowe rozliczeń wewnątrzgospodarczych';
																		|tr = 'Yerel hesaplamaların defterikebir hesabı'");
	DescriptionOfAccountingObject_.DescriptionOfTheConfigurationObjectTypes = Undefined;
	DescriptionOfAccountingObject_.DescriptionOfTheAccountingLocationTypes = New TypeDescription();
	DescriptionOfAccountingObjectsForConfiguringForms.Insert(Enums.DeleteFinancialAccountingObjects.BranchOfficeAccounting, DescriptionOfAccountingObject_);
	
	DescriptionOfAccountingObject_ = DescriptionOfAccountingObjectForConfiguringForms();
	DescriptionOfAccountingObject_.Group = GroupsOfAccountingObjects.OtherAssetsAndLiabilities;
	DescriptionOfAccountingObject_.Presentation = NStr("vi = 'Giao dịch nội bộ theo tài sản được chọn';
														|ru = 'Внутрихозяйственные расчеты по выделенному имуществу';
														|en = 'Interbranch AR/AP for allocated property'; fa = 'دریافتنی/پرداختنی بین شعب بابت دارایی تخصیص‌یافته';
														|it = 'Внутрихозяйственные расчеты по выделенному имуществу';
														|pl = 'Rozliczenia wewnątrzgospodarcze według wydzielonego majątku';
														|tr = 'Seçili mülke ilişkin iç ticaret hesapları'");
	DescriptionOfAccountingObject_.TitleOfTheInvoiceSetupTable = NStr("vi = 'Tài khoản hạch toán nội bộ theo tài sản được chọn';
																		|ru = 'Счета учета внутрихозяйственных расчетов по выделенному имуществу';
																		|en = 'Ledger accounts of interbranch AR/AP for allocated property'; fa = 'Ledger accounts of interbranch AR/AP for allocated property';
																		|it = 'Счета учета внутрихозяйственных расчетов по выделенному имуществу';
																		|pl = 'Konta księgowe wewnątrzgospodarczych rozliczeń według wydzielonego majątku';
																		|tr = 'Seçili mülke ilişkin yerel hesaplamaların defterikebir hesabı'");
	DescriptionOfAccountingObject_.DescriptionOfTheConfigurationObjectTypes = Undefined;
	DescriptionOfAccountingObject_.DescriptionOfTheAccountingLocationTypes = New TypeDescription();
	DescriptionOfAccountingObjectsForConfiguringForms.Insert(Enums.DeleteFinancialAccountingObjects.BranchOfficeAssetsAccounting, DescriptionOfAccountingObject_);
	
	DescriptionOfAccountingObject_ = DescriptionOfAccountingObjectForConfiguringForms();
	DescriptionOfAccountingObject_.Group = GroupsOfAccountingObjects.OtherAssetsAndLiabilities;
	DescriptionOfAccountingObject_.Presentation = NStr("vi = 'Nợ giao hàng không có hóa đơn';
														|ru = 'Обязательства по неотфактурованным поставкам';
														|en = 'Liabilities for goods received not invoiced'; fa = 'بدهی‌ها بابت کالای دریافت‌شده بدون فاکتور';
														|it = 'Обязательства по неотфактурованным поставкам';
														|pl = 'Zobowiązania według niefakturowanych dostaw';
														|tr = 'Faturasız teslimatlara ilişkin yükümlülükler'");
	DescriptionOfAccountingObject_.TitleOfTheInvoiceSetupTable = NStr("vi = 'Tài khoản kế toán nợ phải trả khi giao hàng không có hóa đơn';
																		|ru = 'Счета учета обязательств по неотфактурованным поставкам';
																		|en = 'Ledger accounts of liabilities for goods received not invoiced'; fa = 'Ledger accounts of liabilities for goods received not invoiced';
																		|it = 'Счета учета обязательств по неотфактурованным поставкам';
																		|pl = 'Konta księgowe zobowiązań z tytułu niefakturowanych dostaw';
																		|tr = 'Faturasız teslimatlara ilişkin yükümlülüklerin defterikebir hesabı'");
	DescriptionOfAccountingObject_.DescriptionOfTheConfigurationObjectTypes = Undefined;
	DescriptionOfAccountingObject_.DescriptionOfTheAccountingLocationTypes = New TypeDescription();
	DescriptionOfAccountingObjectsForConfiguringForms.Insert(Enums.DeleteFinancialAccountingObjects.LiabilitiesForGoodsReceivedNotInvoiced, DescriptionOfAccountingObject_);
	
	If TransactionSettings.OptionForGeneratingTransactions = Undefined
	 Or TransactionSettings.OptionForGeneratingTransactions = Enums.EntryGenerationOptions.WithCorrespondence Then
		DescriptionOfAccountingObject_ = DescriptionOfAccountingObjectForConfiguringForms();
		DescriptionOfAccountingObject_.Group = GroupsOfAccountingObjects.OtherAssetsAndLiabilities;
		DescriptionOfAccountingObject_.Presentation = NStr("vi = 'Hạch toán đối trừ công nợ';
															|ru = 'Расчеты по взаимозачетам задолженности';
															|en = 'AR/AP accounting for AR/AP offset'; fa = 'حسابداری دریافتنی/پرداختنی برای تهاتر دریافتنی/پرداختنی';
															|it = 'Расчеты по взаимозачетам задолженности';
															|pl = 'Rozliczenia według rozliczeń wzajemnych zadłużenia';
															|tr = 'Alacak/Borç mahsubuna ilişkin hesaplamalar'");
		DescriptionOfAccountingObject_.TitleOfTheInvoiceSetupTable = NStr("vi = 'Tài khoản kế toán đối trừ công nợ';
																			|ru = 'Счета учета расчетов по взаимозачетам задолженности';
																			|en = 'Ledger accounts of AR/AP accounting for AR/AP offset'; fa = 'Ledger accounts of AR/AP accounting for AR/AP offset';
																			|it = 'Счета учета расчетов по взаимозачетам задолженности';
																			|pl = 'Konta księgowe rozliczeń według rozliczeń wzajemnych zadłużenia';
																			|tr = 'Alacak/Borç mahsubuna ilişkin hesaplamalar defterikebir hesabı'");
		DescriptionOfAccountingObject_.DescriptionOfTheConfigurationObjectTypes = Undefined;
		DescriptionOfAccountingObject_.DescriptionOfTheAccountingLocationTypes = New TypeDescription();
		DescriptionOfAccountingObjectsForConfiguringForms.Insert(Enums.DeleteFinancialAccountingObjects.ARAPSettlements, DescriptionOfAccountingObject_);
	EndIf;
	
	DescriptionOfAccountingObject_ = DescriptionOfAccountingObjectForConfiguringForms();
	DescriptionOfAccountingObject_.Group = GroupsOfAccountingObjects.OtherAssetsAndLiabilities;
	DescriptionOfAccountingObject_.Presentation = NStr("vi = 'Nhập số dư';
														|ru = 'Ввод остатков';
														|en = 'Balance entry'; fa = 'ورود مانده';
														|it = 'Ввод остатков';
														|pl = 'Wpisanie zapasów';
														|tr = 'Bakiyeyi gir'");
	DescriptionOfAccountingObject_.TitleOfTheInvoiceSetupTable = NStr("vi = 'Tài khoản phụ trợ để nhập số dư';
																		|ru = 'Вспомогательные счета для ввода остатков';
																		|en = 'Subaccounts for entering balance'; fa = 'Subaccounts for entering balance';
																		|it = 'Вспомогательные счета для ввода остатков';
																		|pl = 'Rachunki pomocnicze do wprowadzenia sald';
																		|tr = 'Bakiyeyi girmek için yardımcı hesaplar'");
	DescriptionOfAccountingObject_.DescriptionOfTheConfigurationObjectTypes = Undefined;
	DescriptionOfAccountingObject_.DescriptionOfTheAccountingLocationTypes = New TypeDescription();
	DescriptionOfAccountingObjectsForConfiguringForms.Insert(Enums.DeleteFinancialAccountingObjects.OBEntry, DescriptionOfAccountingObject_);

	#EndRegion
	
	FinancialAccountingByFinancialRegisterDataLocalization.AddExtendedDescriptionOfAccountingItemsToConfigure(
		DescriptionOfAccountingObjectsForConfiguringForms, GroupsOfAccountingObjects, TransactionSettings);
	
	#EndRegion
	
	ObjectCount = FinancialAccountingObjects.Count();
	
	For ReverseIndex = 1 To ObjectCount Do
		CurrentIndex = ObjectCount - ReverseIndex;
		AccountingObjectLine_ = FinancialAccountingObjects[CurrentIndex];
		
		ExtendedDescriptionOfObject = DescriptionOfAccountingObjectsForConfiguringForms[AccountingObjectLine_.AccountingObject];
		
		If ExtendedDescriptionOfObject <> Undefined Then
			FillPropertyValues(AccountingObjectLine_, ExtendedDescriptionOfObject);
		Else
			FinancialAccountingObjects.Delete(AccountingObjectLine_);
		EndIf;
	EndDo;
	
	FinancialAccountingObjects.Indexes.Add("AccountingObject");
	
	Return FinancialAccountingObjects;
	
EndFunction

// Returns a view of the accounting object with the group. 
// For example, "Settlements with clients-Debt".
//
// Parameters:
// 	AccountingObject - EnumRef.DeleteFinancialAccountingObjects - The object to get the extended view for
// 	ExtendedDescriptionOfAccountingObjects - See ExtendedDescriptionOfAccountingObjectsToConfigure
//
// Returns:
// 	String - 
Function PresentationOfAccountingObjectWithGroup(AccountingObject, ExtendedDescriptionOfAccountingObjects = Undefined) Export
	
	If ExtendedDescriptionOfAccountingObjects = Undefined Then
		ExtendedDescriptionOfAccountingObjects = ExtendedDescriptionOfAccountingObjectsToConfigure();
	EndIf;
	
	ExtendedDescriptionOfAccountingObject = ExtendedDescriptionOfAccountingObjects.Find(AccountingObject, "AccountingObject");
	If ExtendedDescriptionOfAccountingObject <> Undefined Then
		Result = ExtendedDescriptionOfAccountingObject.Group + " - " + ExtendedDescriptionOfAccountingObject.Presentation;
	Else
		Result = String(AccountingObject);
	EndIf;
	
	Return Result;
	
EndFunction

// Returns a tree of financial accounting objects for Presentation in Forms.
// 
// Parameters:
//  TransactionSettings - See Catalogs.FinancialAccountingPostingGenerationSetting.TransactionGenerationSettings
//  OnlyWithSetting - Boolean - manages the composition of accounting objects. True - only accounting objects with account settings, False - everything
// 
// Returns:
// 	ValueTree - LongDesc:
// * AccountingObject - EnumRef.DeleteFinancialAccountingObjects -
// * Presentation - String -
// * DataSource - String -
// * ImproperValues - Boolean -
// * TitleOfTheInvoiceSetupTable - String -
// * DescriptionOfTheConfigurationObjectTypes - TypeDescription -
// * DescriptionOfTheAccountingLocationTypes - TypeDescription -
// * IsFolder - Boolean -
//
Function TreeOfAccountingObjects(TransactionSettings, OnlyWithSetting = True) Export
	
	TreeOfAccountingObjects = New ValueTree();
	TreeOfAccountingObjects.Columns.Add("IsFolder", New TypeDescription("Boolean"));
	TreeOfAccountingObjects.Columns.Add("AccountingObject", New TypeDescription("EnumRef.DeleteFinancialAccountingObjects"));
	TreeOfAccountingObjects.Columns.Add("Presentation", New TypeDescription("String"));
	TreeOfAccountingObjects.Columns.Add("DataSource", New TypeDescription("String"));
	TreeOfAccountingObjects.Columns.Add("ImproperValues", New TypeDescription("Boolean"));
	TreeOfAccountingObjects.Columns.Add("TitleOfTheInvoiceSetupTable", New TypeDescription("String"));
	TreeOfAccountingObjects.Columns.Add("DescriptionOfTheConfigurationObjectTypes", New TypeDescription("TypeDescription"));
	TreeOfAccountingObjects.Columns.Add("DescriptionOfTheAccountingLocationTypes", New TypeDescription("TypeDescription"));
	TreeOfAccountingObjects.Columns.Add("SelectingConfigurationObjects", New TypeDescription("Structure,FixedArray"));
	TreeOfAccountingObjects.Columns.Add("AllocationOfLongTermAssetsAndLiabilities", New TypeDescription("Boolean"));
	
	If TransactionSettings.RevenueExcludingVAT = Undefined Then
		TransactionSettings.RevenueExcludingVAT = True;
	EndIf;
	
	DescriptionOfAccountingObjects = ExtendedDescriptionOfAccountingObjectsToConfigure(TransactionSettings);
	DescriptionOfAccountingObjects.Indexes.Add("Group");
	
	If Not OnlyWithSetting Then
		AddObjectDescriptionsWithoutSetting(DescriptionOfAccountingObjects, TransactionSettings);
	EndIf;
	
	For Each KeyAndValue In GroupsOfAccountingObjects(TransactionSettings) Do
		
		NewFolder = TreeOfAccountingObjects.Rows.Add();
		NewFolder.IsFolder = True;
		NewFolder.Presentation = KeyAndValue.Value;
		NewFolder.ImproperValues = True;
		
		SelectionResult_ = DescriptionOfAccountingObjects.FindRows(New Structure("Group", KeyAndValue.Value));
		AddedAccountingObjects = New Map();
		For Each TableRow In SelectionResult_ Do
			If AddedAccountingObjects[TableRow.AccountingObject] = Undefined
				And AccountingObjectIsAvailableByFunctionalOptions(TableRow) Then
				NewTreeRow = NewFolder.Rows.Add();
				FillPropertyValues(NewTreeRow, TableRow);
				NewFolder.ImproperValues = NewFolder.ImproperValues And TableRow.ImproperValues;
				If TypeOf(TableRow.SelectingConfigurationObjects) = Type("Array") Then
					NewTreeRow.SelectingConfigurationObjects = New FixedArray(TableRow.SelectingConfigurationObjects);
				EndIf;
				AddedAccountingObjects.Insert(NewTreeRow.AccountingObject, True);
			EndIf;
		EndDo;
	EndDo;
	
	TreeRowsToDelete = New Array;
	For Each TreeRow In TreeOfAccountingObjects.Rows Do
		If TreeRow.Rows.Count() = 0 Then
			TreeRowsToDelete.Add(TreeRow);
		EndIf;
	EndDo;
	
	For Each TreeRow In TreeRowsToDelete Do
		TreeOfAccountingObjects.Rows.Delete(TreeRow);
	EndDo;
	
	Return TreeOfAccountingObjects;
	
EndFunction

Function AccountingObjectIsAvailableByFunctionalOptions(DescriptionOfAccountingObject_) Export
	
	Return AccountingSectionIsAvailableByFunctionalOption(DescriptionOfAccountingObject_.FunctionalOptions);
	
EndFunction

Function TitleOfTypeDescriptionConfigurationObject(DescriptionOfTheConfigurationObjectTypes) Export
	
	PresentationsOfCustomizationObjects = New Array;
	For Each Type In DescriptionOfTheConfigurationObjectTypes.Types() Do
		MetadataOfConfigurationObject =  Metadata.FindByType(Type); 
		If Common.IsCatalog(MetadataOfConfigurationObject) And MetadataOfConfigurationObject.ObjectPresentation <> "" Then
			PresentationsOfCustomizationObjects.Add(MetadataOfConfigurationObject.ObjectPresentation);
		ElsIf Common.IsChartOfCharacteristicTypes(MetadataOfConfigurationObject) And MetadataOfConfigurationObject.ObjectPresentation <> "" Then
			PresentationsOfCustomizationObjects.Add(MetadataOfConfigurationObject.ObjectPresentation);
		Else
			PresentationsOfCustomizationObjects.Add(MetadataOfConfigurationObject.Presentation());
		EndIf;
	EndDo;
	
	Return StrConcat(PresentationsOfCustomizationObjects, ",");
	
EndFunction

Function ObjectSelectionParametersSetup(SelectingConfigurationObjects) Export
	
	If ValueIsFilled(SelectingConfigurationObjects)
	And TypeOf(SelectingConfigurationObjects) = Type("Structure") Then
		ArrayOfSettingsObjectSelectionParameters = New Array;
		For Each KeyAndValue In SelectingConfigurationObjects Do
			If TypeOf(KeyAndValue.Value) = Type("Array") Then
				ArrayOfValues_ = KeyAndValue.Value;
			Else
				ArrayOfValues_ = CommonClientServer.ValueInArray(KeyAndValue.Value);
			EndIf;
			ArrayOfSettingsObjectSelectionParameters.Add(
				New ChoiceParameter("Filter." + KeyAndValue.Key, New FixedArray(ArrayOfValues_)));
		EndDo;
		ChoiceParameters = New FixedArray(ArrayOfSettingsObjectSelectionParameters);
	Else
		ChoiceParameters = New FixedArray(New Array);
	EndIf;
	
	Return ChoiceParameters;
	
EndFunction

Function TitleOfAccountingLocation(DescriptionOfTheAccountingLocationTypes) Export
	
	AccountingPlacePresentations = New Array;
	For Each Type In DescriptionOfTheAccountingLocationTypes.Types() Do
		MetadataOfAccountingLocation =  Metadata.FindByType(Type);
		If Common.IsCatalog(MetadataOfAccountingLocation) And MetadataOfAccountingLocation.ObjectPresentation <> "" Then
			AccountingPlacePresentations.Add(MetadataOfAccountingLocation.ObjectPresentation);
		ElsIf Common.IsChartOfCharacteristicTypes(MetadataOfAccountingLocation) And MetadataOfAccountingLocation.ObjectPresentation <> "" Then
			AccountingPlacePresentations.Add(MetadataOfAccountingLocation.ObjectPresentation);
		Else
			AccountingPlacePresentations.Add(MetadataOfAccountingLocation.Presentation());
		EndIf;
	EndDo;
	
	Return StrConcat(AccountingPlacePresentations, ",");
	
EndFunction

Function DescriptionOfAccountingObjectForConfiguringForms() Export
	
	ObjectDetails = New Structure;
	
	ObjectDetails.Insert("Group", "");
	ObjectDetails.Insert("Presentation", "");
	ObjectDetails.Insert("TitleOfTheInvoiceSetupTable", "");
	ObjectDetails.Insert("DescriptionOfTheConfigurationObjectTypes", New TypeDescription());
	ObjectDetails.Insert("SelectingConfigurationObjects", New Structure);
	ObjectDetails.Insert("DescriptionOfTheAccountingLocationTypes", New TypeDescription());
	
	Return ObjectDetails;
	
EndFunction

Function GroupsOfAccountingObjects(TransactionSettings) Export
	
	GroupsOfAccountingObjects = New Structure;
	GroupsOfAccountingObjects.Insert("RoadsideFunds", NStr("vi = 'Tiền mặt, tiền gửi';
															|ru = 'Денежные средства';
															|en = 'Cash'; fa = 'صندوق';
															|it = 'Денежные средства';
															|pl = 'Środki pieniężne';
															|tr = 'Nakit'"));
	If TransactionSettings.MethodOfAccountingForImproperValues <> Enums.MethodsOfNotOwnedControlledValuesAccounting.NotRecordedOnAccounts
	   And TransactionSettings.MethodOfAccountingForImproperValues <> Enums.MethodsOfNotOwnedControlledValuesAccounting.EmptyRef() Then
		GroupsOfAccountingObjects.Insert("Products", NStr("vi = 'Mặt hàng sở hữu riêng';
															|ru = 'Номенклатура собственная';
															|en = 'Own item'; fa = 'Own item';
															|it = 'Номенклатура собственная';
															|pl = 'Produkt własny';
															|tr = 'Yerel ürün'"));
		GroupsOfAccountingObjects.Insert("ProductListIsAccepted", NStr("vi = 'Mặt hàng được tiếp nhận';
																		|ru = 'Номенклатура принятая';
																		|en = 'Received item'; fa = 'Received item';
																		|it = 'Номенклатура принятая';
																		|pl = 'Produkt przyjęty';
																		|tr = 'Kabul edilen ürünler'"));
	Else
		GroupsOfAccountingObjects.Insert("Products", NStr("vi = 'Mặt hàng';
															|ru = 'Номенклатура';
															|en = 'Items'; fa = 'اقلام';
															|it = 'Номенклатура';
															|pl = 'Items';
															|tr = 'Ürün'"));
	EndIf;
	GroupsOfAccountingObjects.Insert("FixedAssets", NStr("vi = 'Tài sản cố định hữu hình';
														|ru = 'Основные средства';
														|en = 'Fixed assets'; fa = 'دارایی‌های ثابت';
														|it = 'Основные средства';
														|pl = 'Środki trwałe';
														|tr = 'Sabit kıymetler'"));
	GroupsOfAccountingObjects.Insert("IntangibleAssets", NStr("vi = 'Tài sản cố định vô hình';
																|ru = 'Нематериальные активы';
																|en = 'Intangible assets'; fa = 'دارایی‌های نامشهود';
																|it = 'Нематериальные активы';
																|pl = 'Wartości niematerialne';
																|tr = 'Maddi olmayan varlıklar'"));
	GroupsOfAccountingObjects.Insert("CustomersARAPAccounting", NStr("vi = 'Hạch toán với khách hàng';
																	|ru = 'Расчеты с клиентами';
																	|en = 'Customer AR/AP'; fa = 'دریافتنی/پرداختنی مشتری';
																	|it = 'Расчеты с клиентами';
																	|pl = 'Rozliczenia z klientami';
																	|tr = 'Müşterilerle mutabakat'"));
	GroupsOfAccountingObjects.Insert("VendorsARAPAccounting", NStr("vi = 'Hạch toán với nhà cung cấp';
																	|ru = 'Расчеты с поставщиками';
																	|en = 'Vendor AR/AP'; fa = 'دریافتنی/پرداختنی تأمین‌کننده';
																	|it = 'Расчеты с поставщиками';
																	|pl = 'Rozliczenia z dostawcami';
																	|tr = 'Tedarikçi mutabakatı'"));
	GroupsOfAccountingObjects.Insert("LoansAndBorrowingsIssued", NStr("vi = 'Khoản tiền gửi, tín dụng và vay nợ đã chi';
																		|ru = 'Депозиты, кредиты и займы выданные';
																		|en = 'Deposits, credits and loans issued'; fa = 'Deposits, credits and loans issued';
																		|it = 'Депозиты, кредиты и займы выданные';
																		|pl = 'Depozyty, kredyty i pożyczki wydane';
																		|tr = 'Mevduatlar, krediler ve verilen borçlar'"));
	GroupsOfAccountingObjects.Insert("LoansAndBorrowingsReceived", NStr("vi = 'Khoản tín dụng và vay nợ đã nhận';
																		|ru = 'Кредиты и займы полученные';
																		|en = 'Received credits and loans'; fa = 'اعتبارات و وام‌های دریافتی';
																		|it = 'Кредиты и займы полученные';
																		|pl = 'Otrzymane kredyty i pożyczki';
																		|tr = 'Krediler ve alınan borçlar'"));
	GroupsOfAccountingObjects.Insert("SettlementsWithEmployees", NStr("vi = 'Hạch toán với nhân viên';
																		|ru = 'Расчеты с сотрудниками';
																		|en = 'AR/AP accounting for employees'; fa = 'AR/AP accounting for employees';
																		|it = 'Расчеты с сотрудниками';
																		|pl = 'Rozliczenia z pracownikami';
																		|tr = 'Çalışanlar ile mutabakat'"));
	GroupsOfAccountingObjects.Insert("ExpendableRent", NStr("vi = 'Nhận cho thuê';
															|ru = 'Получение в аренду';
															|en = 'Receive on lease'; fa = 'Receive on lease';
															|it = 'Получение в аренду';
															|pl = 'Receive on lease';
															|tr = 'Kiralama'"));
	GroupsOfAccountingObjects.Insert("ProfitableRent", NStr("vi = 'Chuyển giao cho thuê tài chính';
															|ru = 'Передача в финансовую аренду';
															|en = 'Transfer to financial lease'; fa = 'Transfer to financial lease';
															|it = 'Передача в финансовую аренду';
															|pl = 'Transfer to financial lease';
															|tr = 'Finansal kiralamaya transfer'"));
	GroupsOfAccountingObjects.Insert("WorkInProgress", NStr("vi = 'Sản xuất dở dang';
															|ru = 'Незавершенное производство';
															|en = 'Work-in-progress'; fa = 'کالای در جریان ساخت';
															|it = 'Незавершенное производство';
															|pl = 'Produkcja niezakończona';
															|tr = 'Devam eden imalat'"));
	GroupsOfAccountingObjects.Insert("IncomeAndExpenses", NStr("vi = 'Thu nhập và chi phí';
																|ru = 'Доходы и расходы';
																|en = 'Income and expenses'; fa = 'درآمدها و هزینه‌ها';
																|it = 'Доходы и расходы';
																|pl = 'Dochody i rozchody';
																|tr = 'Gelir ve giderler'"));
	GroupsOfAccountingObjects.Insert("VAT", NStr("vi = 'Thuế GTGT';
												|ru = 'НДС';
												|en = 'VAT'; fa = 'مالیات بر ارزش افزوده';
												|it = 'НДС';
												|pl = 'VAT';
												|tr = 'KDV'"));
	GroupsOfAccountingObjects.Insert("ProvisionsForImpairment", NStr("vi = 'Dự phòng giảm giá';
																	|ru = 'Резервы под обесценение';
																	|en = 'Provisions for impairment'; fa = 'Provisions for impairment';
																	|it = 'Резервы под обесценение';
																	|pl = 'Rezerwy pod utratę wartości';
																	|tr = 'Değer kaybının altında rezervler'"));
	GroupsOfAccountingObjects.Insert("WageReserves", NStr("vi = 'Dự phòng thanh toán tiền lương';
															|ru = 'Резервы по оплате труда';
															|en = 'Payroll funds'; fa = 'ذخایر حقوق و دستمزد';
															|it = 'Резервы по оплате труда';
															|pl = 'Payroll funds';
															|tr = 'Bordro rezervleri'"));
	GroupsOfAccountingObjects.Insert("LossAllowance", NStr("vi = 'Dự phòng nợ xấu';
															|ru = 'Резервы по сомнительным долгам';
															|en = 'Loss allowance'; fa = 'ذخیره زیان اعتباری';
															|it = 'Резервы по сомнительным долгам';
															|pl = 'Rezerwy z tytułu wątpliwych długów';
															|tr = 'Şüpheli borç karşılığı'"));
	GroupsOfAccountingObjects.Insert("FutureExpenseCommitments", NStr("vi = 'Dự phòng chi phí trả trước';
																		|ru = 'Резервы предстоящих расходов';
																		|en = 'Provisions and contingent liabilities'; fa = 'ذخایر و بدهی‌های احتمالی';
																		|it = 'Резервы предстоящих расходов';
																		|pl = 'Rezerwy przyszłych wydatków';
																		|tr = 'Karşılıklar ve şarta bağlı yükümlülükler'"));
	GroupsOfAccountingObjects.Insert("OtherAssetsAndLiabilities", NStr("vi = 'Tài sản và nợ phải trả khác';
																		|ru = 'Прочие активы и обязательства';
																		|en = 'Other assets and liabilities'; fa = 'سایر دارایی‌ها و بدهی‌ها';
																		|it = 'Прочие активы и обязательства';
																		|pl = 'Pozostałe aktywa i zobowiązania';
																		|tr = 'Diğer varlıklar ve yükümlülükler'"));
	
	Return GroupsOfAccountingObjects;
	
EndFunction

Function ItemsOfAssetsLiabilitiesWithSettings() Export
	
	AssetLiabilityItems = New Array();
	
	If GetFunctionalOption("SettingOfPostingByAccountingObjects") Then
		SetPrivilegedMode(True);
		FinancialAccountingObjects = DescriptionOfFinancialAccountingObjects();
		SetPrivilegedMode(False);
		
		TheStructureOfTheSearch = New Structure("DataSource", Metadata.AccumulationRegisters.OtherAssetsAndLiabilitiesRecords.Name);
		OtherAssetsAndLiabilities = FinancialAccountingObjects.FindRows(TheStructureOfTheSearch);
		
		For Each AccountingObjectLine_ In OtherAssetsAndLiabilities Do
			FillInArticlesFromSelectionSettings(AssetLiabilityItems, AccountingObjectLine_.Filterdata_);
		EndDo;
	EndIf;
	
	Return AssetLiabilityItems;
	
EndFunction

#EndRegion

#Region EventHandlers

Procedure ChoiceDataGetProcessing(ChoiceData, Parameters, StandardProcessing)
	
	StandardProcessing = False;
	ArrayOfExcludedValues = New Array;
	
	FinancialAccountingObjects = DescriptionOfFinancialAccountingObjects();
	For Each TableRow In FinancialAccountingObjects Do
		If Not AccountingObjectIsAvailableByFunctionalOptions(TableRow) Then
			ArrayOfExcludedValues.Add(TableRow.AccountingObject);
		EndIf;
	EndDo;
	
	TMCommonUse.SelectableEnumerationValues(
		EmptyRef().Metadata().Name,
		ChoiceData,
		Parameters,
		ArrayOfExcludedValues);
		
EndProcedure

#EndRegion

#Region Private

Function AccountingSectionIsAvailableByFunctionalOption(FunctionalOption)
	
	FOValueType = TypeOf(FunctionalOption);
	
	If FOValueType = Type("String") Then
		ThisSectionIsAvailableByFO = GetFunctionalOption(FunctionalOption);
	ElsIf FOValueType = Type("Array") Then
		ThisSectionIsAvailableByFO = False;
		For Each ArrayElement In FunctionalOption Do
			If AccountingSectionIsAvailableByFunctionalOption(ArrayElement) Then
				ThisSectionIsAvailableByFO = True;
				Break;
			EndIf;
		EndDo;
	ElsIf FOValueType = Type("ValueList") Then
		ThisSectionIsAvailableByFO = True;
		For Each ListItem In FunctionalOption Do
			If Not AccountingSectionIsAvailableByFunctionalOption(ListItem.Value) Then
				ThisSectionIsAvailableByFO = False;
				Break;
			EndIf;
		EndDo;
	Else
		ThisSectionIsAvailableByFO = True;
	EndIf;
	
	Return ThisSectionIsAvailableByFO;
	
EndFunction

Procedure AddColumnsForExtendedDescriptionOfAccountingItems(FinancialAccountingObjects)
	
	For Each KeyAndValue In DescriptionOfAccountingObjectForConfiguringForms() Do
		TypesArray = New Array;
		TypesArray.Add(TypeOf(KeyAndValue.Value));
		If KeyAndValue.Key = "SelectingConfigurationObjects" Then
			TypesArray.Add(Type("Array"));
		EndIf;
		FinancialAccountingObjects.Columns.Add(KeyAndValue.Key, New TypeDescription(TypesArray));
	EndDo;
	
EndProcedure

Procedure AddObjectDescriptionsWithoutSetting(DescriptionOfAccountingObjects, TransactionSettings)
	
	GroupsOfAccountingObjects = GroupsOfAccountingObjects(TransactionSettings);
	FinancialAccountingObjects = DescriptionOfFinancialAccountingObjects(TransactionSettings);
	
	#Region OtherAssetsAndLiabilities
	
	ObjectOfFinancialAccounting = FinancialAccountingObjects.Find(Enums.DeleteFinancialAccountingObjects.OtherAssetsLiabilities, "AccountingObject");
	If ObjectOfFinancialAccounting <> Undefined Then
		DescriptionOfTheAccountingObject = DescriptionOfAccountingObjects.Add();
		FillPropertyValues(DescriptionOfTheAccountingObject, ObjectOfFinancialAccounting);
		DescriptionOfTheAccountingObject.Group = GroupsOfAccountingObjects.OtherAssetsAndLiabilities;
		DescriptionOfTheAccountingObject.Presentation = NStr("vi = 'Tài sản và nguồn vốn khác';
															|ru = 'Прочие активы и пассивы';
															|en = 'Other assets and liabilities'; fa = 'سایر دارایی‌ها و بدهی‌ها';
															|it = 'Прочие активы и пассивы';
															|pl = 'Inne aktywa i pasywa';
															|tr = 'Diğer varlıklar ve yükümlülükler'");
	EndIf;
	
	#EndRegion
	
EndProcedure

#Region FillingInPropertiesOfFinancialAccountingObjects

Procedure FillInAccountingItemsCash(FinancialAccountingObjects, TransactionSettings)
	
	CashInCashLine = FinancialAccountingObjects.Add();
	CashInCashLine.AccountingObject = Enums.DeleteFinancialAccountingObjects.CashInCashRegisters;
	
	LineCashAtCashRegisterCashDesks = FinancialAccountingObjects.Add();
	LineCashAtCashRegisterCashDesks.AccountingObject = Enums.DeleteFinancialAccountingObjects.CashInCashRegistersCR;
	LineCashAtCashRegisterCashDesks.FunctionalOptions = Metadata.FunctionalOptions.UseRetailSales.Name;
	
	LineCashOnAccounts = FinancialAccountingObjects.Add();
	LineCashOnAccounts.AccountingObject = Enums.DeleteFinancialAccountingObjects.BankAccountBalance;
	
	LineCashInTransit = FinancialAccountingObjects.Add();
	LineCashInTransit.AccountingObject = Enums.DeleteFinancialAccountingObjects.CashInTransit;
	
EndProcedure

Procedure FillInAccountingItemsProducts(FinancialAccountingObjects, TransactionSettings)
	
	HFCProductSampleField = FinancialAccountingByBalanceSheetRegisterData.HFCProductSampleField();
	
	ProductsReleaseLine = FinancialAccountingObjects.Add();
	ProductsReleaseLine.AccountingObject = Enums.DeleteFinancialAccountingObjects.ProductsRelease;
	ProductsReleaseLine.FunctionalOptions = Metadata.FunctionalOptions.UseProduction.Name;
	Filterdata_ = New Map();
	Filterdata_.Insert("AccountingSection", Enums.SectionsOfInventoryCostAccounting.ProductsRelease);
	ProductsReleaseLine.Filterdata_ = Filterdata_;
	ProductsReleaseLine.DataPathConfigurationObject = HFCProductSampleField;
	ProductsReleaseLine.ManResources = ManSOwnProductInventoryResources();
	ProductsReleaseLine.LocalResources = ResourcesForAccountingForYourOwnLocalProductList();
	
	LineProductsInStock = FinancialAccountingObjects.Add();
	LineProductsInStock.AccountingObject = Enums.DeleteFinancialAccountingObjects.InventoryItemsInStock;
	Filterdata_ = New Map();
	Filterdata_.Insert("AccountingSection", Enums.SectionsOfInventoryCostAccounting.ProductStock);
	LineProductsInStock.Filterdata_ = Filterdata_;
	LineProductsInStock.DataPathConfigurationObject = HFCProductSampleField;
	LineProductsInStock.ManResources = ManSOwnProductInventoryResources();
	LineProductsInStock.LocalResources = ResourcesForAccountingForYourOwnLocalProductList();
	
	StringProductsInTransit = FinancialAccountingObjects.Add();
	StringProductsInTransit.AccountingObject = Enums.DeleteFinancialAccountingObjects.ItemInTransit;
	Filterdata_ = New Map();
	Filterdata_.Insert("AccountingSection", Enums.SectionsOfInventoryCostAccounting.OwnGoodsInTransitFromVendors);
	StringProductsInTransit.Filterdata_ = Filterdata_;
	StringProductsInTransit.DataPathConfigurationObject = HFCProductSampleField;
	StringProductsInTransit.ManResources = ManSOwnProductInventoryResources();
	StringProductsInTransit.LocalResources = ResourcesForAccountingForYourOwnLocalProductList();
	
	LineProductsInShopPantry = FinancialAccountingObjects.Add();
	LineProductsInShopPantry.AccountingObject = Enums.DeleteFinancialAccountingObjects.ItemsInShopStoreroom;
	LineProductsInShopPantry.FunctionalOptions = Metadata.FunctionalOptions.UseProduction.Name;
	Filterdata_ = New Map();
	AccountingSections = New Array();
	AccountingSections.Add(Enums.SectionsOfInventoryCostAccounting.ProductionCosts);
	AccountingSections.Add(Enums.SectionsOfInventoryCostAccounting.GoodsReceivedForRespSafekeeping);
	AccountingSections.Add(Enums.SectionsOfInventoryCostAccounting.VendorManagedInventoryTransferredToPartners);
	Filterdata_.Insert("AccountingSection", AccountingSections);
	Filterdata_.Insert("ItemsLocationAttributes.StorageType", Enums.StorageLocationTypes.Warehouse);
	LineProductsInShopPantry.Filterdata_ = Filterdata_;
	LineProductsInShopPantry.DataPathConfigurationObject = HFCProductSampleField;
	LineProductsInShopPantry.ManResources = ManSOwnProductInventoryResources();
	LineProductsInShopPantry.LocalResources = ResourcesForAccountingForYourOwnLocalProductList();
	
	LineProductsShipped = FinancialAccountingObjects.Add();
	LineProductsShipped.AccountingObject = Enums.DeleteFinancialAccountingObjects.ItemShipped;
	Filterdata_ = New Map();
	AccountingSections = New Array();
	AccountingSections.Add(Enums.SectionsOfInventoryCostAccounting.GoodsInTransit);
	AccountingSections.Add(Enums.SectionsOfInventoryCostAccounting.GoodsInTransitTransferredToCommissionAgent);
	Filterdata_.Insert("AccountingSection", AccountingSections);
	LineProductsShipped.Filterdata_ = Filterdata_;
	LineProductsShipped.DataPathConfigurationObject = HFCProductSampleField;
	LineProductsShipped.ManResources = ManSOwnProductInventoryResources();
	LineProductsShipped.LocalResources = ResourcesForAccountingForYourOwnLocalProductList();
	PathsToExtdimensionData = New Map();
	PathsToExtdimensionData.Insert(ChartsOfCharacteristicTypes.FinancialExtraDimensionTypes.Counterparties, "ItemsLocationAttributes.Counterparty");
	LineProductsShipped.PathsToExtdimensionData = PathsToExtdimensionData;
	
	LineProductsSubmittedForProcessing = FinancialAccountingObjects.Add();
	LineProductsSubmittedForProcessing.AccountingObject = Enums.DeleteFinancialAccountingObjects.ItemTransferredForProcessing;
	FunctionalOptions = New Array();
	FunctionalOptions.Add(Metadata.FunctionalOptions.UseProductionByThirdParty2_5.Name);
	LineProductsSubmittedForProcessing.FunctionalOptions = FunctionalOptions;
	Filterdata_ = New Map();
	Filterdata_.Insert("AccountingSection", Enums.SectionsOfInventoryCostAccounting.GoodsTransferredToToller);
	LineProductsSubmittedForProcessing.Filterdata_ = Filterdata_;
	LineProductsSubmittedForProcessing.DataPathConfigurationObject = HFCProductSampleField;
	LineProductsSubmittedForProcessing.ManResources = ManSOwnProductInventoryResources();
	LineProductsSubmittedForProcessing.LocalResources = ResourcesForAccountingForYourOwnLocalProductList();
	
	StringProductsTransferredForStorage = FinancialAccountingObjects.Add();
	StringProductsTransferredForStorage.AccountingObject = Enums.DeleteFinancialAccountingObjects.ItemTransferredForStorage;
	StringProductsTransferredForStorage.FunctionalOptions = Metadata.FunctionalOptions.UseTransferToCustodyWithRightOfSale.Name;
	Filterdata_ = New Map();
	Filterdata_.Insert("AccountingSection", Enums.SectionsOfInventoryCostAccounting.OwnGoodsTransferredToPartners);
	StringProductsTransferredForStorage.Filterdata_ = Filterdata_;
	StringProductsTransferredForStorage.DataPathConfigurationObject = HFCProductSampleField;
	StringProductsTransferredForStorage.ManResources = ManSOwnProductInventoryResources();
	StringProductsTransferredForStorage.LocalResources = ResourcesForAccountingForYourOwnLocalProductList();
	
	LineProductsSubmittedToCommission = FinancialAccountingObjects.Add();
	LineProductsSubmittedToCommission.AccountingObject = Enums.DeleteFinancialAccountingObjects.ItemsSubmittedForCommission;
	LineProductsSubmittedToCommission.FunctionalOptions = Metadata.FunctionalOptions.UseSalesCommission.Name;
	Filterdata_ = New Map();
	Filterdata_.Insert("AccountingSection", Enums.SectionsOfInventoryCostAccounting.GoodsTransferredToCommissionAgent);
	LineProductsSubmittedToCommission.Filterdata_ = Filterdata_;
	LineProductsSubmittedToCommission.DataPathConfigurationObject = HFCProductSampleField;
	LineProductsSubmittedToCommission.ManResources = ManSOwnProductInventoryResources();
	LineProductsSubmittedToCommission.LocalResources = ResourcesForAccountingForYourOwnLocalProductList();
	PathsToExtdimensionData = New Map();
	PathsToExtdimensionData.Insert(ChartsOfCharacteristicTypes.FinancialExtraDimensionTypes.Counterparties, "ItemsLocationAttributes.Counterparty");
	LineProductsSubmittedToCommission.PathsToExtdimensionData = PathsToExtdimensionData;
	
	// Other sections of cost accounting that are not described in the selections of accounting items should not be read
	SuppressDataWithoutSelectingByResourceComposition(FinancialAccountingObjects,
		Undefined,
		Metadata.AccumulationRegisters.InventoryCost.Name,
		ManSOwnProductInventoryResources(),
		ResourcesForAccountingForYourOwnLocalProductList());
	
	DeviationLineInCostOfItem = FinancialAccountingObjects.Add();
	DeviationLineInCostOfItem.AccountingObject = Enums.DeleteFinancialAccountingObjects.ItemCostVariances;
	
	If TransactionSettings.MethodOfAccountingForImproperValues <> Enums.MethodsOfNotOwnedControlledValuesAccounting.NotRecordedOnAccounts
	   And TransactionSettings.MethodOfAccountingForImproperValues <> Enums.MethodsOfNotOwnedControlledValuesAccounting.EmptyRef() Then
		ProductLineAcceptedForProcessingInWarehouse = FinancialAccountingObjects.Add();
		ProductLineAcceptedForProcessingInWarehouse.AccountingObject = Enums.DeleteFinancialAccountingObjects.ItemReceivedForSubcontractingAtAWarehouse;
		FunctionalOptions = New Array();
		FunctionalOptions.Add(Metadata.FunctionalOptions.UseTollManufacturing2_5.Name);
		ProductLineAcceptedForProcessingInWarehouse.FunctionalOptions = FunctionalOptions;
		Filterdata_ = New Map();
		Filterdata_.Insert("AccountingSection", Enums.SectionsOfInventoryCostAccounting.MaterialsReceivedForProcessing);
		Filterdata_.Insert("ItemsLocationAttributes.StorageType", Enums.StorageLocationTypes.Warehouse);
		Filterdata_.Insert(StrReplace(
			"CAST(DataSourceAlias.ItemsLocationAttributes.StorageLocation AS Catalog.Warehouses).ShopFloorStockroom",
			"DataSourceAlias",
			FinancialAccountingByBalanceSheetRegisterData.DefaultDataSourceAlias()),
			False);
		ProductLineAcceptedForProcessingInWarehouse.Filterdata_ = Filterdata_;
		ProductLineAcceptedForProcessingInWarehouse.ImproperValues = True;
		ProductLineAcceptedForProcessingInWarehouse.DataPathConfigurationObject = HFCProductSampleField;
		ProductLineAcceptedForProcessingInWarehouse.ManResources = ResourcesForAccountingForAcceptedItemOfMan();
		ProductLineAcceptedForProcessingInWarehouse.LocalResources = ResourcesForAccountingForAcceptedItemOfLocalRegulations();
		PathsToExtdimensionData = New Map();
		PathsToExtdimensionData.Insert(ChartsOfCharacteristicTypes.FinancialExtraDimensionTypes.Counterparties, "InventoryOwnerAttribute.Counterparty");
		ProductLineAcceptedForProcessingInWarehouse.PathsToExtdimensionData = PathsToExtdimensionData;
		
		StringProductAcceptedForProcessingInPantry = FinancialAccountingObjects.Add();
		StringProductAcceptedForProcessingInPantry.AccountingObject = Enums.DeleteFinancialAccountingObjects.ItemReceivedForSubcontractingInAShopFloorStockroom;
		FunctionalOptions = New Array();
		FunctionalOptions.Add(Metadata.FunctionalOptions.UseTollManufacturing2_5.Name);
		StringProductAcceptedForProcessingInPantry.FunctionalOptions = FunctionalOptions;
		Filterdata_ = New Map();
		Filterdata_.Insert("AccountingSection", Enums.SectionsOfInventoryCostAccounting.MaterialsReceivedForProcessing);
		Filterdata_.Insert("ItemsLocationAttributes.StorageType", Enums.StorageLocationTypes.Warehouse);
		Filterdata_.Insert(StrReplace(
			"CAST(DataSourceAlias.ItemsLocationAttributes.StorageLocation AS Catalog.Warehouses).ShopFloorStockroom",
			"DataSourceAlias",
			FinancialAccountingByBalanceSheetRegisterData.DefaultDataSourceAlias()),
			True);
		StringProductAcceptedForProcessingInPantry.Filterdata_ = Filterdata_;
		StringProductAcceptedForProcessingInPantry.ImproperValues = True;
		StringProductAcceptedForProcessingInPantry.DataPathConfigurationObject = HFCProductSampleField;
		StringProductAcceptedForProcessingInPantry.ManResources = ResourcesForAccountingForAcceptedItemOfMan();
		StringProductAcceptedForProcessingInPantry.LocalResources = ResourcesForAccountingForAcceptedItemOfLocalRegulations();
		PathsToExtdimensionData = New Map();
		PathsToExtdimensionData.Insert(ChartsOfCharacteristicTypes.FinancialExtraDimensionTypes.Counterparties, "InventoryOwnerAttribute.Counterparty");
		StringProductAcceptedForProcessingInPantry.PathsToExtdimensionData = PathsToExtdimensionData;
		
		RowProductAcceptedForProcessingFromPartners = FinancialAccountingObjects.Add();
		RowProductAcceptedForProcessingFromPartners.AccountingObject = Enums.DeleteFinancialAccountingObjects.ProductsReceivedForSubcontractingTransferredToPartners;
		FunctionalOptions = New Array();
		FunctionalOptions.Add(Metadata.FunctionalOptions.UseTollManufacturing2_5.Name);
		RowProductAcceptedForProcessingFromPartners.FunctionalOptions = FunctionalOptions;
		Filterdata_ = New Map();
		Filterdata_.Insert("AccountingSection", Enums.SectionsOfInventoryCostAccounting.MaterialsReceivedForSubcontractingTransferredToPartners);
		RowProductAcceptedForProcessingFromPartners.Filterdata_ = Filterdata_;
		RowProductAcceptedForProcessingFromPartners.ImproperValues = True;
		RowProductAcceptedForProcessingFromPartners.DataPathConfigurationObject = HFCProductSampleField;
		RowProductAcceptedForProcessingFromPartners.ManResources = ResourcesForAccountingForAcceptedItemOfMan();
		RowProductAcceptedForProcessingFromPartners.LocalResources = ResourcesForAccountingForAcceptedItemOfLocalRegulations();
		PathsToExtdimensionData = New Map();
		PathsToExtdimensionData.Insert(ChartsOfCharacteristicTypes.FinancialExtraDimensionTypes.Counterparties, "InventoryOwnerAttribute.Counterparty");
		RowProductAcceptedForProcessingFromPartners.PathsToExtdimensionData = PathsToExtdimensionData;
		
		RowLineAcceptedForProcessingForWriteOff = FinancialAccountingObjects.Add();
		RowLineAcceptedForProcessingForWriteOff.AccountingObject = Enums.DeleteFinancialAccountingObjects.ProductsReceivedForSubcontractingToWriteOff;
		FunctionalOptions = New Array();
		FunctionalOptions.Add(Metadata.FunctionalOptions.UseTollManufacturing2_5.Name);
		RowLineAcceptedForProcessingForWriteOff.FunctionalOptions = FunctionalOptions;
		Filterdata_ = New Map();
		Filterdata_.Insert("AccountingSection", Enums.SectionsOfInventoryCostAccounting.MaterialsReceivedForSubcontractingToRegisterWriteOff);
		RowLineAcceptedForProcessingForWriteOff.Filterdata_ = Filterdata_;
		RowLineAcceptedForProcessingForWriteOff.ImproperValues = True;
		RowLineAcceptedForProcessingForWriteOff.DataPathConfigurationObject = HFCProductSampleField;
		RowLineAcceptedForProcessingForWriteOff.ManResources = ResourcesForAccountingForAcceptedItemOfMan();
		RowLineAcceptedForProcessingForWriteOff.LocalResources = ResourcesForAccountingForAcceptedItemOfLocalRegulations();
		PathsToExtdimensionData = New Map();
		PathsToExtdimensionData.Insert(ChartsOfCharacteristicTypes.FinancialExtraDimensionTypes.Counterparties, "InventoryOwnerAttribute.Counterparty");
		RowLineAcceptedForProcessingForWriteOff.PathsToExtdimensionData = PathsToExtdimensionData;
		
		ProductLineAcceptedForStorageInWarehouse = FinancialAccountingObjects.Add();
		ProductLineAcceptedForStorageInWarehouse.AccountingObject = Enums.DeleteFinancialAccountingObjects.ItemReceivedForStorageAtAWarehouse;
		FunctionalOptions = New Array();
		FunctionalOptions.Add(Metadata.FunctionalOptions.UseTollManufacturing2_5.Name);
		FunctionalOptions.Add(Metadata.FunctionalOptions.UseCustodyDuringPurchase.Name);
		ProductLineAcceptedForStorageInWarehouse.FunctionalOptions = FunctionalOptions;
		Filterdata_ = New Map();
		AccountingSections = New Array();
		AccountingSections.Add(Enums.SectionsOfInventoryCostAccounting.GoodsReceivedForRespSafekeeping);
		AccountingSections.Add(Enums.SectionsOfInventoryCostAccounting.GoodsAtStorageWithRightOfSale);
		Filterdata_.Insert("AccountingSection", AccountingSections);
		Filterdata_.Insert("ItemsLocationAttributes.StorageType", Enums.StorageLocationTypes.Warehouse);
		Filterdata_.Insert(StrReplace(
			"CAST(DataSourceAlias.ItemsLocationAttributes.StorageLocation AS Catalog.Warehouses).ShopFloorStockroom",
			"DataSourceAlias",
			FinancialAccountingByBalanceSheetRegisterData.DefaultDataSourceAlias()),
			False);
		ProductLineAcceptedForStorageInWarehouse.Filterdata_ = Filterdata_;
		ProductLineAcceptedForStorageInWarehouse.ImproperValues = True;
		ProductLineAcceptedForStorageInWarehouse.DataPathConfigurationObject = HFCProductSampleField;
		ProductLineAcceptedForStorageInWarehouse.ManResources = ResourcesForAccountingForAcceptedItemOfMan();
		ProductLineAcceptedForStorageInWarehouse.LocalResources = ResourcesForAccountingForAcceptedItemOfLocalRegulations();
		PathsToExtdimensionData = New Map();
		PathsToExtdimensionData.Insert(ChartsOfCharacteristicTypes.FinancialExtraDimensionTypes.Counterparties, "InventoryOwnerAttribute.Counterparty");
		ProductLineAcceptedForStorageInWarehouse.PathsToExtdimensionData = PathsToExtdimensionData;
		
		StringProductAcceptedForStorageInPantry = FinancialAccountingObjects.Add();
		StringProductAcceptedForStorageInPantry.AccountingObject = Enums.DeleteFinancialAccountingObjects.ItemReceivedForStorageInAShopFloorStockroom;
		FunctionalOptions = New Array();
		FunctionalOptions.Add(Metadata.FunctionalOptions.UseTollManufacturing2_5.Name);
		FunctionalOptions.Add(Metadata.FunctionalOptions.UseCustodyDuringPurchase.Name);
		StringProductAcceptedForStorageInPantry.FunctionalOptions = FunctionalOptions;
		Filterdata_ = New Map();
		AccountingSections = New Array();
		AccountingSections.Add(Enums.SectionsOfInventoryCostAccounting.GoodsReceivedForRespSafekeeping);
		AccountingSections.Add(Enums.SectionsOfInventoryCostAccounting.GoodsAtStorageWithRightOfSale);
		Filterdata_.Insert("AccountingSection", AccountingSections);
		Filterdata_.Insert("ItemsLocationAttributes.StorageType", Enums.StorageLocationTypes.Warehouse);
		Filterdata_.Insert(StrReplace(
			"CAST(DataSourceAlias.ItemsLocationAttributes.StorageLocation AS Catalog.Warehouses).ShopFloorStockroom",
			"DataSourceAlias",
			FinancialAccountingByBalanceSheetRegisterData.DefaultDataSourceAlias()),
			True);
		StringProductAcceptedForStorageInPantry.Filterdata_ = Filterdata_;
		StringProductAcceptedForStorageInPantry.ImproperValues = True;
		StringProductAcceptedForStorageInPantry.DataPathConfigurationObject = HFCProductSampleField;
		StringProductAcceptedForStorageInPantry.ManResources = ResourcesForAccountingForAcceptedItemOfMan();
		StringProductAcceptedForStorageInPantry.LocalResources = ResourcesForAccountingForAcceptedItemOfLocalRegulations();
		PathsToExtdimensionData = New Map();
		PathsToExtdimensionData.Insert(ChartsOfCharacteristicTypes.FinancialExtraDimensionTypes.Counterparties, "InventoryOwnerAttribute.Counterparty");
		StringProductAcceptedForStorageInPantry.PathsToExtdimensionData = PathsToExtdimensionData;
		
		RowProductAcceptedForStorageFromPartners = FinancialAccountingObjects.Add();
		RowProductAcceptedForStorageFromPartners.AccountingObject = Enums.DeleteFinancialAccountingObjects.VMITransferredToPartners;
		FunctionalOptions = New Array();
		FunctionalOptions.Add(Metadata.FunctionalOptions.UseTollManufacturing2_5.Name);
		FunctionalOptions.Add(Metadata.FunctionalOptions.UseCustodyDuringPurchase.Name);
		RowProductAcceptedForStorageFromPartners.FunctionalOptions = FunctionalOptions;
		Filterdata_ = New Map();
		AccountingSections = New Array();
		AccountingSections.Add(Enums.SectionsOfInventoryCostAccounting.VendorManagedInventoryTransferredToPartners);
		AccountingSections.Add(Enums.SectionsOfInventoryCostAccounting.GoodsInCustodyWithSalesTransferredToPartners);
		Filterdata_.Insert("AccountingSection", AccountingSections);
		RowProductAcceptedForStorageFromPartners.Filterdata_ = Filterdata_;
		RowProductAcceptedForStorageFromPartners.ImproperValues = True;
		RowProductAcceptedForStorageFromPartners.DataPathConfigurationObject = HFCProductSampleField;
		RowProductAcceptedForStorageFromPartners.ManResources = ResourcesForAccountingForAcceptedItemOfMan();
		RowProductAcceptedForStorageFromPartners.LocalResources = ResourcesForAccountingForAcceptedItemOfLocalRegulations();
		PathsToExtdimensionData = New Map();
		PathsToExtdimensionData.Insert(ChartsOfCharacteristicTypes.FinancialExtraDimensionTypes.Counterparties, "InventoryOwnerAttribute.Counterparty");
		RowProductAcceptedForStorageFromPartners.PathsToExtdimensionData = PathsToExtdimensionData;
		
		RowProductAcceptedForStorageForWriteOff = FinancialAccountingObjects.Add();
		RowProductAcceptedForStorageForWriteOff.AccountingObject = Enums.DeleteFinancialAccountingObjects.VMIToWriteOff;
		FunctionalOptions = New Array();
		FunctionalOptions.Add(Metadata.FunctionalOptions.UseTollManufacturing2_5.Name);
		FunctionalOptions.Add(Metadata.FunctionalOptions.UseCustodyDuringPurchase.Name);
		RowProductAcceptedForStorageForWriteOff.FunctionalOptions = FunctionalOptions;
		Filterdata_ = New Map();
		AccountingSections = New Array();
		AccountingSections.Add(Enums.SectionsOfInventoryCostAccounting.VendorManagedInventoryToRegisterWriteOff);
		AccountingSections.Add(Enums.SectionsOfInventoryCostAccounting.GoodsInStorageWithRightOfSaleToRegisterWriteOff);
		Filterdata_.Insert("AccountingSection", AccountingSections);
		RowProductAcceptedForStorageForWriteOff.Filterdata_ = Filterdata_;
		RowProductAcceptedForStorageForWriteOff.ImproperValues = True;
		RowProductAcceptedForStorageForWriteOff.DataPathConfigurationObject = HFCProductSampleField;
		RowProductAcceptedForStorageForWriteOff.ManResources = ResourcesForAccountingForAcceptedItemOfMan();
		RowProductAcceptedForStorageForWriteOff.LocalResources = ResourcesForAccountingForAcceptedItemOfLocalRegulations();
		PathsToExtdimensionData = New Map();
		PathsToExtdimensionData.Insert(ChartsOfCharacteristicTypes.FinancialExtraDimensionTypes.Counterparties, "InventoryOwnerAttribute.Counterparty");
		RowProductAcceptedForStorageForWriteOff.PathsToExtdimensionData = PathsToExtdimensionData;
		
		ProductLineAcceptedForCommission = FinancialAccountingObjects.Add();
		ProductLineAcceptedForCommission.AccountingObject = Enums.DeleteFinancialAccountingObjects.ConsignedItemReceived;
		ProductLineAcceptedForCommission.FunctionalOptions = Metadata.FunctionalOptions.UseSalesCommission.Name;
		Filterdata_ = New Map();
		Filterdata_.Insert("AccountingSection", Enums.SectionsOfInventoryCostAccounting.GoodsReceivedByCommissionAgent);
		Filterdata_.Insert("ItemsLocationAttributes.StorageType", Enums.StorageLocationTypes.Warehouse);
		ProductLineAcceptedForCommission.Filterdata_ = Filterdata_;
		ProductLineAcceptedForCommission.ImproperValues = True;
		ProductLineAcceptedForCommission.DataPathConfigurationObject = HFCProductSampleField;
		ProductLineAcceptedForCommission.ManResources = ResourcesForAccountingForAcceptedItemOfMan();
		ProductLineAcceptedForCommission.LocalResources = ResourcesForAccountingForAcceptedItemOfLocalRegulations();
		
		ProductLineSubmittedToSubCommission = FinancialAccountingObjects.Add();
		ProductLineSubmittedToSubCommission.AccountingObject = Enums.DeleteFinancialAccountingObjects.ItemHandedOverToSubConsignment;
		ProductLineSubmittedToSubCommission.FunctionalOptions = Metadata.FunctionalOptions.UseSalesCommission.Name;
		Filterdata_ = New Map();
		Filterdata_.Insert("AccountingSection", Enums.SectionsOfInventoryCostAccounting.GoodsReceivedByCommissionAgent);
		StorageLocationsOfProductOnSubCommission = New Array();
		StorageLocationsOfProductOnSubCommission.Add(Enums.StorageLocationTypes.Partner);
		StorageLocationsOfProductOnSubCommission.Add(Enums.StorageLocationTypes.Organization);
		Filterdata_.Insert("ItemsLocationAttributes.StorageType", StorageLocationsOfProductOnSubCommission);
		ProductLineSubmittedToSubCommission.Filterdata_ = Filterdata_;
		ProductLineSubmittedToSubCommission.ImproperValues = True;
		ProductLineSubmittedToSubCommission.DataPathConfigurationObject = HFCProductSampleField;
		ProductLineSubmittedToSubCommission.ManResources = ResourcesForAccountingForAcceptedItemOfMan();
		ProductLineSubmittedToSubCommission.LocalResources = ResourcesForAccountingForAcceptedItemOfLocalRegulations();
		PathsToExtdimensionData = New Map();
		PathsToExtdimensionData.Insert(ChartsOfCharacteristicTypes.FinancialExtraDimensionTypes.Counterparties, "ItemsLocationAttributes.StorageLocation");
		ProductLineSubmittedToSubCommission.PathsToExtdimensionData = PathsToExtdimensionData;
	
		// Other sections of cost accounting that are not described in the selections of accounting items should not be read
		FunctionalOptionsForInappropriateValues = New Array();
		FunctionalOptionsForInappropriateValues.Add(Metadata.FunctionalOptions.UseTollManufacturing2_5.Name);
		FunctionalOptionsForInappropriateValues.Add(Metadata.FunctionalOptions.UseCustodyDuringPurchase.Name);
		FunctionalOptionsForInappropriateValues.Add(Metadata.FunctionalOptions.UseSalesCommission.Name);
		
		SuppressDataWithoutSelectingByResourceComposition(FinancialAccountingObjects,
			FunctionalOptionsForInappropriateValues,
			Metadata.AccumulationRegisters.InventoryCost.Name,
			ResourcesForAccountingForAcceptedItemOfMan(),
			ResourcesForAccountingForAcceptedItemOfLocalRegulations());
	EndIf;
	
	StringTransmittedReturnContainer = FinancialAccountingObjects.Add();
	StringTransmittedReturnContainer.AccountingObject = Enums.DeleteFinancialAccountingObjects.TransferredReturnablePackaging;
	
	StringAcceptedReturnTare = FinancialAccountingObjects.Add();
	StringAcceptedReturnTare.AccountingObject = Enums.DeleteFinancialAccountingObjects.ReceivedReturnablePackaging;
	
EndProcedure

Procedure FillInAccountingItemsFixedAssets(FinancialAccountingObjects, TransactionSettings)
	
	FACostLine = FinancialAccountingObjects.Add();
	FACostLine.AccountingObject = Enums.DeleteFinancialAccountingObjects.FACost;
	FACostLine.FunctionalOptions = Metadata.FunctionalOptions.UseNonCurrentAssets2_4.Name;
	FACostLine.ManResources.Add("Cost");
	FACostLine.LocalResources.Add("LocalCost");
	FACostLine.LocalResources.Add("CostTargetFinancing");
	
	LineDepreciationFA = FinancialAccountingObjects.Add();
	LineDepreciationFA.AccountingObject = Enums.DeleteFinancialAccountingObjects.FixedAssetsDepreciationCharge;
	LineDepreciationFA.FunctionalOptions = Metadata.FunctionalOptions.UseNonCurrentAssets2_4.Name;
	LineDepreciationFA.LocalResources.Add("DepreciationLocal");
	LineDepreciationFA.LocalResources.Add("FixedAssetDepreciationTargetFinancing");
	
	FARevaluationReserveLine = FinancialAccountingObjects.Add();
	FARevaluationReserveLine.AccountingObject = Enums.DeleteFinancialAccountingObjects.RevaluationReserveForFixedAssets;
	FARevaluationReserveLine.FunctionalOptions = Metadata.FunctionalOptions.UseNonCurrentAssets2_4.Name;
	FARevaluationReserveLine.ManResources.Add("CostGainMA");
	FARevaluationReserveLine.LocalResources.Add("CostGainLocal");
	
	LineImpairmentOfFA = FinancialAccountingObjects.Add();
	LineImpairmentOfFA.AccountingObject = Enums.DeleteFinancialAccountingObjects.FAImpairment;
	LineImpairmentOfFA.FunctionalOptions = Metadata.FunctionalOptions.UseFixedAssetImpairment.Name;
	TypesOfVNA = New Array();
	TypesOfVNA.Add(Enums.KindsOfNonCurrentAssets.FixedAsset);
	TypesOfVNA.Add(Enums.KindsOfNonCurrentAssets.InvestmentProperty);
	Filterdata_ = New Map();
	Filterdata_.Insert("FinancialAccountingGroup.AssetKind", TypesOfVNA);
	LineImpairmentOfFA.Filterdata_ = Filterdata_;
	
	StringPassedByFA = FinancialAccountingObjects.Add();
	StringPassedByFA.AccountingObject = Enums.DeleteFinancialAccountingObjects.FixedAssetsProvided;
	StringPassedByFA.FunctionalOptions = Metadata.FunctionalOptions.UseNonCurrentAssets2_4.Name;
	Filterdata_ = New Map();
	Filterdata_.Insert("AssetRef", ChartsOfCharacteristicTypes.AssetLiabilityItems.FixedAssetSaleWithDeferredTransferOfTitleIs);
	StringPassedByFA.Filterdata_ = Filterdata_;
	PathsToExtdimensionData = New Map();
	PathsToExtdimensionData.Insert(ChartsOfCharacteristicTypes.FinancialExtraDimensionTypes.FixedAssets, "Dimension");
	StringPassedByFA.PathsToExtdimensionData = PathsToExtdimensionData;
	
EndProcedure

Procedure FillInAccountingItemsIntangibleAssets(FinancialAccountingObjects, TransactionSettings)
	
	LineCostOfIa = FinancialAccountingObjects.Add();
	LineCostOfIa.AccountingObject = Enums.DeleteFinancialAccountingObjects.IACost;
	LineCostOfIa.FunctionalOptions = Metadata.FunctionalOptions.UseNonCurrentAssets2_4.Name;
	LineCostOfIa.ManResources.Add("Cost");
	LineCostOfIa.LocalResources.Add("LocalCost");
	LineCostOfIa.LocalResources.Add("CostTargetFinancing");
	
	LineDepreciationIA = FinancialAccountingObjects.Add();
	LineDepreciationIA.AccountingObject = Enums.DeleteFinancialAccountingObjects.IntangibleAssetsAmortizationCharge;
	LineDepreciationIA.FunctionalOptions = Metadata.FunctionalOptions.UseNonCurrentAssets2_4.Name;
	LineDepreciationIA.LocalResources.Add("DepreciationLocal");
	LineDepreciationIA.LocalResources.Add("FixedAssetDepreciationTargetFinancing");
	
	RowResevreRevaluationOfIaValue = FinancialAccountingObjects.Add();
	RowResevreRevaluationOfIaValue.AccountingObject = Enums.DeleteFinancialAccountingObjects.RevaluationReserveForIA;
	RowResevreRevaluationOfIaValue.FunctionalOptions = Metadata.FunctionalOptions.UseNonCurrentAssets2_4.Name;
	RowResevreRevaluationOfIaValue.ManResources.Add("CostGainMA");
	RowResevreRevaluationOfIaValue.LocalResources.Add("CostGainLocal");
	
	LineImpairmentOfIA = FinancialAccountingObjects.Add();
	LineImpairmentOfIA.AccountingObject = Enums.DeleteFinancialAccountingObjects.ImpairmentIA;
	LineImpairmentOfIA.FunctionalOptions = Metadata.FunctionalOptions.UseFixedAssetImpairment.Name;
	TypesOfVNA = New Array();
	TypesOfVNA.Add(Enums.KindsOfNonCurrentAssets.IA);
	TypesOfVNA.Add(Enums.KindsOfNonCurrentAssets.RD);
	Filterdata_ = New Map();
	Filterdata_.Insert("FinancialAccountingGroup.AssetKind", TypesOfVNA);
	LineImpairmentOfIA.Filterdata_ = Filterdata_;
	
EndProcedure

Procedure FillInAccountingObjectsSettlementsWithCustomers(FinancialAccountingObjects, TransactionSettings)
	
	LineAdvancesReceivedFromCustomers = FinancialAccountingObjects.Add();
	LineAdvancesReceivedFromCustomers.AccountingObject = Enums.DeleteFinancialAccountingObjects.PrepaymentsFromCustomers;
	LineAdvancesReceivedFromCustomers.ManResources.Add("PrepaymentMan");
	LineAdvancesReceivedFromCustomers.LocalResources.Add("PrepaymentLocal");
	LineAdvancesReceivedFromCustomers.ShaftResources.Add("Prepayment");
	
	CustomerDebtLine_0 = FinancialAccountingObjects.Add();
	CustomerDebtLine_0.AccountingObject = Enums.DeleteFinancialAccountingObjects.CustomersAccountsReceivable;
	CustomerDebtLine_0.ManResources.Add("ARAPMan");
	CustomerDebtLine_0.LocalResources.Add("DebtLocal");
	CustomerDebtLine_0.ShaftResources.Add("Debt");
	
	LineGiftCertificates = FinancialAccountingObjects.Add();
	LineGiftCertificates.AccountingObject = Enums.DeleteFinancialAccountingObjects.GiftCertificates;
	
	If TransactionSettings.OptionForGeneratingTransactions = Undefined
	 Or TransactionSettings.OptionForGeneratingTransactions = Enums.EntryGenerationOptions.WithCorrespondence Then
		LineSettlementsWithRetailCustomers = FinancialAccountingObjects.Add();
		LineSettlementsWithRetailCustomers.AccountingObject = Enums.DeleteFinancialAccountingObjects.RetailCustomerAccountsReceivables;
	EndIf;
	
	LineOfObligationToPurchasingCommittee = FinancialAccountingObjects.Add();
	LineOfObligationToPurchasingCommittee.AccountingObject = Enums.DeleteFinancialAccountingObjects.ObligationsToProcurementCommittee;
	LineOfObligationToPurchasingCommittee.FunctionalOptions = Metadata.FunctionalOptions.ProvideAgentServicesOnPurchaseToPrincipals.Name;
	
EndProcedure

Procedure FillInAccountingItemsSettlementsWithSuppliers(FinancialAccountingObjects, TransactionSettings)
	
	LineAdvancesToSuppliers = FinancialAccountingObjects.Add();
	LineAdvancesToSuppliers.AccountingObject = Enums.DeleteFinancialAccountingObjects.PrepaymentsToVendors;
	LineAdvancesToSuppliers.ManResources.Add("PrepaymentMan");
	LineAdvancesToSuppliers.LocalResources.Add("PrepaymentLocal");
	LineAdvancesToSuppliers.ShaftResources.Add("Prepayment");
	
	LineDebtToSuppliers = FinancialAccountingObjects.Add();
	LineDebtToSuppliers.AccountingObject = Enums.DeleteFinancialAccountingObjects.VendorAccountsReceivable;
	LineDebtToSuppliers.ManResources.Add("ARAPMan");
	LineDebtToSuppliers.LocalResources.Add("DebtLocal");
	LineDebtToSuppliers.ShaftResources.Add("Debt");
	
	LineTicketsAndReservations = FinancialAccountingObjects.Add();
	LineTicketsAndReservations.AccountingObject = Enums.DeleteFinancialAccountingObjects.TicketsAndBooking;
	Filterdata_ = New Map();
	Filterdata_.Insert("ARAPObject.FinancialAccountingGroup.BookingARAPAccounting", True);
	LineTicketsAndReservations.Filterdata_ = Filterdata_;
	LineTicketsAndReservations.ManResources.Add("PrepaymentMan");
	LineTicketsAndReservations.LocalResources.Add("PrepaymentLocal");
	LineTicketsAndReservations.ShaftResources.Add("Prepayment");
	
	LineTicketsAndReservations = FinancialAccountingObjects.Add();
	LineTicketsAndReservations.AccountingObject = Enums.DeleteFinancialAccountingObjects.TicketsAndBooking;
	Filterdata_ = New Map();
	Filterdata_.Insert("ARAPObject.FinancialAccountingGroup.BookingARAPAccounting", True);
	LineTicketsAndReservations.Filterdata_ = Filterdata_;
	LineTicketsAndReservations.ManResources.Add("ARAPMan");
	LineTicketsAndReservations.LocalResources.Add("DebtLocal");
	LineTicketsAndReservations.ShaftResources.Add("Debt");
	
	DiscountExpenseLine = FinancialAccountingObjects.Add();
	DiscountExpenseLine.AccountingObject = Enums.DeleteFinancialAccountingObjects.DiscountInterestExpense;
	
	LineObligationsToCommitteeForGoodsSold = FinancialAccountingObjects.Add();
	LineObligationsToCommitteeForGoodsSold.AccountingObject = Enums.DeleteFinancialAccountingObjects.ObligationsToCommiteeForGoodsSold;
	LineObligationsToCommitteeForGoodsSold.FunctionalOptions = Metadata.FunctionalOptions.UsePurchaseCommission.Name;
	PathsToExtdimensionData = New Map();
	PathsToExtdimensionData.Insert(ChartsOfCharacteristicTypes.FinancialExtraDimensionTypes.Counterparties, "InventoryOwnerAttribute.Counterparty");
	LineObligationsToCommitteeForGoodsSold.PathsToExtdimensionData = PathsToExtdimensionData;
	
	LineObligationsToPrincipalForServicesProvided = FinancialAccountingObjects.Add();
	LineObligationsToPrincipalForServicesProvided.AccountingObject = Enums.DeleteFinancialAccountingObjects.ObligationsToPrincipalForServicesProvided;
	LineObligationsToPrincipalForServicesProvided.FunctionalOptions = Metadata.FunctionalOptions.UseAgentServiceSale.Name;
	
EndProcedure

Procedure FillInAccountingItemsLoansAndBorrowingsIssued(FinancialAccountingObjects, TransactionSettings)
	
	NatureOfContracts = New Array();
	NatureOfContracts.Add(Enums.ContractKindsOfFinancialInstruments.IssuedBorrowing);
	NatureOfContracts.Add(Enums.ContractKindsOfFinancialInstruments.Deposit);
	
	LineLoansAndBorrowingsIssuedDebt = FinancialAccountingObjects.Add();
	LineLoansAndBorrowingsIssuedDebt.AccountingObject = Enums.DeleteFinancialAccountingObjects.LoansAndBorrowingsIssuedDebt;
	LineLoansAndBorrowingsIssuedDebt.FunctionalOptions = Metadata.FunctionalOptions.UseLoanAndDepositContracts.Name;
	Filterdata_ = New Map();
	Filterdata_.Insert("Contract.ContractKind", NatureOfContracts);
	Filterdata_.Insert("AmountType", Enums.LoanAndDepositScheduleAmountTypes.PrincipalDebt);
	LineLoansAndBorrowingsIssuedDebt.Filterdata_ = Filterdata_;
	
	LineLoansAndBorrowingsIssuedCommission = FinancialAccountingObjects.Add();
	LineLoansAndBorrowingsIssuedCommission.AccountingObject = Enums.DeleteFinancialAccountingObjects.LoansAndBorrowingsIssuedFee;
	LineLoansAndBorrowingsIssuedCommission.FunctionalOptions = Metadata.FunctionalOptions.UseLoanAndDepositContracts.Name;
	Filterdata_ = New Map();
	Filterdata_.Insert("Contract.ContractKind", NatureOfContracts);
	Filterdata_.Insert("AmountType", Enums.LoanAndDepositScheduleAmountTypes.Fee);
	LineLoansAndBorrowingsIssuedCommission.Filterdata_ = Filterdata_;
	
	LineLoansAndBorrowingsInterestIssued = FinancialAccountingObjects.Add();
	LineLoansAndBorrowingsInterestIssued.AccountingObject = Enums.DeleteFinancialAccountingObjects.LoansAndBorrowingsIssuedInterest;
	LineLoansAndBorrowingsInterestIssued.FunctionalOptions = Metadata.FunctionalOptions.UseLoanAndDepositContracts.Name;
	Filterdata_ = New Map();
	Filterdata_.Insert("Contract.ContractKind", NatureOfContracts);
	Filterdata_.Insert("AmountType", Enums.LoanAndDepositScheduleAmountTypes.Interests);
	LineLoansAndBorrowingsInterestIssued.Filterdata_ = Filterdata_;
	
EndProcedure

Procedure FillInAccountingItemsLoansAndBorrowingsReceived(FinancialAccountingObjects, TransactionSettings)
	
	LineLoansAndBorrowingsReceivedDebt = FinancialAccountingObjects.Add();
	LineLoansAndBorrowingsReceivedDebt.AccountingObject = Enums.DeleteFinancialAccountingObjects.LoansAndBorrowingsReceivedDebt;
	LineLoansAndBorrowingsReceivedDebt.FunctionalOptions = Metadata.FunctionalOptions.UseLoanAndDepositContracts.Name;
	Filterdata_ = New Map();
	Filterdata_.Insert("Contract.ContractKind", Enums.ContractKindsOfFinancialInstruments.LoanOrBorrowing);
	Filterdata_.Insert("AmountType", Enums.LoanAndDepositScheduleAmountTypes.PrincipalDebt);
	LineLoansAndBorrowingsReceivedDebt.Filterdata_ = Filterdata_;
	
	LineLoansAndBorrowingsReceivedCommission = FinancialAccountingObjects.Add();
	LineLoansAndBorrowingsReceivedCommission.AccountingObject = Enums.DeleteFinancialAccountingObjects.LoansAndBorrowingsReceivedFee;
	LineLoansAndBorrowingsReceivedCommission.FunctionalOptions = Metadata.FunctionalOptions.UseLoanAndDepositContracts.Name;
	Filterdata_ = New Map();
	Filterdata_.Insert("Contract.ContractKind", Enums.ContractKindsOfFinancialInstruments.LoanOrBorrowing);
	Filterdata_.Insert("AmountType", Enums.LoanAndDepositScheduleAmountTypes.Fee);
	LineLoansAndBorrowingsReceivedCommission.Filterdata_ = Filterdata_;
	
	LineLoansAndBorrowingsInterestReceived = FinancialAccountingObjects.Add();
	LineLoansAndBorrowingsInterestReceived.AccountingObject = Enums.DeleteFinancialAccountingObjects.LoansAndBorrowingsInterestReceived;
	LineLoansAndBorrowingsInterestReceived.FunctionalOptions = Metadata.FunctionalOptions.UseLoanAndDepositContracts.Name;
	Filterdata_ = New Map();
	Filterdata_.Insert("Contract.ContractKind", Enums.ContractKindsOfFinancialInstruments.LoanOrBorrowing);
	Filterdata_.Insert("AmountType", Enums.LoanAndDepositScheduleAmountTypes.Interests);
	LineLoansAndBorrowingsInterestReceived.Filterdata_ = Filterdata_;
	
EndProcedure

Procedure FillInAccountingItemsSettlementsWithEmployees(FinancialAccountingObjects, TransactionSettings)
	
	LinePayrollCalculations = FinancialAccountingObjects.Add();
	LinePayrollCalculations.AccountingObject = Enums.DeleteFinancialAccountingObjects.PayrollAccountsPayable;
	Filterdata_ = New Map();
	Filterdata_.Insert("AssetRef", ChartsOfCharacteristicTypes.AssetLiabilityItems.Payroll);
	LinePayrollCalculations.Filterdata_ = Filterdata_;
	
	LineSettlementsWithAccountablePersons = FinancialAccountingObjects.Add();
	LineSettlementsWithAccountablePersons.AccountingObject = Enums.DeleteFinancialAccountingObjects.AdvanceHoldersARAPAccounting;
	
	LineSettlementsOnLoansToEmployees = FinancialAccountingObjects.Add();
	LineSettlementsOnLoansToEmployees.AccountingObject = Enums.DeleteFinancialAccountingObjects.EmployeeARAPAccounting;
	Filterdata_ = New Map();
	Filterdata_.Insert("AssetRef", ChartsOfCharacteristicTypes.AssetLiabilityItems.IssuedBorrowings);
	LineSettlementsOnLoansToEmployees.Filterdata_ = Filterdata_;
	
EndProcedure

Procedure FillInAccountingItemsExpenseLease(FinancialAccountingObjects, TransactionSettings)
	
	LineSecurityPaymentForRent = FinancialAccountingObjects.Add();
	LineSecurityPaymentForRent.AccountingObject = Enums.DeleteFinancialAccountingObjects.SecurityPaymentForLease;
	Filterdata_ = New Map();
	Filterdata_.Insert("Contract.ContractKind", Enums.ContractKindsOfFinancialInstruments.Lease);
	Filterdata_.Insert("AmountType", Enums.TypesOfLeasePayments.DepositPayment);
	LineSecurityPaymentForRent.Filterdata_ = Filterdata_;
	
	LineRentalServices = FinancialAccountingObjects.Add();
	LineRentalServices.AccountingObject = Enums.DeleteFinancialAccountingObjects.RentalServices;
	Filterdata_ = New Map();
	Filterdata_.Insert("Contract.ContractKind", Enums.ContractKindsOfFinancialInstruments.Lease);
	PaymentTypesRentalService = New Array();
	PaymentTypesRentalService.Add(Enums.TypesOfLeasePayments.RentalService);
	PaymentTypesRentalService.Add(Enums.TypesOfLeasePayments.RentalServicePrepayment);
	Filterdata_.Insert("AmountType", PaymentTypesRentalService);
	LineRentalServices.Filterdata_ = Filterdata_;
	
	LineLeaseLiabilities = FinancialAccountingObjects.Add();
	LineLeaseLiabilities.AccountingObject = Enums.DeleteFinancialAccountingObjects.LeaseObligations;
	Filterdata_ = New Map();
	Filterdata_.Insert("Contract.ContractKind", Enums.ContractKindsOfFinancialInstruments.Lease);
	Filterdata_.Insert("AmountType", Enums.TypesOfLeasePayments.LeaseObligations);
	LineLeaseLiabilities.Filterdata_ = Filterdata_;
	
	LinePurchasePriceForLease = FinancialAccountingObjects.Add();
	LinePurchasePriceForLease.AccountingObject = Enums.DeleteFinancialAccountingObjects.LeaseBuyoutValue;
	Filterdata_ = New Map();
	Filterdata_.Insert("Contract.ContractKind", Enums.ContractKindsOfFinancialInstruments.Lease);
	Filterdata_.Insert("AmountType", Enums.TypesOfLeasePayments.BuyoutValue);
	LinePurchasePriceForLease.Filterdata_ = Filterdata_;
	
	LeaseRepurchaseAdvanceLine = FinancialAccountingObjects.Add();
	LeaseRepurchaseAdvanceLine.AccountingObject = Enums.DeleteFinancialAccountingObjects.PrepaymentLeaseBuyoutValue;
	Filterdata_ = New Map();
	Filterdata_.Insert("Contract.ContractKind", Enums.ContractKindsOfFinancialInstruments.Lease);
	Filterdata_.Insert("AmountType", Enums.TypesOfLeasePayments.BuyoutValuePrepayment);
	LeaseRepurchaseAdvanceLine.Filterdata_ = Filterdata_;
	
	RentalInterestLine = FinancialAccountingObjects.Add();
	RentalInterestLine.AccountingObject = Enums.DeleteFinancialAccountingObjects.RentalInterest;
	Filterdata_ = New Map();
	Filterdata_.Insert("Contract.ContractKind", Enums.ContractKindsOfFinancialInstruments.Lease);
	Filterdata_.Insert("AmountType", Enums.TypesOfLeasePayments.Interests);
	RentalInterestLine.Filterdata_ = Filterdata_;
	
	VATLineForRent = FinancialAccountingObjects.Add();
	VATLineForRent.AccountingObject = Enums.DeleteFinancialAccountingObjects.VATForLease;
	Filterdata_ = New Map();
	Filterdata_.Insert("Contract.ContractKind", Enums.ContractKindsOfFinancialInstruments.Lease);
	Filterdata_.Insert("AmountType", Enums.TypesOfLeasePayments.VAT);
	VATLineForRent.Filterdata_ = Filterdata_;
	
EndProcedure

Procedure FillInAccountingItemsProfitableLease(FinancialAccountingObjects, TransactionSettings)
	
	LineRentalPayments = FinancialAccountingObjects.Add();
	LineRentalPayments.AccountingObject = Enums.DeleteFinancialAccountingObjects.RentalPayments;
	LineRentalPayments.FunctionalOptions = Metadata.FunctionalOptions.TransferToRentalSubleaseBasedOnRussianGAAPFSBU25.Name;
	LineRentalPayments.ManResources.Add("RentalPaymentsManag");
	LineRentalPayments.LocalResources.Add("RentalPaymentsLocal");
	LineRentalPayments.ShaftResources.Add("RentalPayments");
	PathsToExtdimensionData = New Map();
	PathsToExtdimensionData.Insert(ChartsOfCharacteristicTypes.FinancialExtraDimensionTypes.Counterparties, "Contract.Counterparty");
	LineRentalPayments.PathsToExtdimensionData = PathsToExtdimensionData;
	
	LineIsNonGuaranteedResidualValue = FinancialAccountingObjects.Add();
	LineIsNonGuaranteedResidualValue.AccountingObject = Enums.DeleteFinancialAccountingObjects.NonGuaranteedResidualValueFinancialLease;
	LineIsNonGuaranteedResidualValue.FunctionalOptions = Metadata.FunctionalOptions.TransferToRentalSubleaseBasedOnRussianGAAPFSBU25.Name;
	LineIsNonGuaranteedResidualValue.ManResources.Add("NonGuaranteedResidualValueManag");
	LineIsNonGuaranteedResidualValue.LocalResources.Add("NonGuaranteedResidualValueLocal");
	LineIsNonGuaranteedResidualValue.ShaftResources.Add("0");
	PathsToExtdimensionData = New Map();
	PathsToExtdimensionData.Insert(ChartsOfCharacteristicTypes.FinancialExtraDimensionTypes.Counterparties, "Contract.Counterparty");
	LineIsNonGuaranteedResidualValue.PathsToExtdimensionData = PathsToExtdimensionData;
	
	LinePercentagesOfDiscountingRentalPayments = FinancialAccountingObjects.Add();
	LinePercentagesOfDiscountingRentalPayments.AccountingObject = Enums.DeleteFinancialAccountingObjects.InterestOnDiscountingRentalPaymentsFinancialLease;
	LinePercentagesOfDiscountingRentalPayments.FunctionalOptions = Metadata.FunctionalOptions.TransferToRentalSubleaseBasedOnRussianGAAPFSBU25.Name;
	LinePercentagesOfDiscountingRentalPayments.ManResources.Add("InterestDiscountMan");
	LinePercentagesOfDiscountingRentalPayments.LocalResources.Add("InterestDiscountLocal");
	LinePercentagesOfDiscountingRentalPayments.ShaftResources.Add("InterestDiscount");
	PathsToExtdimensionData = New Map();
	PathsToExtdimensionData.Insert(ChartsOfCharacteristicTypes.FinancialExtraDimensionTypes.Counterparties, "Contract.Counterparty");
	LinePercentagesOfDiscountingRentalPayments.PathsToExtdimensionData = PathsToExtdimensionData;
	
EndProcedure

Procedure FillInAccountingItemsWorkInProgress(FinancialAccountingObjects, TransactionSettings)

	StorageLocationsForProductionCosts = New Array();
	StorageLocationsForProductionCosts.Add(Enums.StorageLocationTypes.CounterpartyContract);
	StorageLocationsForProductionCosts.Add(Enums.StorageLocationTypes.Organization);
	StorageLocationsForProductionCosts.Add(Enums.StorageLocationTypes.Partner);
	StorageLocationsForProductionCosts.Add(Enums.StorageLocationTypes.Department);
	
	OtherMaterialsInProgress = FinancialAccountingObjects.Add();
	OtherMaterialsInProgress.AccountingObject = Enums.DeleteFinancialAccountingObjects.MaterialsAndWorksInProgress;
	OtherMaterialsInProgress.FunctionalOptions = Metadata.FunctionalOptions.UseProduction.Name;
	GroupOfFilters = New Array();
	Filterdata_ = New Map();
	Filterdata_.Insert("AccountingSection", Enums.SectionsOfInventoryCostAccounting.WorkInProgress);
	GroupOfFilters.Add(Filterdata_);
	Filterdata_ = New Map();
	AccountingSections = New Array();
	AccountingSections.Add(Enums.SectionsOfInventoryCostAccounting.ProductionCosts);
	AccountingSections.Add(Enums.SectionsOfInventoryCostAccounting.GoodsReceivedForRespSafekeeping);
	AccountingSections.Add(Enums.SectionsOfInventoryCostAccounting.VendorManagedInventoryTransferredToPartners);
	Filterdata_.Insert("AccountingSection", AccountingSections);
	Filterdata_.Insert("ItemsLocationAttributes.StorageType", StorageLocationsForProductionCosts);
	GroupOfFilters.Add(Filterdata_);
	OtherMaterialsInProgress.Filterdata_ = GroupOfFilters;
	OtherMaterialsInProgress.DataPathConfigurationObject = "FinancialAccountingDimension";
	OtherMaterialsInProgress.ManResources = ManSOwnProductInventoryResources();
	OtherMaterialsInProgress.LocalResources = ResourcesForAccountingForYourOwnLocalProductList();
	
	LineLaborCostsInWorkInProgress = FinancialAccountingObjects.Add();
	LineLaborCostsInWorkInProgress.AccountingObject = Enums.DeleteFinancialAccountingObjects.LaborCostsInWorkInProgress;
	LineLaborCostsInWorkInProgress.FunctionalOptions = Metadata.FunctionalOptions.UseProduction.Name;
	
	LineItemByItemCostsInWorkInProgress = FinancialAccountingObjects.Add();
	LineItemByItemCostsInWorkInProgress.AccountingObject = Enums.DeleteFinancialAccountingObjects.ItemizedCostsInWorkInProgress;
	LineItemByItemCostsInWorkInProgress.FunctionalOptions = Metadata.FunctionalOptions.UseProduction.Name;
	
	If TransactionSettings.MethodOfAccountingForImproperValues <> Enums.MethodsOfNotOwnedControlledValuesAccounting.NotRecordedOnAccounts
	   And TransactionSettings.MethodOfAccountingForImproperValues <> Enums.MethodsOfNotOwnedControlledValuesAccounting.EmptyRef() Then
		ProductLineAcceptedForProcessing = FinancialAccountingObjects.Add();
		ProductLineAcceptedForProcessing.AccountingObject = Enums.DeleteFinancialAccountingObjects.ItemReceivedForSubcontractingInProduction;
		FunctionalOptions = New Array;
		FunctionalOptions.Add(Metadata.FunctionalOptions.UseTollManufacturing2_5.Name);
		ProductLineAcceptedForProcessing.FunctionalOptions = FunctionalOptions;
		Filterdata_ = New Map();
		Filterdata_.Insert("AccountingSection", Enums.SectionsOfInventoryCostAccounting.MaterialsReceivedForProcessing);
		Filterdata_.Insert("ItemsLocationAttributes.StorageType", StorageLocationsForProductionCosts);
		ProductLineAcceptedForProcessing.Filterdata_ = Filterdata_;
		ProductLineAcceptedForProcessing.ImproperValues = True;
		ProductLineAcceptedForProcessing.DataPathConfigurationObject = "FinancialAccountingDimension";
		ProductLineAcceptedForProcessing.ManResources = ResourcesForAccountingForAcceptedItemOfMan();
		ProductLineAcceptedForProcessing.LocalResources = ResourcesForAccountingForAcceptedItemOfLocalRegulations();
		PathsToExtdimensionData = New Map();
		PathsToExtdimensionData.Insert(ChartsOfCharacteristicTypes.FinancialExtraDimensionTypes.Counterparties, "InventoryOwnerAttribute.Counterparty");
		ProductLineAcceptedForProcessing.PathsToExtdimensionData = PathsToExtdimensionData;
		
		StringProductAcceptedForStorage = FinancialAccountingObjects.Add();
		StringProductAcceptedForStorage.AccountingObject = Enums.DeleteFinancialAccountingObjects.ItemReceivedForStorageInProduction;
		FunctionalOptions = New Array();
		FunctionalOptions.Add(Metadata.FunctionalOptions.UseTollManufacturing2_5.Name);
		FunctionalOptions.Add(Metadata.FunctionalOptions.UseCustodyDuringPurchase.Name);
		StringProductAcceptedForStorage.FunctionalOptions = FunctionalOptions;
		Filterdata_ = New Map();
		AccountingSections = New Array();
		AccountingSections.Add(Enums.SectionsOfInventoryCostAccounting.GoodsReceivedForRespSafekeeping);
		AccountingSections.Add(Enums.SectionsOfInventoryCostAccounting.GoodsAtStorageWithRightOfSale);
		Filterdata_.Insert("AccountingSection", AccountingSections);
		Filterdata_.Insert("ItemsLocationAttributes.StorageType", StorageLocationsForProductionCosts);
		StringProductAcceptedForStorage.ImproperValues = True;
		StringProductAcceptedForStorage.Filterdata_ = Filterdata_;
		StringProductAcceptedForStorage.DataPathConfigurationObject = "FinancialAccountingDimension";
		StringProductAcceptedForStorage.ManResources = ResourcesForAccountingForAcceptedItemOfMan();
		StringProductAcceptedForStorage.LocalResources = ResourcesForAccountingForAcceptedItemOfLocalRegulations();
		PathsToExtdimensionData = New Map();
		PathsToExtdimensionData.Insert(ChartsOfCharacteristicTypes.FinancialExtraDimensionTypes.Counterparties, "InventoryOwnerAttribute.Counterparty");
		StringProductAcceptedForStorage.PathsToExtdimensionData = PathsToExtdimensionData;
	EndIf;
	
EndProcedure

Procedure FillInAccountingItemsIncomeAndExpenses(FinancialAccountingObjects, TransactionSettings)
	
	If TransactionSettings.RevenueExcludingVAT = False
	 Or TransactionSettings.RevenueExcludingVAT = Undefined Then
		LineRevenueFromSales = FinancialAccountingObjects.Add();
		LineRevenueFromSales.AccountingObject = Enums.DeleteFinancialAccountingObjects.SalesRevenue;
		LineRevenueFromSales.DebitCondition = "FALSE";
		LineRevenueFromSales.ConditionCredit = "TRUE";
		LineRevenueFromSales.DataPathRecordFinID = StrReplace(
			"CASE
			|		WHEN DataSourceAlias.SourceOfARAPFinancialAccountingGroup <> VALUE(Catalog.ARAPObjects.EmptyRef)
			|			THEN DataSourceAlias.SourceOfARAPFinancialAccountingGroup.UUID
			|		ELSE DataSourceAlias.FinRecordID
			|	END",
			"DataSourceAlias",
			FinancialAccountingByBalanceSheetRegisterData.DefaultDataSourceAlias());
		LineRevenueFromSales.DataPathRowId = "FinRecordID";
		LineRevenueFromSales.ManResources.Add("RevenueAmount");
		LineRevenueFromSales.LocalResources.Add("RevenueAmountIncludingVATLocal");
		LineRevenueFromSales.AccountingWithVAT = True;
		LineRevenueFromSales.CorDataSources.Add(Metadata.AccumulationRegisters.CustomersARAPAccountingByDueDates.Name);
		If TransactionSettings.RevenueExcludingVAT = Undefined Then
			FillInSignsOfCorrespondenceAccounting(LineRevenueFromSales, "RevenueExcludingVAT", False);
		EndIf;
		
		OtherRevenueLine = FinancialAccountingObjects.Add();
		OtherRevenueLine.AccountingObject = Enums.DeleteFinancialAccountingObjects.RevenueServicesAndAssets;
		OtherRevenueLine.DebitCondition = "FALSE";
		OtherRevenueLine.ConditionCredit = "TRUE";
		OtherRevenueLine.DataPathRecordFinID = StrReplace(
			"CASE
			|		WHEN DataSourceAlias.ARAPObject <> VALUE(Catalog.ARAPObjects.EmptyRef)
			|			THEN DataSourceAlias.ARAPObject.UUID
			|		ELSE DataSourceAlias.FinRecordID
			|	END",
			"DataSourceAlias",
			FinancialAccountingByBalanceSheetRegisterData.DefaultDataSourceAlias());
		OtherRevenueLine.DataPathRowId = "FinRecordID";
		OtherRevenueLine.AccountingWithVAT = True;
		OtherRevenueLine.CorDataSources.Add(Metadata.AccumulationRegisters.CustomersARAPAccountingByDueDates.Name);
		OtherRevenueLine.CorDataSources.Add(Metadata.AccumulationRegisters.FinancialInstrumentsARAP.Name);
		OtherRevenueLine.CorDataSources.Add(Metadata.AccumulationRegisters.OtherAssetsAndLiabilitiesRecords.Name);
		If TransactionSettings.RevenueExcludingVAT = Undefined Then
			FillInSignsOfCorrespondenceAccounting(OtherRevenueLine, "RevenueExcludingVAT", False);
		EndIf;
	EndIf;
	
	If TransactionSettings.RevenueExcludingVAT = True
	 Or TransactionSettings.RevenueExcludingVAT = Undefined Then
		LineRevenueFromSalesExcludingVAT = FinancialAccountingObjects.Add();
		LineRevenueFromSalesExcludingVAT.AccountingObject = Enums.DeleteFinancialAccountingObjects.SalesRevenueExcludingVAT;
		LineRevenueFromSalesExcludingVAT.DebitCondition = "FALSE";
		LineRevenueFromSalesExcludingVAT.ConditionCredit = "TRUE";
		LineRevenueFromSalesExcludingVAT.DataPathRecordFinID = StrReplace(
			"CASE
			|		WHEN DataSourceAlias.SourceOfARAPFinancialAccountingGroup <> VALUE(Catalog.ARAPObjects.EmptyRef)
			|			THEN DataSourceAlias.SourceOfARAPFinancialAccountingGroup.UUID
			|		ELSE DataSourceAlias.FinRecordID
			|	END",
			"DataSourceAlias",
			FinancialAccountingByBalanceSheetRegisterData.DefaultDataSourceAlias());
		LineRevenueFromSalesExcludingVAT.DataPathRowId = "FinRecordID";
		LineRevenueFromSalesExcludingVAT.ManResources.Add("RevenueAmountExcludingVAT");
		LineRevenueFromSalesExcludingVAT.LocalResources.Add("RevenueAmountExclVATLocal");
		LineRevenueFromSalesExcludingVAT.CorDataSources.Add(Metadata.AccumulationRegisters.CustomersARAPAccountingByDueDates.Name);
		If TransactionSettings.RevenueExcludingVAT = Undefined Then
			FillInSignsOfCorrespondenceAccounting(LineRevenueFromSalesExcludingVAT, "RevenueExcludingVAT", True);
		EndIf;
		
		LineOtherRevenueExcludingVAT = FinancialAccountingObjects.Add();
		LineOtherRevenueExcludingVAT.AccountingObject = Enums.DeleteFinancialAccountingObjects.RevenueServicesAndAssetsExcludingVAT;
		LineOtherRevenueExcludingVAT.DebitCondition = "FALSE";
		LineOtherRevenueExcludingVAT.ConditionCredit = "TRUE";
		LineOtherRevenueExcludingVAT.DataPathRecordFinID = StrReplace(
			"CASE
			|		WHEN DataSourceAlias.ARAPObject <> VALUE(Catalog.ARAPObjects.EmptyRef)
			|			THEN DataSourceAlias.ARAPObject.UUID
			|		ELSE DataSourceAlias.FinRecordID
			|	END",
			"DataSourceAlias",
			FinancialAccountingByBalanceSheetRegisterData.DefaultDataSourceAlias());
		LineOtherRevenueExcludingVAT.DataPathRowId = "FinRecordID";
		LineOtherRevenueExcludingVAT.ManResources.Add("RevenueExcludingVATManag");
		LineOtherRevenueExcludingVAT.LocalResources.Add("RevenueExcludingVATLocal");
		LineOtherRevenueExcludingVAT.CorDataSources.Add(Metadata.AccumulationRegisters.CustomersARAPAccountingByDueDates.Name);
		LineOtherRevenueExcludingVAT.CorDataSources.Add(Metadata.AccumulationRegisters.FinancialInstrumentsARAP.Name);
		LineOtherRevenueExcludingVAT.CorDataSources.Add(Metadata.AccumulationRegisters.OtherAssetsAndLiabilitiesRecords.Name);
		If TransactionSettings.RevenueExcludingVAT = Undefined Then
			FillInSignsOfCorrespondenceAccounting(LineOtherRevenueExcludingVAT, "RevenueExcludingVAT", True);
		EndIf;
	EndIf;
	
	LineCostOfSales = FinancialAccountingObjects.Add();
	LineCostOfSales.AccountingObject = Enums.DeleteFinancialAccountingObjects.SaleCost;
	LineCostOfSales.DebitCondition = "TRUE";
	LineCostOfSales.ConditionCredit = "FALSE";
	LineCostOfSales.ManResources.Add("CostMan");
	LineCostOfSales.ManResources.Add("AddExpensesMan");
	LineCostOfSales.ManResources.Add("LaborCostsMan");
	LineCostOfSales.ManResources.Add("ItemizedFixedCostsManag");
	LineCostOfSales.ManResources.Add("ItemizedVariableCostsManag");
	LineCostOfSales.ManResources.Add("SellingExpensesMan");
	LineCostOfSales.ManResources.Add("ProvisionForImpairmentMan");
	LineCostOfSales.LocalResources.Add("LocalCost");
	LineCostOfSales.LocalResources.Add("AddExpensesLocal");
	LineCostOfSales.LocalResources.Add("LaborCostsLocal");
	LineCostOfSales.LocalResources.Add("ItemizedFixedCostsCompl");
	LineCostOfSales.LocalResources.Add("ItemizedVariableCostsCompl");
	LineCostOfSales.LocalResources.Add("SellingExpensesLocal");
	LineCostOfSales.LocalResources.Add("ProvisionForImpairmentLocal");
	LineCostOfSales.CorDataSources.Add(Metadata.AccumulationRegisters.InventoryCost.Name);
	LineCostOfSales.CorDataSources.Add(Metadata.AccumulationRegisters.VendorsARAPAccountingByDueDates.Name);
	LineCostOfSales.CorDataSources.Add(Metadata.AccumulationRegisters.OtherExpenses.Name);
	LineCostOfSales.CorDataSources.Add(Metadata.AccumulationRegisters.VATInvoiced.Name);
	
	LineExpenses = FinancialAccountingObjects.Add();
	LineExpenses.AccountingObject = Enums.DeleteFinancialAccountingObjects.Expenses;
	
	OtherIncomeLine = FinancialAccountingObjects.Add();
	OtherIncomeLine.AccountingObject = Enums.DeleteFinancialAccountingObjects.OtherIncome;
	
	RevenueClosingLine = FinancialAccountingObjects.Add();
	RevenueClosingLine.AccountingObject = Enums.DeleteFinancialAccountingObjects.ContinuingOperationIncomeClosing;
	Filterdata_ = New Map();
	Filterdata_.Insert("AssetRef", ChartsOfCharacteristicTypes.AssetLiabilityItems.ProfitAndLoss);
	Filterdata_.Insert("DebitCredit", Enums.RecordKindsOfOtherAssetsAndLiabilities.Credit);
	RevenueClosingLine.Filterdata_ = Filterdata_;
	
	LineClosingExpenses = FinancialAccountingObjects.Add();
	LineClosingExpenses.AccountingObject = Enums.DeleteFinancialAccountingObjects.ContinuingOperationExpenseClosing;
	Filterdata_ = New Map();
	Filterdata_.Insert("AssetRef", ChartsOfCharacteristicTypes.AssetLiabilityItems.ProfitAndLoss);
	Filterdata_.Insert("DebitCredit", Enums.RecordKindsOfOtherAssetsAndLiabilities.Debit);
	LineClosingExpenses.Filterdata_ = Filterdata_;
	
EndProcedure

Procedure FillInVATObjects(FinancialAccountingObjects, TransactionSettings)
	
	IncomingVATLine = FinancialAccountingObjects.Add();
	IncomingVATLine.AccountingObject = Enums.DeleteFinancialAccountingObjects.IncomingVAT;
	IncomingVATLine.FunctionalOptions = Metadata.FunctionalOptions.UseVATAccounting.Name;
	IncomingVATLine.VATAccounting = True;
	
	LineVATCalculations = FinancialAccountingObjects.Add();
	LineVATCalculations.AccountingObject = Enums.DeleteFinancialAccountingObjects.VATAccountsPayable;
	LineVATCalculations.FunctionalOptions = Metadata.FunctionalOptions.UseVATAccounting.Name;
	If TransactionSettings.RevenueExcludingVAT = True Then
		LineVATCalculations.DataPathRecordFinID = StrReplace(
			"CASE
			|		WHEN DataSourceAlias.ARAPObject <> VALUE(Catalog.ARAPObjects.EmptyRef)
			|			THEN DataSourceAlias.ARAPObject.UUID
			|		ELSE DataSourceAlias.FinRecordID
			|	END",
			"DataSourceAlias",
			FinancialAccountingByBalanceSheetRegisterData.DefaultDataSourceAlias());
		LineVATCalculations.DataPathRowId = "FinRecordID";
	EndIf;
	LineVATCalculations.VATAccounting = True;
	
	VATLineForShipmentsWithoutTransferOfRights = FinancialAccountingObjects.Add();
	VATLineForShipmentsWithoutTransferOfRights.AccountingObject = Enums.DeleteFinancialAccountingObjects.VATForShipmentsWithDeferredTransferOfTitle;
	VATLineForShipmentsWithoutTransferOfRights.FunctionalOptions = Metadata.FunctionalOptions.UseVATAccounting.Name;
	Filterdata_ = New Map();
	Filterdata_.Insert("AssetRef", ChartsOfCharacteristicTypes.AssetLiabilityItems.VATForShipmentsWithDeferredTransferOfTitle);
	VATLineForShipmentsWithoutTransferOfRights.Filterdata_ = Filterdata_;
	If TransactionSettings.RevenueExcludingVAT = True Then
		VATLineForShipmentsWithoutTransferOfRights.DataPathRecordFinID = StrReplace(
			"CASE
			|		WHEN DataSourceAlias.ARAPObject <> VALUE(Catalog.ARAPObjects.EmptyRef)
			|			THEN DataSourceAlias.ARAPObject.UUID
			|		ELSE DataSourceAlias.FinRecordID
			|	END",
			"DataSourceAlias",
			FinancialAccountingByBalanceSheetRegisterData.DefaultDataSourceAlias());
		VATLineForShipmentsWithoutTransferOfRights.DataPathSettingUpHouseholdOperations = StrReplace(
			"CASE
			|		WHEN DataSourceAlias.DebitCredit = VALUE(Enum.RecordKindsOfOtherAssetsAndLiabilities.Debit)
			|			THEN DataSourceAlias.BusinessTransactionSetting
			|		WHEN VALUETYPE(DataSourceAlias.Recorder) = TYPE(Document.CustomerInvoiceServicesAndAssets)
			|			THEN VALUE(Catalog.BusinessTransactionsSettings.AccrualVATFromSalesOfGoodsInTransit)
			|		ELSE DataSourceAlias.BusinessTransactionSetting
			|	END",
			"DataSourceAlias",
			FinancialAccountingByBalanceSheetRegisterData.DefaultDataSourceAlias());
	EndIf;
	VATLineForShipmentsWithoutTransferOfRights.VATAccounting = True;
	PathsToExtdimensionData = New Map();
	PathsToExtdimensionData.Insert(ChartsOfCharacteristicTypes.FinancialExtraDimensionTypes.Counterparties, "Dimension");
	VATLineForShipmentsWithoutTransferOfRights.PathsToExtdimensionData = PathsToExtdimensionData;
	
	If TransactionSettings.RevenueExcludingVAT = Undefined Then
		LineVATCalculations = FinancialAccountingObjects.Add();
		LineVATCalculations.AccountingObject = Enums.DeleteFinancialAccountingObjects.VATAccountsPayable;
		LineVATCalculations.FunctionalOptions = Metadata.FunctionalOptions.UseVATAccounting.Name;
		LineVATCalculations.DataPathRecordFinID = StrReplace(
			"CASE
			|		WHEN DataSourceAlias.ARAPObject <> VALUE(Catalog.ARAPObjects.EmptyRef)
			|			THEN DataSourceAlias.ARAPObject.UUID
			|		WHEN VALUETYPE(DataSourceAlias.Recorder) IN (&TypesOfRetailSalesDocuments)
			|		  OR VALUETYPE(DataSourceAlias.Recorder) IN (&TypesOfRetailReturnsDocuments)
			|			THEN SUBSTRING(DataSourceAlias.FinRecordID, 29, 8) +
			|				  SUBSTRING(DataSourceAlias.FinRecordID, 9, 20) +
			|				  SUBSTRING(DataSourceAlias.FinRecordID, 1, 8)
			|		ELSE &IDOfUnusedFinRecord
			|	END",
			"DataSourceAlias",
			FinancialAccountingByBalanceSheetRegisterData.DefaultDataSourceAlias());
		LineVATCalculations.DataPathRowId = "FinRecordID";
		LineVATCalculations.ResourcesQuantity.Add("0");
		LineVATCalculations.VATAccounting = True;
		FillInSignsOfCorrespondenceAccounting(LineVATCalculations, "RevenueExcludingVAT", True);
		
		VATLineForShipmentsWithoutTransferOfRights = FinancialAccountingObjects.Add();
		VATLineForShipmentsWithoutTransferOfRights.AccountingObject = Enums.DeleteFinancialAccountingObjects.VATForShipmentsWithDeferredTransferOfTitle;
		VATLineForShipmentsWithoutTransferOfRights.FunctionalOptions = Metadata.FunctionalOptions.UseVATAccounting.Name;
		Filterdata_ = New Map();
		Filterdata_.Insert("AssetRef", ChartsOfCharacteristicTypes.AssetLiabilityItems.VATForShipmentsWithDeferredTransferOfTitle);
		VATLineForShipmentsWithoutTransferOfRights.Filterdata_ = Filterdata_;
		VATLineForShipmentsWithoutTransferOfRights.DataPathRecordFinID = StrReplace(
			"CASE
			|		WHEN DataSourceAlias.ARAPObject <> VALUE(Catalog.ARAPObjects.EmptyRef)
			|			THEN DataSourceAlias.ARAPObject.UUID
			|		ELSE &IDOfUnusedFinRecord
			|	END",
			"DataSourceAlias",
			FinancialAccountingByBalanceSheetRegisterData.DefaultDataSourceAlias());
		VATLineForShipmentsWithoutTransferOfRights.DataPathSettingUpHouseholdOperations = StrReplace(
			"CASE
			|		WHEN DataSourceAlias.DebitCredit = VALUE(Enum.RecordKindsOfOtherAssetsAndLiabilities.Debit)
			|			THEN DataSourceAlias.BusinessTransactionSetting
			|		WHEN VALUETYPE(DataSourceAlias.Recorder) = TYPE(Document.CustomerInvoiceServicesAndAssets)
			|			THEN VALUE(Catalog.BusinessTransactionsSettings.AccrualVATFromSalesOfGoodsInTransit)
			|		ELSE DataSourceAlias.BusinessTransactionSetting
			|	END",
			"DataSourceAlias",
			FinancialAccountingByBalanceSheetRegisterData.DefaultDataSourceAlias());
		VATLineForShipmentsWithoutTransferOfRights.ResourcesQuantity.Add("0");
		VATLineForShipmentsWithoutTransferOfRights.VATAccounting = True;
		PathsToExtdimensionData = New Map();
		PathsToExtdimensionData.Insert(ChartsOfCharacteristicTypes.FinancialExtraDimensionTypes.Counterparties, "Dimension");
		VATLineForShipmentsWithoutTransferOfRights.PathsToExtdimensionData = PathsToExtdimensionData;
		FillInSignsOfCorrespondenceAccounting(VATLineForShipmentsWithoutTransferOfRights, "RevenueExcludingVAT", True);
		
		SuppressDataWithoutSelectingByResourceComposition(FinancialAccountingObjects,
			Metadata.FunctionalOptions.UseVATAccounting.Name,
			Metadata.AccumulationRegisters.OtherAssetsAndLiabilitiesRecords.Name,,, "0");
	EndIf;
	
	If TransactionSettings.RevenueExcludingVAT = False
	 Or TransactionSettings.RevenueExcludingVAT = Undefined Then
		NDSSSalesLine = FinancialAccountingObjects.Add();
		NDSSSalesLine.AccountingObject = Enums.DeleteFinancialAccountingObjects.VATFromSales;
		NDSSSalesLine.FunctionalOptions = Metadata.FunctionalOptions.UseVATAccounting.Name;
		NDSSSalesLine.DebitCondition = "TRUE";
		NDSSSalesLine.ConditionCredit = "FALSE";
		NDSSSalesLine.DataPathConfigurationObject = "ItemsLocationAttributes.Products.FinancialAccountingGroup";
		NDSSSalesLine.ManResources.Add("RevenueAmount");
		NDSSSalesLine.ManResources.Add("-RevenueAmountExcludingVAT");
		NDSSSalesLine.LocalResources.Add("RevenueAmountIncludingVATLocal");
		NDSSSalesLine.LocalResources.Add("-RevenueAmountExclVATLocal");
		NDSSSalesLine.ResourcesQuantity.Add("0");
		NDSSSalesLine.VATAccounting = True;
		NDSSSalesLine.CorDataSources.Add(Metadata.AccumulationRegisters.VATRegisterRecords.Name);
		NDSSSalesLine.CorDataSources.Add(Metadata.AccumulationRegisters.OtherAssetsAndLiabilitiesRecords.Name);
		If VATAccountingERP.AccountingSettings().DateWhenRefundsAreReflectedInCorrectiveSF > '00010101' Then
			NDSSSalesLine.CorDataSources.Add(Metadata.AccumulationRegisters.VATInvoiced.Name);
		EndIf;
		If TransactionSettings.RevenueExcludingVAT = Undefined Then
			FillInSignsOfCorrespondenceAccounting(NDSSSalesLine, "RevenueExcludingVAT", False);
		EndIf;
		
		NDSSOtherIncomeLine = FinancialAccountingObjects.Add();
		NDSSOtherIncomeLine.AccountingObject = Enums.DeleteFinancialAccountingObjects.VATFromOtherIncome;
		NDSSOtherIncomeLine.FunctionalOptions = Metadata.FunctionalOptions.UseVATAccounting.Name;
		NDSSOtherIncomeLine.DebitCondition = "TRUE";
		NDSSOtherIncomeLine.ConditionCredit = "FALSE";
		NDSSOtherIncomeLine.DataPathConfigurationObject = "IncomeItem.FinancialAccountingGroup";
		NDSSOtherIncomeLine.ManResources.Add("VATManag");
		NDSSOtherIncomeLine.LocalResources.Add("VATLocal");
		NDSSOtherIncomeLine.ResourcesQuantity.Add("0");
		NDSSOtherIncomeLine.VATAccounting = True;
		If TransactionSettings.RevenueExcludingVAT = Undefined Then
			FillInSignsOfCorrespondenceAccounting(NDSSOtherIncomeLine, "RevenueExcludingVAT", False);
		EndIf;
	EndIf;
	
	NDSSLineOfAdvancesReceived = FinancialAccountingObjects.Add();
	NDSSLineOfAdvancesReceived.AccountingObject = Enums.DeleteFinancialAccountingObjects.VATFromPrepaymentsFromCustomer;
	NDSSLineOfAdvancesReceived.FunctionalOptions = Metadata.FunctionalOptions.UseVATAccounting.Name;
	NDSSLineOfAdvancesReceived.VATAccounting = True;
	
	NDSSLineOfAdvancesIssued = FinancialAccountingObjects.Add();
	NDSSLineOfAdvancesIssued.AccountingObject = Enums.DeleteFinancialAccountingObjects.VATFromPrepaymentsToVendor;
	NDSSLineOfAdvancesIssued.FunctionalOptions = Metadata.FunctionalOptions.UseVATAccounting.Name;
	NDSSLineOfAdvancesIssued.VATAccounting = True;
	
EndProcedure

Procedure OtherAccountingItemsProvisionsForImpairment(FinancialAccountingObjects, TransactionSettings)
	
	LineProvisionsForImpairmentOfInventories = FinancialAccountingObjects.Add();
	LineProvisionsForImpairmentOfInventories.AccountingObject = Enums.DeleteFinancialAccountingObjects.ProvisionsForImpairmentOfInventory;
	LineProvisionsForImpairmentOfInventories.FunctionalOptions = Metadata.FunctionalOptions.AccualInventoryImpairmentProvision.Name;
	Filterdata_ = New Map();
	AccountingSections = New Array();
	AccountingSections.Add(Enums.SectionsOfInventoryCostAccounting.ProductStock);
	AccountingSections.Add(Enums.SectionsOfInventoryCostAccounting.OwnGoodsInTransitFromVendors);
	AccountingSections.Add(Enums.SectionsOfInventoryCostAccounting.GoodsInTransit);
	AccountingSections.Add(Enums.SectionsOfInventoryCostAccounting.GoodsInTransitTransferredToCommissionAgent);
	Filterdata_.Insert("AccountingSection", AccountingSections);
	LineProvisionsForImpairmentOfInventories.Filterdata_ = Filterdata_;
	LineProvisionsForImpairmentOfInventories.DataPathConfigurationObject = FinancialAccountingByBalanceSheetRegisterData.HFCProductSampleField();
	LineProvisionsForImpairmentOfInventories.ManResources = ResourcesForAccountingForProvisionForImpairmentOfItemOfMan();
	LineProvisionsForImpairmentOfInventories.LocalResources = LocalItemAllowanceResourcesForImpairment();
	LineProvisionsForImpairmentOfInventories.ResourcesQuantity.Add("0");
	
	LineProvisionsForImpairmentOfInventoriesTransferred = FinancialAccountingObjects.Add();
	LineProvisionsForImpairmentOfInventoriesTransferred.AccountingObject = Enums.DeleteFinancialAccountingObjects.ProvisionsForImpairmentOfInventoriesTransferred;
	FunctionOptionsPassed = New Array();
	FunctionOptionsPassed.Add(Metadata.FunctionalOptions.UseProductionByThirdParty2_5.Name);
	FunctionOptionsPassed.Add(Metadata.FunctionalOptions.UseTransferToCustodyWithRightOfSale.Name);
	FunctionOptionsPassed.Add(Metadata.FunctionalOptions.UseSalesCommission.Name);
	FunctionalOptions = New ValueList();
	FunctionalOptions.Add(Metadata.FunctionalOptions.AccualInventoryImpairmentProvision.Name);
	FunctionalOptions.Add(FunctionOptionsPassed);
	LineProvisionsForImpairmentOfInventoriesTransferred.FunctionalOptions = FunctionalOptions;
	Filterdata_ = New Map();
	AccountingSections = New Array();
	AccountingSections.Add(Enums.SectionsOfInventoryCostAccounting.GoodsTransferredToToller);
	AccountingSections.Add(Enums.SectionsOfInventoryCostAccounting.OwnGoodsTransferredToPartners);
	AccountingSections.Add(Enums.SectionsOfInventoryCostAccounting.GoodsTransferredToCommissionAgent);
	Filterdata_.Insert("AccountingSection", AccountingSections);
	LineProvisionsForImpairmentOfInventoriesTransferred.Filterdata_ = Filterdata_;
	LineProvisionsForImpairmentOfInventoriesTransferred.DataPathConfigurationObject = FinancialAccountingByBalanceSheetRegisterData.HFCProductSampleField();
	LineProvisionsForImpairmentOfInventoriesTransferred.ManResources = ResourcesForAccountingForProvisionForImpairmentOfItemOfMan();
	LineProvisionsForImpairmentOfInventoriesTransferred.LocalResources = LocalItemAllowanceResourcesForImpairment();
	LineProvisionsForImpairmentOfInventoriesTransferred.ResourcesQuantity.Add("0");
	
	LineProvisionsForImpairmentOfInventoryInShopPantry = FinancialAccountingObjects.Add();
	LineProvisionsForImpairmentOfInventoryInShopPantry.AccountingObject = Enums.DeleteFinancialAccountingObjects.ProvisionsForImpairmentOfInventoryInShopPantry;
	FunctionalOptions = New ValueList();
	FunctionalOptions.Add(Metadata.FunctionalOptions.AccualInventoryImpairmentProvision.Name);
	FunctionalOptions.Add(Metadata.FunctionalOptions.UseProduction.Name);
	LineProvisionsForImpairmentOfInventoryInShopPantry.FunctionalOptions = FunctionalOptions;
	Filterdata_ = New Map();
	AccountingSections = New Array();
	AccountingSections.Add(Enums.SectionsOfInventoryCostAccounting.ProductionCosts);
	AccountingSections.Add(Enums.SectionsOfInventoryCostAccounting.GoodsReceivedForRespSafekeeping);
	AccountingSections.Add(Enums.SectionsOfInventoryCostAccounting.VendorManagedInventoryTransferredToPartners);
	Filterdata_.Insert("AccountingSection", AccountingSections);
	Filterdata_.Insert("ItemsLocationAttributes.StorageType", Enums.StorageLocationTypes.Warehouse);
	LineProvisionsForImpairmentOfInventoryInShopPantry.Filterdata_ = Filterdata_;
	LineProvisionsForImpairmentOfInventoryInShopPantry.DataPathConfigurationObject = FinancialAccountingByBalanceSheetRegisterData.HFCProductSampleField();
	LineProvisionsForImpairmentOfInventoryInShopPantry.ManResources = ResourcesForAccountingForProvisionForImpairmentOfItemOfMan();
	LineProvisionsForImpairmentOfInventoryInShopPantry.LocalResources = LocalItemAllowanceResourcesForImpairment();
	LineProvisionsForImpairmentOfInventoryInShopPantry.ResourcesQuantity.Add("0");
	
	LineProvisionsForImpairmentOfUnfinishedProduction = FinancialAccountingObjects.Add();
	LineProvisionsForImpairmentOfUnfinishedProduction.AccountingObject = Enums.DeleteFinancialAccountingObjects.ProvisionsForImpairmentOfWorkInProgress;
	FunctionalOptions = New ValueList();
	FunctionalOptions.Add(Metadata.FunctionalOptions.AccualInventoryImpairmentProvision.Name);
	FunctionalOptions.Add(Metadata.FunctionalOptions.UseProduction.Name);
	LineProvisionsForImpairmentOfUnfinishedProduction.FunctionalOptions = FunctionalOptions;
	GroupOfFilters = New Array();
	Filterdata_ = New Map();
	Filterdata_.Insert("AccountingSection", Enums.SectionsOfInventoryCostAccounting.WorkInProgress);
	GroupOfFilters.Add(Filterdata_);
	Filterdata_ = New Map();
	AccountingSections = New Array();
	AccountingSections.Add(Enums.SectionsOfInventoryCostAccounting.ProductionCosts);
	AccountingSections.Add(Enums.SectionsOfInventoryCostAccounting.GoodsReceivedForRespSafekeeping);
	AccountingSections.Add(Enums.SectionsOfInventoryCostAccounting.VendorManagedInventoryTransferredToPartners);
	Filterdata_.Insert("AccountingSection", AccountingSections);
	StorageLocations_ = New Array();
	StorageLocations_.Add(Enums.StorageLocationTypes.CounterpartyContract);
	StorageLocations_.Add(Enums.StorageLocationTypes.Organization);
	StorageLocations_.Add(Enums.StorageLocationTypes.Partner);
	StorageLocations_.Add(Enums.StorageLocationTypes.Department);
	Filterdata_.Insert("ItemsLocationAttributes.StorageType", StorageLocations_);
	GroupOfFilters.Add(Filterdata_);
	LineProvisionsForImpairmentOfUnfinishedProduction.Filterdata_ = GroupOfFilters;
	LineProvisionsForImpairmentOfUnfinishedProduction.DataPathConfigurationObject = "FinancialAccountingDimension";
	LineProvisionsForImpairmentOfUnfinishedProduction.ManResources = ResourcesForAccountingForProvisionForImpairmentOfItemOfMan();
	LineProvisionsForImpairmentOfUnfinishedProduction.LocalResources = LocalItemAllowanceResourcesForImpairment();
	LineProvisionsForImpairmentOfUnfinishedProduction.ResourcesQuantity.Add("0");
	
	// Other sections of cost accounting that are not described in the selections of accounting items should not be read
	SuppressDataWithoutSelectingByResourceComposition(FinancialAccountingObjects,
		Metadata.FunctionalOptions.AccualInventoryImpairmentProvision.Name,
		Metadata.AccumulationRegisters.InventoryCost.Name,
		ResourcesForAccountingForProvisionForImpairmentOfItemOfMan(),
		LocalItemAllowanceResourcesForImpairment(),
		"0");
	
EndProcedure

Procedure FillInAccountingObjectsLossesAllowanceForDoubtfulDebts(FinancialAccountingObjects, TransactionSettings)
	
	LineProvisionsForDoubtfulDebts = FinancialAccountingObjects.Add();
	LineProvisionsForDoubtfulDebts.AccountingObject = Enums.DeleteFinancialAccountingObjects.LossAllowance;
	LineProvisionsForDoubtfulDebts.FunctionalOptions = Metadata.FunctionalOptions.ToGenerateLossAllowance.Name;
	
EndProcedure

Procedure FillInAccountingObjectsProvisionsAndContingentLiabilities(FinancialAccountingObjects, TransactionSettings)
	
	LineProvisionsProvisions = FinancialAccountingObjects.Add();
	LineProvisionsProvisions.AccountingObject = Enums.DeleteFinancialAccountingObjects.ProvisionsEstimatedLiabilities;
	LineProvisionsProvisions.FunctionalOptions = Metadata.FunctionalOptions.GenerateFutureExpenseCommitments.Name;
	LineProvisionsProvisions.ManResources.Add("SumMan");
	LineProvisionsProvisions.LocalResources.Add("SumCompl");
	
	LinePercentagesOfDiscountingReserves = FinancialAccountingObjects.Add();
	LinePercentagesOfDiscountingReserves.AccountingObject = Enums.DeleteFinancialAccountingObjects.ProvisionDiscountingInterest;
	LinePercentagesOfDiscountingReserves.FunctionalOptions = Metadata.FunctionalOptions.GenerateFutureExpenseCommitments.Name;
	LinePercentagesOfDiscountingReserves.ManResources.Add("DiscountingAmountMan");
	LinePercentagesOfDiscountingReserves.LocalResources.Add("DiscountingAmountCompl");
	
EndProcedure

Procedure OtherAccountingItemsOtherAssetsAndLiabilities(FinancialAccountingObjects, TransactionSettings)
	
	LineCalculationsForTaxesAndContributions = FinancialAccountingObjects.Add();
	LineCalculationsForTaxesAndContributions.AccountingObject = Enums.DeleteFinancialAccountingObjects.TaxesAndContributionsAccountsPayable;;
	Filterdata_ = New Map();
	Filterdata_.Insert("AssetRef", ChartsOfCharacteristicTypes.AssetLiabilityItems.Taxes);
	LineCalculationsForTaxesAndContributions.Filterdata_ = Filterdata_;
	LineCalculationsForTaxesAndContributions.DataPathConfigurationObject = "Dimension";
	
	LineOnFarmCalculations = FinancialAccountingObjects.Add();
	LineOnFarmCalculations.AccountingObject = Enums.DeleteFinancialAccountingObjects.BranchOfficeAccounting;
	LineOnFarmCalculations.FunctionalOptions = Metadata.FunctionalOptions.UseBranchOfficesWithSeparateBalanceSheets.Name;
	Filterdata_ = New Map();
	Filterdata_.Insert("AssetRef", ChartsOfCharacteristicTypes.AssetLiabilityItems.BranchOfficeARAPAccounting);
	LineOnFarmCalculations.Filterdata_ = Filterdata_;
	PathsToExtdimensionData = New Map();
	PathsToExtdimensionData.Insert(ChartsOfCharacteristicTypes.FinancialExtraDimensionTypes.Counterparties, "Dimension");
	LineOnFarmCalculations.PathsToExtdimensionData = PathsToExtdimensionData;
	
	LineCalculationsForAllocatedProperty = FinancialAccountingObjects.Add();
	LineCalculationsForAllocatedProperty.AccountingObject = Enums.DeleteFinancialAccountingObjects.BranchOfficeAssetsAccounting;
	LineCalculationsForAllocatedProperty.FunctionalOptions = Metadata.FunctionalOptions.UseBranchOfficesWithSeparateBalanceSheets.Name;
	Filterdata_ = New Map();
	Filterdata_.Insert("AssetRef", ChartsOfCharacteristicTypes.AssetLiabilityItems.BranchOfficeAssetsARAPAccounting);
	LineCalculationsForAllocatedProperty.Filterdata_ = Filterdata_;
	PathsToExtdimensionData = New Map();
	PathsToExtdimensionData.Insert(ChartsOfCharacteristicTypes.FinancialExtraDimensionTypes.Counterparties, "Dimension");
	LineCalculationsForAllocatedProperty.PathsToExtdimensionData = PathsToExtdimensionData;
	
	LineOfObligationForNonCounterfeitDeliveries = FinancialAccountingObjects.Add();
	LineOfObligationForNonCounterfeitDeliveries.AccountingObject = Enums.DeleteFinancialAccountingObjects.LiabilitiesForGoodsReceivedNotInvoiced;
	LineOfObligationForNonCounterfeitDeliveries.FunctionalOptions = Metadata.FunctionalOptions.UseUninvoicedDeliveries.Name;
	Filterdata_ = New Map();
	Filterdata_.Insert("AccountingSection", Enums.SectionsOfInventoryCostAccounting.UninvoicedDeliveries);
	LineOfObligationForNonCounterfeitDeliveries.Filterdata_ = Filterdata_;
	LineOfObligationForNonCounterfeitDeliveries.ManResources = ManSOwnProductInventoryResources();
	LineOfObligationForNonCounterfeitDeliveries.LocalResources = ResourcesForAccountingForYourOwnLocalProductList();
	
	If TransactionSettings.OptionForGeneratingTransactions = Undefined
	 Or TransactionSettings.OptionForGeneratingTransactions = Enums.EntryGenerationOptions.WithCorrespondence Then
		LineSettlementsOnOffsets = FinancialAccountingObjects.Add();
		LineSettlementsOnOffsets.AccountingObject = Enums.DeleteFinancialAccountingObjects.ARAPSettlements;
	EndIf;
	
	LineInputOfBalances = FinancialAccountingObjects.Add();
	LineInputOfBalances.AccountingObject = Enums.DeleteFinancialAccountingObjects.OBEntry;
	
	LineOtherAssetsLiabilities = FinancialAccountingObjects.Add();
	LineOtherAssetsLiabilities.AccountingObject = Enums.DeleteFinancialAccountingObjects.OtherAssetsLiabilities;
	LineOtherAssetsLiabilities.DataPathConfigurationObject = "GLAccountSettings";
	
EndProcedure

#EndRegion

Function ManSOwnProductInventoryResources()
	
	ManResources = New Array();
	ManResources.Add("CostMan");
	ManResources.Add("AddExpensesMan");
	ManResources.Add("LaborCostsMan");
	ManResources.Add("ItemizedFixedCostsManag");
	ManResources.Add("ItemizedVariableCostsManag");
	
	Return ManResources;
	
EndFunction

Function ResourcesForAccountingForYourOwnLocalProductList()
	
	LocalResources = New Array();
	LocalResources.Add("LocalCost");
	LocalResources.Add("AddExpensesLocal");
	LocalResources.Add("LaborCostsLocal");
	LocalResources.Add("ItemizedFixedCostsCompl");
	LocalResources.Add("ItemizedVariableCostsCompl");
	
	Return LocalResources;
	
EndFunction

Function ResourcesForAccountingForAcceptedItemOfMan()
	
	ManResources = New Array();
	ManResources.Add("OffBalanceCost");
	
	Return ManResources;
	
EndFunction

Function ResourcesForAccountingForAcceptedItemOfLocalRegulations()
	
	LocalResources = New Array();
	LocalResources.Add("OffBalanceCostLocal");
	
	Return LocalResources;
	
EndFunction

Function ResourcesForAccountingForProvisionForImpairmentOfItemOfMan()
	
	ManResources = New Array();
	ManResources.Add("ProvisionForImpairmentMan");
	
	Return ManResources;
	
EndFunction

Function LocalItemAllowanceResourcesForImpairment()
	
	LocalResources = New Array();
	LocalResources.Add("ProvisionForImpairmentLocal");
	
	Return LocalResources;
	
EndFunction

Procedure SuppressDataWithoutSelectingByResourceComposition(FinancialAccountingObjects,
	FunctionalOptions, DataSource,
	ManResources = Undefined, LocalResources = Undefined, ResourcesQuantity = Undefined)
	
	LineIsEmptyAccountingObject = FinancialAccountingObjects.Add();
	LineIsEmptyAccountingObject.AccountingObject = Enums.DeleteFinancialAccountingObjects.EmptyRef();
	LineIsEmptyAccountingObject.FunctionalOptions = FunctionalOptions;
	LineIsEmptyAccountingObject.DataSource = DataSource;
	LineIsEmptyAccountingObject.DataPathRecordFinID = "&IDOfUnusedFinRecord";
	
	If ManResources <> Undefined Then
		LineIsEmptyAccountingObject.ManResources = ArrayOfResources(ManResources);
	EndIf;
	
	If LocalResources <> Undefined Then
		LineIsEmptyAccountingObject.LocalResources = ArrayOfResources(LocalResources);
	EndIf;
	
	If ResourcesQuantity <> Undefined Then
		LineIsEmptyAccountingObject.ResourcesQuantity = ArrayOfResources(ResourcesQuantity);
	EndIf;
	
EndProcedure

Function ArrayOfResources(Resources)
	
	If TypeOf(Resources) = Type("String") Then
		Return StrSplit(Resources, ",");
	Else
		Return TMCommonUseClientServer.Array(Resources);
	EndIf;
	
EndFunction

Procedure FillInSignsOfCorrespondenceAccounting(AccountingObjectLine_, AccountingFlag, Value)
	
	SignsOfCorrespondenceAccounting = NewFeaturesOfCorrespondenceAccounting();
	
	If AccountingObjectLine_.AccountingObject = SalesRevenue
	 Or AccountingObjectLine_.AccountingObject = SalesRevenueExcludingVAT
	 Or AccountingObjectLine_.AccountingObject = VATAccountsPayable
	 Or AccountingObjectLine_.AccountingObject = VATForShipmentsWithDeferredTransferOfTitle Then
		NewRow = SignsOfCorrespondenceAccounting.Add();
		NewRow.AccountingObject = CustomersAccountsReceivable;
		
		NewRow = SignsOfCorrespondenceAccounting.Add();
		NewRow.AccountingObject = PrepaymentsFromCustomers;
		
		NewRow = SignsOfCorrespondenceAccounting.Add();
		NewRow.AccountingObject = RetailCustomerAccountsReceivables;
	EndIf;
	
	If AccountingObjectLine_.AccountingObject = RevenueServicesAndAssets
	 Or AccountingObjectLine_.AccountingObject = RevenueServicesAndAssetsExcludingVAT Then
		NewRow = SignsOfCorrespondenceAccounting.Add();
		NewRow.AccountingObject = CustomersAccountsReceivable;
		
		NewRow = SignsOfCorrespondenceAccounting.Add();
		NewRow.AccountingObject = PrepaymentsFromCustomers;
		
		NewRow = SignsOfCorrespondenceAccounting.Add();
		NewRow.AccountingObject = EmployeeARAPAccounting;
		
		NewRow = SignsOfCorrespondenceAccounting.Add();
		NewRow.AccountingObject = LoansAndBorrowingsIssuedFee;
		
		NewRow = SignsOfCorrespondenceAccounting.Add();
		NewRow.AccountingObject = LoansAndBorrowingsIssuedInterest;
	EndIf;
	
	If AccountingObjectLine_.AccountingObject = VATFromSales
	 Or AccountingObjectLine_.AccountingObject = VATFromOtherIncome Then
		NewRow = SignsOfCorrespondenceAccounting.Add();
		NewRow.AccountingObject = VATAccountsPayable;
		
		NewRow = SignsOfCorrespondenceAccounting.Add();
		NewRow.AccountingObject = VATForShipmentsWithDeferredTransferOfTitle;
	EndIf;
	
	SignsOfCorrespondenceAccounting.FillValues(AccountingFlag, "AccountingFlag");
	SignsOfCorrespondenceAccounting.FillValues(Value, "Value");
	
	AccountingObjectLine_.SignsOfCorrespondenceAccounting = SignsOfCorrespondenceAccounting;
	
EndProcedure

Function NewFeaturesOfCorrespondenceAccounting()
	
	SignsOfCorrespondenceAccounting = New ValueTable();
	SignsOfCorrespondenceAccounting.Columns.Add("AccountingObject", New TypeDescription("EnumRef.DeleteFinancialAccountingObjects"));
	SignsOfCorrespondenceAccounting.Columns.Add("AccountingFlag", Common.StringTypeDetails(150));
	SignsOfCorrespondenceAccounting.Columns.Add("Value", New TypeDescription("Boolean"));
	
	Return SignsOfCorrespondenceAccounting;
	
EndFunction
	
Procedure FillInDataSourcesOfAccountingObjects(FinancialAccountingObjects)
	
	DataSourcesOfAccountingObjects = DataSourcesOfFinancialAccountingObjects();
	
	For Each AccountingObjectLine_ In FinancialAccountingObjects Do
		If IsBlankString(AccountingObjectLine_.DataSource) Then
			DataSource = DataSourcesOfAccountingObjects[AccountingObjectLine_.AccountingObject];
			If ValueIsFilled(DataSource) Then
				AccountingObjectLine_.DataSource = DataSource;
			EndIf;
		EndIf;
	EndDo;
	
EndProcedure

Procedure CompleteAllocationOfNonCurrentAssetsLiabilities(FinancialAccountingObjects)
	
	OnlyShortTermAccountingObjects = New Array();
	OnlyShortTermAccountingObjects.Add(Enums.DeleteFinancialAccountingObjects.PrepaymentsToVendors);
	
	AccumulationRegistersMetadata = Metadata.AccumulationRegisters;
	RegisterReflectionParameters = New Structure();
	
	For Each AccountingObjectLine_ In FinancialAccountingObjects Do
		If IsBlankString(AccountingObjectLine_.DataSource) Then
			Continue;
		EndIf;
		
		MotionReflectionParameters = Undefined;
		
		If Not RegisterReflectionParameters.Property(AccountingObjectLine_.DataSource, MotionReflectionParameters) Then
			RegisterManager = AccumulationRegisters[AccountingObjectLine_.DataSource]; // AccumulationRegisterManager -
			RegisterMetadata = AccumulationRegistersMetadata[AccountingObjectLine_.DataSource];
			MotionReflectionParameters = RegisterManager.ParametersForReflectingRegisteredRecordsInFinancialAccounting(RegisterMetadata); // See FinancialAccountingByBalanceSheetRegisterData.ParametersForReflectingRegisteredRecordsInFinancialAccounting
			RegisterReflectionParameters.Insert(AccountingObjectLine_.DataSource, MotionReflectionParameters);
		EndIf;
		
		If Not MotionReflectionParameters.AllocationOfLongTermAssetsAndLiabilities
		 Or OnlyShortTermAccountingObjects.Find(AccountingObjectLine_.AccountingObject) <> Undefined Then
			AccountingObjectLine_.AllocationOfLongTermAssetsAndLiabilities = False;
		Else
			AccountingObjectLine_.AllocationOfLongTermAssetsAndLiabilities = True;
		EndIf;
	EndDo;
	
EndProcedure

Procedure FillInArticlesFromSelectionSettings(AssetLiabilityItems, Filterdata_)
	
	ValueTypeFilter = TypeOf(Filterdata_);
	
	If ValueTypeFilter = Type("Map") Then
		For Each FilterElement In Filterdata_ Do
			FillInArticlesFromSelectionSettings(AssetLiabilityItems, FilterElement.Value);
		EndDo;
	ElsIf ValueTypeFilter = Type("Array") Then
		For Each FilterElement In Filterdata_ Do
			FillInArticlesFromSelectionSettings(AssetLiabilityItems, FilterElement);
		EndDo;
	ElsIf ValueTypeFilter = Type("ChartOfCharacteristicTypesRef.AssetLiabilityItems") Then
		If AssetLiabilityItems.Find(Filterdata_) = Undefined Then
			AssetLiabilityItems.Add(Filterdata_);
		EndIf;
	EndIf;
	
EndProcedure

#EndRegion

#EndIf
