///////////////////////////////////////////////////////////////////////////////////////////////////////
// Copyright (c) 2025, OOO 1C-Soft
// All rights reserved. This software and the related materials 
// are licensed under a Creative Commons Attribution 4.0 International license (CC BY 4.0).
// To view the license terms, follow the link:
// https://creativecommons.org/licenses/by/4.0/legalcode
///////////////////////////////////////////////////////////////////////////////////////////////////////
//

#Region Public

// Overrides the standard behavior of the AccessManagement subsystem.
//
// Parameters:
//  Settings - Structure:
//   * CaptionsLevelRestrictions - Boolean - Default is True.
//         If set to False, restriction texts in roles are cleared during compilation,
//         access restriction registers are not populated,
//         and record-level restriction settings are hidden in the Administration panel.
//         The property cannot be calculated based on database data, but can depend on metadata,
//         such as the configuration name.
//         When disabled, the system verifies that service registers are empty and, if not, clears them using the
//         AccessUpdateOnRecordsLevel scheduled job.
//         Likewise, the list of access types in delivered access group profiles is cleared during profile
//         and access group updates, resetting access values.
//
//   * StandardOption - Boolean - Default is True. If set to False, the option to switch
//         to the standard mode is hidden in the Administration panel.
//         The SSLImplementationCheck.erf report removes standard variant templates from roles
//         and updates restrictions by removing the condition "#If &RecordLevelAccessRestrictionIsUniversal #Then",
//         keeping only the optimized restriction form, for example, "#ForObject(...)".
//         For the built-in English language, the value is always False and cannot be overridden.
//         This property can only be modified during development and is not allowed to be changed in production.
//
// Example:
//  1. Disable support for the standard option:
//  Settings.StandardOption = False;
//
//  2. Disable record-level restriction.
//
//  2.1. Disable permanently:
//  Settings.RecordLevelRestriction = False;
//
//  2.2. Disable depending on the configuration type:
//  Settings.RecordLevelRestriction = Not StandardSubsystemsServer.IsBaseConfigurationVersion();
//
Procedure OnDefineSettings(Settings) Export
	
EndProcedure

// Fills access kinds used in access restrictions.
// Note: the Users and ExternalUsers access kinds are predefined,
// but you can remove them from the AccessKinds list if you do not need them for access restriction.
//
// Parameters:
//  AccessKinds - ValueTable:
//   * Name                    - String - Name used in the description of the built-in access group profiles and RLS text.
//                                       
//   * Presentation          - String - presents an access kind in profiles and access groups.
//   * ValuesType            - Type    - an access value reference type,
//                                       for example, Type("CatalogRef.Products").
//   * ValuesGroupsType       - Type    - an access value group reference type,
//                                       for example, Type("CatalogRef.ProductsAccessGroups").
//   * MultipleValuesGroups - Boolean - True indicates that you can
//                                       select multiple value groups (Products access group) for an access value (Products).
//
// Example:
//  1. To set access rights by companies:
//  AccessKind = AccessKinds.Add(),
//  AccessKind.Name = "Companies",
//  AccessKind.Presentation = NStr("en = 'Companies'; fa = 'شرکت‌ها'");
//  AccessKind.ValuesType = Type("CatalogRef.Companies");
//
//  2.To set access rights by partner groups:
//  AccessKind = AccessKinds.Add(),
//  AccessKind.Name = "PartnersGroups",
//  AccessKind.Presentation = NStr("en = 'Partner groups'; fa = 'Partner groups'");
//  AccessKind.ValuesType = Type("CatalogRef.Partners");
//  AccessKind.ValuesGroupsType = Type("CatalogRef.PartnersAccessGroups");
//
Procedure OnFillAccessKinds(AccessKinds) Export
	TMAccessManagement.OnFillAccessKinds(AccessKinds);
	AccessManagementLocalization.FillInAccessTypes(AccessKinds);
EndProcedure

// Allows specifying the metadata objects for which the data access restriction logic is set.
// In manager modules of the specified lists, there is a handler procedure, for example:
//
//Parameters:
//Restriction - See AccessManagementOverridable.OnFillAccessRestriction.Restriction.
////
//
//	
//  Procedure OnFillAccessRestriction(Restriction) Export
//  Restriction.Text =
//  "AllowReadUpdate
//  |WHERE
//  |	ValueAllowed(Company)
//	
//|	AND ValueAllowed(Counterparty)";
//
// EndProcedure
// The data access restriction logic can also be overridden in the procedure
// "AccessManagementOverridable.OnFillAccessRestriction".
//
// Parameters:
//  Lists - Map of KeyAndValue - lists with access restriction:
//             * Key     - MetadataObject - a list with access restriction.
//             * Value - Boolean - True - a restriction text in the manager module.
//                                   False - a restriction text in the overridable
//                          module in the OnFillAccessRestriction procedure.
//
Procedure OnFillListsWithAccessRestriction(Lists) Export
	
	TMAccessManagement.OnFillListsWithAccessRestriction(Lists);
	AccessManagementLocalization.OnFillListsWithAccessRestriction(Lists);

	InventoryInOperationServer.OnFillListsWithAccessRestriction(Lists);
	RebatesServer.OnFillListsWithAccessRestriction(Lists);
	GoodsDelivery.OnFillListsWithAccessRestriction(Lists);
	NonCurrentAssets.OnFillListsWithAccessRestriction(Lists);
	FinancialAccountingOfGeneralPurpose.OnFillListsWithAccessRestriction(Lists);
	VATAccountingERP.OnFillListsWithAccessRestriction(Lists);
	
	Lists.Insert(Metadata.Catalogs.ExpenseReportAttachedFiles, True);
	Lists.Insert(Metadata.Catalogs.CustomerInvoiceServicesAttachedFiles, True);
	Lists.Insert(Metadata.Catalogs.GoodsQualityControlCertificateAttachedFiles, True);
	Lists.Insert(Metadata.Catalogs.DiscrepancyReportFollowingShipmentAttachedFiles, True);
	Lists.Insert(Metadata.Catalogs.DiscrepancyReportFollowingTransferAttachedFiles, True);
	Lists.Insert(Metadata.Catalogs.DiscrepancyReportFollowingReceiptAttachedFiles, True);
	Lists.Insert(Metadata.Catalogs.CounterpartyBankAccounts, True);
	Lists.Insert(Metadata.Catalogs.CompaniesBankAccounts, True);
	Lists.Insert(Metadata.Catalogs.ProductKitConfigurations, True);
	Lists.Insert(Metadata.Catalogs.ARAPSettlementAttachedFiles, True);
	Lists.Insert(Metadata.Catalogs.InventoryKinds, True);
	Lists.Insert(Metadata.Catalogs.ItemKinds, True);
	Lists.Insert(Metadata.Catalogs.ItemKindsAttachedFiles, True);
	Lists.Insert(Metadata.Catalogs.TypesOfPrices, True);
	Lists.Insert(Metadata.Catalogs.VendorPriceTypes, True);
	Lists.Insert(Metadata.Catalogs.InventoryConsumptionAttachedFiles, True);
	Lists.Insert(Metadata.Catalogs.IntercompanyGoodsReturnAttachedFiles, True);
	Lists.Insert(Metadata.Catalogs.ReturnOfGoodsFromCustomerAttachedFiles, True);
	Lists.Insert(Metadata.Catalogs.ReturnOfGoodsToVendorAttachedFiles, True);
	Lists.Insert(Metadata.Catalogs.ReturnablePackagingRedemptionByCustomerAttachedFiles, True);
	Lists.Insert(Metadata.Catalogs.RedemptionOfReturnablePackagingFromVendorAttachedFiles, True);
	Lists.Insert(Metadata.Catalogs.RedemptionOfGoodsFromStorageAttachedFiles, True);
	Lists.Insert(Metadata.Catalogs.RedemptionOfGoodsByCustodianAttachedFiles, True);
	Lists.Insert(Metadata.Catalogs.PartnerAccessGroups, True);
	Lists.Insert(Metadata.Catalogs.CounterpartyContracts, True);
	Lists.Insert(Metadata.Catalogs.CounterpartyContractsAttachedFiles, True);
	Lists.Insert(Metadata.Catalogs.LoanAndDepositContracts, True);
	Lists.Insert(Metadata.Catalogs.LoanAndDepositContractsAttachedFiles, True);
	Lists.Insert(Metadata.Catalogs.IntercompanyContracts, True);
	Lists.Insert(Metadata.Catalogs.IntercompanyContractsAttachedFiles, True);
	Lists.Insert(Metadata.Catalogs.AcquiringContracts, True);
	Lists.Insert(Metadata.Catalogs.AcquiringContractsAttachedFiles, True);
	Lists.Insert(Metadata.Catalogs.TransportationJobAttachedFiles, True);
	Lists.Insert(Metadata.Catalogs.JobForSalesRepresentativeAttachedFiles, True);
	Lists.Insert(Metadata.Catalogs.ProjectTasks, True);
	Lists.Insert(Metadata.Catalogs.SalesOrderAttachedFiles, True);
	Lists.Insert(Metadata.Catalogs.InventoryConsumptionOrderAttachedFiles, True);
	Lists.Insert(Metadata.Catalogs.ByAssemblyDisassemblyOrderAttachedFiles, True);
	Lists.Insert(Metadata.Catalogs.PurchaseOrderAttachedFiles, True);
	Lists.Insert(Metadata.Catalogs.PurchaseRequestAttachedFiles, True);
	Lists.Insert(Metadata.Catalogs.ApplicationForCollateralAttachedFiles, True);
	Lists.Insert(Metadata.Catalogs.RequestForReturnOfGoodsFromCustomerAttachedFiles, True);
	Lists.Insert(Metadata.Catalogs.ApplicationForBusinessTripAttachedFiles, True);
	Lists.Insert(Metadata.Catalogs.RequestForGoodsQualityControlAttachedFiles, True);
	Lists.Insert(Metadata.Catalogs.PaymentRequestAttachedFiles, True);
	Lists.Insert(Metadata.Catalogs.CashAccounts, True);
	Lists.Insert(Metadata.Catalogs.CashRegisters, True);
	Lists.Insert(Metadata.Catalogs.ContactPersonsForPartners, True);
	Lists.Insert(Metadata.Catalogs.Counterparties, True);
	Lists.Insert(Metadata.Catalogs.PurchaseAdjustmentAttachedFiles, True);
	Lists.Insert(Metadata.Catalogs.AdjustmentOfARAPAccountingForAdvanceHoldersAttachedFiles, True);
	Lists.Insert(Metadata.Catalogs.SaleAdjustmentAttachedFiles, True);
	Lists.Insert(Metadata.Catalogs.AdjustmentOfPlannedDemandAttachedFiles, True);
	Lists.Insert(Metadata.Catalogs.ReverseVATAccrualAttachedFiles, True);
	Lists.Insert(Metadata.Catalogs.Products, True);
	Lists.Insert(Metadata.Catalogs.ProductCrossReferences, True);
	Lists.Insert(Metadata.Catalogs.ProductCrossReferencesAttachedFiles, True);
	Lists.Insert(Metadata.Catalogs.ProductsAttachedFiles, True);
	Lists.Insert(Metadata.Catalogs.StorageAreas, True);
	Lists.Insert(Metadata.Catalogs.PlannedCashReceiptAttachedFiles, True);
	Lists.Insert(Metadata.Catalogs.ElectronicTicketTransactionAttachedFiles, True);
	Lists.Insert(Metadata.Catalogs.RecognitionOfStockSurplusShippedToCustomerAttachedFiles, True);
	Lists.Insert(Metadata.Catalogs.Companies, True);
	Lists.Insert(Metadata.Catalogs.CompaniesAttachedFiles, True);
	Lists.Insert(Metadata.Catalogs.GoodsShipmentToCustomerAttachedFiles, True);
	Lists.Insert(Metadata.Catalogs.GoodsShipmentFromStorageAttachedFiles, True);
	Lists.Insert(Metadata.Catalogs.PersonsResponsibleAndCompanies, True);
	Lists.Insert(Metadata.Catalogs.WriteOffReportFromCommissionAgentAttachedFiles, True);
	Lists.Insert(Metadata.Catalogs.ConsignmentReportFromCustomerAttachedFiles, True);
	Lists.Insert(Metadata.Catalogs.PurchaseInvoiceConsignmentStockLostAttachedFiles, True);
	Lists.Insert(Metadata.Catalogs.ConsignmentReportToVendorAttachedFiles, True);
	Lists.Insert(Metadata.Catalogs.PurchasingReportToConsignorPrincipalAttachedFiles, True);
	Lists.Insert(Metadata.Catalogs.Partners, True);
	Lists.Insert(Metadata.Catalogs.PartnersAttachedFiles, True);
	Lists.Insert(Metadata.Catalogs.CustomerInvoiceIntercompanyAttachedFiles, True);
	Lists.Insert(Metadata.Catalogs.InventoryTransferAttachedFiles, True);
	Lists.Insert(Metadata.Catalogs.InventoryConsumptionPlanAttachedFiles, True);
	Lists.Insert(Metadata.Catalogs.TransferOfGoodsToBaileeAttachedFiles, True);
	Lists.Insert(Metadata.Catalogs.MisgradingOfGoodsAtCustodianAttachedFiles, True);
	Lists.Insert(Metadata.Catalogs.DamageAtCustodianAttachedFiles, True);
	Lists.Insert(Metadata.Catalogs.PurchasePlanAttachedFiles, True);
	Lists.Insert(Metadata.Catalogs.PlanOfGoodsStockAttachedFiles, True);
	Lists.Insert(Metadata.Catalogs.SalesPlanByCategoriesAttachedFiles, True);
	Lists.Insert(Metadata.Catalogs.SalesPlanAttachedFiles, True);
	Lists.Insert(Metadata.Catalogs.AssemblyDisassemblyPlanAttachedFiles, True);
	Lists.Insert(Metadata.Catalogs.SubscriptionsToCustomerMailoutsAndNotifications, True);
	Lists.Insert(Metadata.Catalogs.BankConfirmationAboutCashReceiptOnEmployeeAccountAttachedFiles, True);
	Lists.Insert(Metadata.Catalogs.BankAccountReceiptNoteAttachedFiles, True);
	Lists.Insert(Metadata.Catalogs.ReceiptOfGoodsToWarehouseAttachedFiles, True);
	Lists.Insert(Metadata.Catalogs.GoodsReceiptFromCustomerAttachedFiles, True);
	Lists.Insert(Metadata.Catalogs.ReceiptOfGoodsFromCustodianAttachedFiles, True);
	Lists.Insert(Metadata.Catalogs.ReceiptOfServicesToBusinessUnitAttachedFiles, True);
	Lists.Insert(Metadata.Catalogs.Complaints, True);
	Lists.Insert(Metadata.Catalogs.ComplaintsAttachedFiles, True);
	Lists.Insert(Metadata.Catalogs.GoodsReceiptForStorageAttachedFiles, True);
	Lists.Insert(Metadata.Catalogs.VendorInvoiceAttachedFiles, True);
	Lists.Insert(Metadata.Catalogs.VendorInvoiceServicesAndAssetsAttachedFiles, True);
	Lists.Insert(Metadata.Catalogs.OtherIncomeExpensesAttachedFiles, True);
	Lists.Insert(Metadata.Catalogs.WarehouseZones, True);
	Lists.Insert(Metadata.Catalogs.MailoutToCustomersAttachedFiles, True);
	Lists.Insert(Metadata.Catalogs.CustomerInvoiceAttachedFiles, True);
	Lists.Insert(Metadata.Catalogs.CustomerInvoiceServicesAndAssetsAttachedFiles, True);
	Lists.Insert(Metadata.Catalogs.VendorPriceListAttachedFiles, True);
	Lists.Insert(Metadata.Catalogs.ARAPReconciliation2_4AttachedFiles, True);
	Lists.Insert(Metadata.Catalogs.ARAPReconciliation2_5_11AttachedFiles, True);
	Lists.Insert(Metadata.Catalogs.SalesOpportunitiesToCustomer, True);
	Lists.Insert(Metadata.Catalogs.SalesOpportunitiesToCustomerAttachedFiles, True);
	Lists.Insert(Metadata.Catalogs.Warerooms, True);
	Lists.Insert(Metadata.Catalogs.StorageBins, True);
	Lists.Insert(Metadata.Catalogs.Warehouses, True);
	Lists.Insert(Metadata.Catalogs.TermsOfSale, True);
	Lists.Insert(Metadata.Catalogs.TermsOfSaleAttachedFiles, True);
	Lists.Insert(Metadata.Catalogs.TermsOfPurchaseFromVendors, True);
	Lists.Insert(Metadata.Catalogs.TermsOfPurchaseFromVendorsAttachedFiles, True);
	Lists.Insert(Metadata.Catalogs.BankAccountIssueAttachedFiles, True);
	Lists.Insert(Metadata.Catalogs.WriteOffDiscrepanciesBetweenReceiptAndPurchaseAttachedFiles, True);
	Lists.Insert(Metadata.Catalogs.ARAPAccountingScheduleAdjustmentAttachedFiles, True);
	Lists.Insert(Metadata.Catalogs.ARAPAdjustmentAttachedFiles, True);
	Lists.Insert(Metadata.Catalogs.ReportOnVMIAdjustmentAttachedFiles, True);
	Lists.Insert(Metadata.Catalogs.WriteOffOfShippedGoodsAttachedFiles, True);
	Lists.Insert(Metadata.Catalogs.BusinessStructure, True);
	Lists.Insert(Metadata.Catalogs.ReversingEntryAttachedFiles, True);
	Lists.Insert(Metadata.Catalogs.CustomerCommercialInvoiceAttachedFiles, True);
	Lists.Insert(Metadata.Catalogs.CCDImportAttachedFiles, True);
	Lists.Insert(Metadata.Catalogs.DeliveryPoints, True);
	Lists.Insert(Metadata.Catalogs.PackagesAndUnitsOfMeasure, True);
	Lists.Insert(Metadata.Catalogs.TermsAndConditionsOfServicesProvidedToCustomersBySalesRepresentatives, True);
	Lists.Insert(Metadata.Catalogs.PriceSetupAttachedFiles, True);
	Lists.Insert(Metadata.Catalogs.ItemsCharacteristics, True);
	Lists.Insert(Metadata.Catalogs.POSTerminals, True);
	Lists.Insert(Metadata.Documents.ExpenseReport, True);
	Lists.Insert(Metadata.Documents.CustomerInvoiceServices, True);
	Lists.Insert(Metadata.Documents.GoodsQualityControlCertificate, True);
	Lists.Insert(Metadata.Documents.DiscrepancyReportFollowingShipment, True);
	Lists.Insert(Metadata.Documents.DiscrepancyReportFollowingTransfer, True);
	Lists.Insert(Metadata.Documents.DiscrepancyReportFollowingReceipt, True);
	Lists.Insert(Metadata.Documents.OBEntryARAP, True);
	Lists.Insert(Metadata.Documents.OBEntryCash, True);
	Lists.Insert(Metadata.Documents.OBEntrySalesForPastPeriods, True);
	Lists.Insert(Metadata.Documents.OBEntryFinancialInstruments, True);
	Lists.Insert(Metadata.Documents.OBEntryOtherExpenses, True);
	Lists.Insert(Metadata.Documents.OBEntryOtherAssetsAndLiabilities, True);
	Lists.Insert(Metadata.Documents.OBEntryAcquiringContractARAP, True);
	Lists.Insert(Metadata.Documents.OBEntryARAPAdvanceHolders, True);
	Lists.Insert(Metadata.Documents.OBEntryGoods, True);
	Lists.Insert(Metadata.Documents.ARAPSettlement, True);
	Lists.Insert(Metadata.Documents.DepositCashIntoCashRegister, True);
	Lists.Insert(Metadata.Documents.InventoryConsumption, True);
	Lists.Insert(Metadata.Documents.IntercompanyGoodsReturn, True);
	Lists.Insert(Metadata.Documents.ReturnOfGoodsFromCustomer, True);
	Lists.Insert(Metadata.Documents.ReturnOfGoodsToVendor, True);
	Lists.Insert(Metadata.Documents.CashWithdrawalFromCashRegister, True);
	Lists.Insert(Metadata.Documents.ReturnablePackagingRedemptionByCustomer, True);
	Lists.Insert(Metadata.Documents.RedemptionOfReturnablePackagingFromVendor, True);
	Lists.Insert(Metadata.Documents.RedemptionOfGoodsFromStorage, True);
	Lists.Insert(Metadata.Documents.RedemptionOfGoodsByCustodian, True);
	Lists.Insert(Metadata.Documents.MovementOfOtherAssetsAndLiabilities, True);
	Lists.Insert(Metadata.Documents.IssuedLetterOfAuthority, True);
	Lists.Insert(Metadata.Documents.TransportationJob, True);
	Lists.Insert(Metadata.Documents.JobForSalesRepresentative, True);
	Lists.Insert(Metadata.Documents.SalesOrder, True);
	Lists.Insert(Metadata.Documents.InventoryConsumptionOrder, True);
	Lists.Insert(Metadata.Documents.TransferOrder, True);
	Lists.Insert(Metadata.Documents.ByAssemblyDisassemblyOrder, True);
	Lists.Insert(Metadata.Documents.PurchaseOrder, True);
	Lists.Insert(Metadata.Documents.PurchaseRequest, True);
	Lists.Insert(Metadata.Documents.ApplicationForCollateral, True);
	Lists.Insert(Metadata.Documents.RequestForReturnOfGoodsFromCustomer, True);
	Lists.Insert(Metadata.Documents.ApplicationForBusinessTrip, True);
	Lists.Insert(Metadata.Documents.PaymentRequest, True);
	Lists.Insert(Metadata.Documents.GoodsQualityControlCertificate, True);
	Lists.Insert(Metadata.Documents.RequestForGoodsQualityControl, True);
	Lists.Insert(Metadata.Documents.ProductRangeChange, True);
	Lists.Insert(Metadata.Documents.PhysicalCountReport, True);
	Lists.Insert(Metadata.Documents.PhysicalCountOfCashAccounts, True);
	Lists.Insert(Metadata.Documents.CashRegisterShift, True);
	Lists.Insert(Metadata.Documents.ARAPAdjustmentFinancialInstruments, True);
	Lists.Insert(Metadata.Documents.InventoryAdjustmentSurplusesAndShortages, True);
	Lists.Insert(Metadata.Documents.InventoryAssignmentAdjustment, True);
	Lists.Insert(Metadata.Documents.InventoryAdjustmentGoodsShipmentOrder, True);
	Lists.Insert(Metadata.Documents.PurchaseAdjustment, True);
	Lists.Insert(Metadata.Documents.AdjustmentOfARAPAccountingForAdvanceHolders, True);
	Lists.Insert(Metadata.Documents.SaleAdjustment, True);
	Lists.Insert(Metadata.Documents.AdjustmentOfPlannedDemand, True);
	Lists.Insert(Metadata.Documents.CashFlowLimits, True);
	Lists.Insert(Metadata.Documents.ReverseVATAccrual, True);
	Lists.Insert(Metadata.Documents.LoanAndDepositInterestCharge, True);
	Lists.Insert(Metadata.Documents.PlannedCashReceipt, True);
	Lists.Insert(Metadata.Documents.PaymentCardTransaction, True);
	Lists.Insert(Metadata.Documents.ElectronicTicketTransaction, True);
	Lists.Insert(Metadata.Documents.InventorySurplusRecognition, True);
	Lists.Insert(Metadata.Documents.RecognitionOfStockSurplusShippedToCustomer, True); 
	Lists.Insert(Metadata.Documents.GoodsSurplusesNote, True);
	Lists.Insert(Metadata.Documents.GoodsShortageNote, True);
	Lists.Insert(Metadata.Documents.GoodsMisgradingNote, True);
	Lists.Insert(Metadata.Documents.DamageNote, True);
	Lists.Insert(Metadata.Documents.GoodsTransferNote, True);
	Lists.Insert(Metadata.Documents.GoodsPickingPlacement, True);
	Lists.Insert(Metadata.Documents.GoodsShipmentToCustomer, True);
	Lists.Insert(Metadata.Documents.GoodsShipmentFromStorage, True);
	Lists.Insert(Metadata.Documents.CashDepositWithdrawalDiscrepancies, True);
	Lists.Insert(Metadata.Documents.BankReportOnAcquiringTransactions, True);
	Lists.Insert(Metadata.Documents.ConsignmentReportFromCustomer, True);
	Lists.Insert(Metadata.Documents.WriteOffReportFromCommissionAgent, True);
	Lists.Insert(Metadata.Documents.ConsignmentReportToVendor, True);
	Lists.Insert(Metadata.Documents.PurchasingReportToConsignorPrincipal, True);
	Lists.Insert(Metadata.Documents.PurchaseInvoiceConsignmentStockLost, True);	
	Lists.Insert(Metadata.Documents.RetailReturnsReport, True);
	Lists.Insert(Metadata.Documents.RetailSalesReport, True);
	Lists.Insert(Metadata.Documents.CommissionReportIntercompany, True);
	Lists.Insert(Metadata.Documents.CommissionWriteOffReportIntercompany, True);
	Lists.Insert(Metadata.Documents.SourceDocument, True);
	Lists.Insert(Metadata.Documents.CustomerInvoiceIntercompany, True);
	Lists.Insert(Metadata.Documents.TransferOfGoodsToBailee, True);
	Lists.Insert(Metadata.Documents.InventoryTransfer, True);
	Lists.Insert(Metadata.Documents.GoodsMisgrading, True);
	Lists.Insert(Metadata.Documents.InventoryRecount, True);
	Lists.Insert(Metadata.Documents.InventoryConsumptionPlan, True);
	Lists.Insert(Metadata.Documents.PurchasePlan, True);
	Lists.Insert(Metadata.Documents.PlanOfGoodsStock, True);
	Lists.Insert(Metadata.Documents.SalesPlan, True);
	Lists.Insert(Metadata.Documents.SalesPlanByCategories, True);
	Lists.Insert(Metadata.Documents.AssemblyDisassemblyPlan, True);
	Lists.Insert(Metadata.Documents.BankConfirmationAboutCashReceiptOnEmployeeAccount, True);
	Lists.Insert(Metadata.Documents.InstructionForShippingAgent, True);
	Lists.Insert(Metadata.Documents.GoodsDamage, True);
	Lists.Insert(Metadata.Documents.BankAccountReceiptNote, True);
	Lists.Insert(Metadata.Documents.ReceiptOfGoodsToWarehouse, True);
	Lists.Insert(Metadata.Documents.GoodsReceiptFromCustomer, True);
	Lists.Insert(Metadata.Documents.ReceiptOfGoodsFromCustodian, True);
	Lists.Insert(Metadata.Documents.ReceiptOfServicesToBusinessUnit, True);
	Lists.Insert(Metadata.Documents.GoodsReceiptForStorage, True);
	Lists.Insert(Metadata.Documents.VendorInvoice, True);
	Lists.Insert(Metadata.Documents.VendorInvoiceServicesAndAssets, True);
	Lists.Insert(Metadata.Documents.CashAccountReceiptNote, True);
	Lists.Insert(Metadata.Documents.GoodsReceiptNote, True);
	Lists.Insert(Metadata.Documents.OtherGoodsRecordingAsReceived, True);
	Lists.Insert(Metadata.Documents.OtherIncomeExpenses, True);
	Lists.Insert(Metadata.Documents.CashTransferReferenceOrder, True);
	Lists.Insert(Metadata.Documents.AllocationOfIncomeByLinesOfBusiness, True);
	Lists.Insert(Metadata.Documents.AllocationOfOtherCosts, True);
	Lists.Insert(Metadata.Documents.DeferredExpensesAllocation, True);
	Lists.Insert(Metadata.Documents.CashVoucher, True);
	Lists.Insert(Metadata.Documents.GoodsIssueNote, True);
	Lists.Insert(Metadata.Documents.ExchangeDifferenceCalculation, True);
	Lists.Insert(Metadata.Documents.CalculationOfDiscountInterestExpenses, True);
	Lists.Insert(Metadata.Documents.InventoryCostCalculation, True);
	Lists.Insert(Metadata.Documents.CustomerInvoice, True);
	Lists.Insert(Metadata.Documents.CustomerInvoiceServicesAndAssets, True);
	Lists.Insert(Metadata.Documents.VendorContractVendorAgreementRecorder, True);
	Lists.Insert(Metadata.Documents.CostCalculationRecorder, True);
	Lists.Insert(Metadata.Documents.VendorPriceList, True);
	Lists.Insert(Metadata.Documents.AssemblyFromComponents, True);
	Lists.Insert(Metadata.Documents.ARAPReconciliation2_4, True);
	Lists.Insert(Metadata.Documents.ARAPReconciliation2_5_11, True);
	Lists.Insert(Metadata.Documents.ReconcileOpeningBalancesByWarehouses, True);
	Lists.Insert(Metadata.Documents.BankAccountIssue, True);
	Lists.Insert(Metadata.Documents.ARAPAccountingScheduleAdjustment, True);
	Lists.Insert(Metadata.Documents.ARAPAdjustment, True);
	Lists.Insert(Metadata.Documents.WriteOffOfGoodsShortages, True);
	Lists.Insert(Metadata.Documents.ReportOnVMIAdjustment, True);
	Lists.Insert(Metadata.Documents.WriteOffOfShippedGoods, True);
	Lists.Insert(Metadata.Documents.MisgradingOfGoodsAtCustodian, True);
	Lists.Insert(Metadata.Documents.DamageAtCustodian, True);
	Lists.Insert(Metadata.Documents.WriteOffDiscrepanciesBetweenReceiptAndPurchase, True);
	Lists.Insert(Metadata.Documents.ReversingEntry, True);
	Lists.Insert(Metadata.Documents.CustomerCommercialInvoice, True);
	Lists.Insert(Metadata.Documents.CCDImport, True);
	Lists.Insert(Metadata.Documents.SetStorageBinLocks, True);
	Lists.Insert(Metadata.Documents.PriceSetup, True);
	Lists.Insert(Metadata.Documents.CashRegisterReceipt, True);
	Lists.Insert(Metadata.Documents.CashRegisterReceiptReturn, True);
	Lists.Insert(Metadata.Documents.ReceiptOfCashRegisterAdjustment, True);
	Lists.Insert(Metadata.DocumentJournals.ARAPReconciliations, True);
	Lists.Insert(Metadata.DocumentJournals.GoodsReceiptIssue, True);
	Lists.Insert(Metadata.DocumentJournals.SurplusesShortagesAndDamageOfGoods, True);
	Lists.Insert(Metadata.DocumentJournals.CashRegisterReceipts, True);
	Lists.Insert(Metadata.InformationRegisters.ABCXYZCustomerClassification, True);
	Lists.Insert(Metadata.InformationRegisters.GoodsProcurementStrategy, True);
	Lists.Insert(Metadata.InformationRegisters.ScheduleOfPayments, True);
	Lists.Insert(Metadata.InformationRegisters.DatesOfConsignmentGoodsTransfer, True);
	Lists.Insert(Metadata.InformationRegisters.SourceDocumentsData, True);
	Lists.Insert(Metadata.InformationRegisters.DatesOfConsignmentGoodsTransfer, True);
	Lists.Insert(Metadata.InformationRegisters.ItemizeGoodsLotCost, True);
	Lists.Insert(Metadata.InformationRegisters.ItemizeLotCostItemizedAndOtherCosts, True);
	Lists.Insert(Metadata.InformationRegisters.ItemizeGoodsCostItemizedAndOtherCosts, True);
	Lists.Insert(Metadata.InformationRegisters.DocumentsPersons, True);
	Lists.Insert(Metadata.InformationRegisters.GoodsAvailabilityForExternalUsers, True);
	Lists.Insert(Metadata.InformationRegisters.AvailableStockBalances, True);
	Lists.Insert(Metadata.InformationRegisters.MasterDataDuplicates, True);
	Lists.Insert(Metadata.InformationRegisters.MasterDataDuplicatesToConfirm, True);
	Lists.Insert(Metadata.InformationRegisters.JobsForAllocatingInventory, True);
	Lists.Insert(Metadata.InformationRegisters.JobsForAllocatingCustomersARAP, True);
	Lists.Insert(Metadata.InformationRegisters.JobsForAllocatingVendorsARAP, True);
	Lists.Insert(Metadata.InformationRegisters.SourcesOfInitialRequests, True);
	Lists.Insert(Metadata.InformationRegisters.CustomerShoppingCart, True);
	Lists.Insert(Metadata.InformationRegisters.SetUpSupplyControl, True);
	Lists.Insert(Metadata.InformationRegisters.CustomizeCustomerInvoiceIntercompany, True);
	Lists.Insert(Metadata.InformationRegisters.SettingsOfBinLocationWarehouses, True);
	Lists.Insert(Metadata.InformationRegisters.BankAccountBalanceAccordingToStatementData, True);
	Lists.Insert(Metadata.InformationRegisters.InventoryAdjustmentSurplusesAndShortagesGenerationQueue, True);
	Lists.Insert(Metadata.InformationRegisters.LotAndCostCalculationErrors, True);
	Lists.Insert(Metadata.InformationRegisters.SegmentPartners, True);
	Lists.Insert(Metadata.InformationRegisters.GoodsPlacementRules, True);
	Lists.Insert(Metadata.InformationRegisters.PackageConsumptionForecasts, True);
	Lists.Insert(Metadata.InformationRegisters.PlaceProductsInStorageBins, True);
	Lists.Insert(Metadata.InformationRegisters.InventoryAllocation, True);
	Lists.Insert(Metadata.InformationRegisters.CalculationOfPlanShortagesByStages, True);
	Lists.Insert(Metadata.InformationRegisters.DocumentsRegistry, True);
	Lists.Insert(Metadata.InformationRegisters.ABCXYZInventoryClassification, True);
	Lists.Insert(Metadata.InformationRegisters.RelationshipsBetweenPartners, True);
	Lists.Insert(Metadata.InformationRegisters.StatesAndDetailsOfDelivery, True);
	Lists.Insert(Metadata.InformationRegisters.DiscountRates, True);
	Lists.Insert(Metadata.InformationRegisters.StatisticsOfCustomerOpportunities, True);
	Lists.Insert(Metadata.InformationRegisters.GoodsCost, True);
	Lists.Insert(Metadata.InformationRegisters.SupplySchemes, True);
	Lists.Insert(Metadata.InformationRegisters.ProductRestrictions, True);
	Lists.Insert(Metadata.InformationRegisters.FinancialAccountingPolicy, True);
	Lists.Insert(Metadata.InformationRegisters.TaxationSystemSettings, True);
	Lists.Insert(Metadata.InformationRegisters.VATAccountingSettings, True);
	Lists.Insert(Metadata.InformationRegisters.FullNameOfPersons, True);
	Lists.Insert(Metadata.InformationRegisters.ItemsPrices, True);
	Lists.Insert(Metadata.InformationRegisters.ItemsPrices25, True);
	Lists.Insert(Metadata.InformationRegisters.ItemsPricesOfVendor, True);
	Lists.Insert(Metadata.InformationRegisters.ItemsBarcodes, True);
	Lists.Insert(Metadata.InformationRegisters.FiscalTransactions, True);
	Lists.Insert(Metadata.AccumulationRegisters.RevenueAndCOGS, True);
	Lists.Insert(Metadata.AccumulationRegisters.RevenueServicesAndAssets, True);
	Lists.Insert(Metadata.AccumulationRegisters.RecordsCashIncomeExpenses, True);
	Lists.Insert(Metadata.AccumulationRegisters.RecordsCashCounterparty, True);
	Lists.Insert(Metadata.AccumulationRegisters.CashFlow, True);
	Lists.Insert(Metadata.AccumulationRegisters.RecordsIncomeExpensesOtherAssetsLiabilities, True);
	Lists.Insert(Metadata.AccumulationRegisters.RecordsCounterpartyIncomeExpenses, True);
	Lists.Insert(Metadata.AccumulationRegisters.RecordsCounterpartyCounterparty, True);
	Lists.Insert(Metadata.AccumulationRegisters.RegisterRecordsProductsIncomeExpenses, True);
	Lists.Insert(Metadata.AccumulationRegisters.RecordsProductsProducts, True);
	Lists.Insert(Metadata.AccumulationRegisters.RegisterRecordsByExcises, True);
	Lists.Insert(Metadata.AccumulationRegisters.OtherAssetsAndLiabilitiesRecords, True);
	Lists.Insert(Metadata.AccumulationRegisters.GoodsBatchMovement, True);
	Lists.Insert(Metadata.AccumulationRegisters.BankAccountCash, True);
	Lists.Insert(Metadata.AccumulationRegisters.CashInCashRegistersCR, True);
	Lists.Insert(Metadata.AccumulationRegisters.CashInTransit, True);
	Lists.Insert(Metadata.AccumulationRegisters.CashToBePaid, True);
	Lists.Insert(Metadata.AccumulationRegisters.CashAccountBalance, True);
	Lists.Insert(Metadata.AccumulationRegisters.AdvanceHolderCash, True);
	Lists.Insert(Metadata.AccumulationRegisters.ShipmentAndReturnReferences, True);
	Lists.Insert(Metadata.AccumulationRegisters.InventoryConsumptionOrders, True);
	Lists.Insert(Metadata.AccumulationRegisters.TransferOrders, True);
	Lists.Insert(Metadata.AccumulationRegisters.AssemblyOrders, True);
	Lists.Insert(Metadata.AccumulationRegisters.PurchaseOrders, True);
	Lists.Insert(Metadata.AccumulationRegisters.Purchases, True);
	Lists.Insert(Metadata.AccumulationRegisters.InventoryAndDemands, True);
	Lists.Insert(Metadata.AccumulationRegisters.AdjustmentsToPlannedDemands, True);
	Lists.Insert(Metadata.AccumulationRegisters.CashFlowLimits, True);
	Lists.Insert(Metadata.AccumulationRegisters.MaterialsAndWorksInProduction, True);
	Lists.Insert(Metadata.AccumulationRegisters.ItemisedExpensesLots, True);
	Lists.Insert(Metadata.AccumulationRegisters.LotsVATForAllocation, True);
	Lists.Insert(Metadata.AccumulationRegisters.TransferredReturnablePackaging, True);
	Lists.Insert(Metadata.AccumulationRegisters.PurchasePlans, True);
	Lists.Insert(Metadata.AccumulationRegisters.PlansOfGoodsStock, True);
	Lists.Insert(Metadata.AccumulationRegisters.CashFlowPlansCustomers, True);
	Lists.Insert(Metadata.AccumulationRegisters.CashFlowPlansVendors, True);
	Lists.Insert(Metadata.AccumulationRegisters.ComponentsConsumptionPlans, True);
	Lists.Insert(Metadata.AccumulationRegisters.SalesPlans, True);
	Lists.Insert(Metadata.AccumulationRegisters.SalesPlansByCategories, True);
	Lists.Insert(Metadata.AccumulationRegisters.AssemblyDisassemblyPlans, True);
	Lists.Insert(Metadata.AccumulationRegisters.InventoryConsumptionPlans, True);
	Lists.Insert(Metadata.AccumulationRegisters.ReceivedReturnablePackaging, True);
	Lists.Insert(Metadata.AccumulationRegisters.DiscountInterestExpense, True);
	Lists.Insert(Metadata.AccumulationRegisters.OtherAssetsLiabilities, True);
	Lists.Insert(Metadata.AccumulationRegisters.OtherIncome, True);
	Lists.Insert(Metadata.AccumulationRegisters.OtherExpenses, True);
	Lists.Insert(Metadata.AccumulationRegisters.FinancialInstrumentsARAP, True);
	Lists.Insert(Metadata.AccumulationRegisters.AcquiringContractARAP, True);
	Lists.Insert(Metadata.AccumulationRegisters.CustomersARAPAccounting, True);
	Lists.Insert(Metadata.AccumulationRegisters.CustomersARAPAccountingByDocuments, True);
	Lists.Insert(Metadata.AccumulationRegisters.CustomersARAPAccountingByDueDates, True);
	Lists.Insert(Metadata.AccumulationRegisters.CustomersARAPAccountingCashFlowPlan, True);
	Lists.Insert(Metadata.AccumulationRegisters.CustomersARAPAccountingPlannedShipments, True);
	Lists.Insert(Metadata.AccumulationRegisters.VendorsARAPAccounting, True);
	Lists.Insert(Metadata.AccumulationRegisters.VendorsARAPAccountingByDocuments, True);
	Lists.Insert(Metadata.AccumulationRegisters.VendorsARAPAccountingByDueDates, True);
	Lists.Insert(Metadata.AccumulationRegisters.VendorsARAPAccountingCashFlowPlan, True);
	Lists.Insert(Metadata.AccumulationRegisters.VendorsARAPAccountingPlannedDeliveries, True);
	Lists.Insert(Metadata.AccumulationRegisters.CompanySafeStock, True);
	Lists.Insert(Metadata.AccumulationRegisters.InventoryCost, True);
	Lists.Insert(Metadata.AccumulationRegisters.GoodsCostVariances, True);
	Lists.Insert(Metadata.AccumulationRegisters.CargoItemsForRecordingSurplusesAndShortages, True);
	Lists.Insert(Metadata.AccumulationRegisters.GoodsInStorageBins, True);
	Lists.Insert(Metadata.AccumulationRegisters.GoodsForIssue, True);
	Lists.Insert(Metadata.AccumulationRegisters.GoodsForRegistrationOfSurplusesAndShortages, True);
	Lists.Insert(Metadata.AccumulationRegisters.GoodsToBeRegisteredInReportsToConsignor, True);
	Lists.Insert(Metadata.AccumulationRegisters.GoodsForRegistrationOfImportDocuments, True);
	Lists.Insert(Metadata.AccumulationRegisters.GoodsToReceive, True);
	Lists.Insert(Metadata.AccumulationRegisters.ProductStock, True);
	Lists.Insert(Metadata.AccumulationRegisters.CompanyGoods, True);
	Lists.Insert(Metadata.AccumulationRegisters.CompanyGoodsForTransfer, True);
	Lists.Insert(Metadata.AccumulationRegisters.GoodsTransferredToCommissionAgent, True);
	Lists.Insert(Metadata.AccumulationRegisters.GoodsAndServicesToRegisterPurchasingReportsToConsignor, True);
	Lists.Insert(Metadata.AccumulationRegisters.ServicesForRegistrationOfReportsToPrincipal, True);
	Lists.Insert(Metadata.AccumulationRegisters.FinancialResults, True);
	Lists.Insert(Metadata.AccumulationRegisters.ShipmentAndReturnReferences, True); 
	Lists.Insert(Metadata.BusinessProcesses.PriceApproval, True);
	Lists.Insert(Metadata.BusinessProcesses.StandardSale, True);
	Lists.Insert(Metadata.Catalogs.PersonsAttachedFiles, True);
	// Redefining the restriction of BZKR lists.
	Lists.Insert(Metadata.Catalogs.Persons, False);
	
	Lists.Insert(Metadata.Catalogs.InternalAcceptanceCertificateAttachedFiles, True);
	Lists.Insert(Metadata.Catalogs.BudgetProfiles, True);
	Lists.Insert(Metadata.Catalogs.MovementOfProductsAndMaterialsAttachedFiles, True);
	Lists.Insert(Metadata.Catalogs.DocumentsFAAttachedFiles, True);
	Lists.Insert(Metadata.Catalogs.OrderOfMaterialsForProductionAttachedFiles, True);
	Lists.Insert(Metadata.Catalogs.SubcontractOrder2_5AttachedFiles, True);
	Lists.Insert(Metadata.Catalogs.NonFinancialItemsOfBudgets, True);
	Lists.Insert(Metadata.Catalogs.FutureExpenseCommitmentsAccrualWriteOffAttachedFiles, True);
	Lists.Insert(Metadata.Catalogs.AccountingObjectsOfFutureExpenseCommitments, True);
	Lists.Insert(Metadata.Catalogs.AccrualAndWriteOffOfBadDebtAlowancesAttachedFiles, True);
	Lists.Insert(Metadata.Catalogs.PostingPayrollExpensesInFinancialAccounting2_5AttachedFiles, True);
	Lists.Insert(Metadata.Catalogs.SubcontractorReport2_5AttachedFiles, True);
	Lists.Insert(Metadata.Catalogs.ProductionLots, True);
	Lists.Insert(Metadata.Catalogs.ProductionPlanAttachedFiles, True);
	Lists.Insert(Metadata.Catalogs.BudgetBalanceItems, True);
	Lists.Insert(Metadata.Catalogs.BudgetingLimits, True);
	Lists.Insert(Metadata.Catalogs.RuleForCalculatingRelatedBudgetBalancesAndTurnovers, True);
	Lists.Insert(Metadata.Catalogs.BackflushProductionAttachedFiles, True);
	Lists.Insert(Metadata.Catalogs.RecyclableWasteAllocationAttachedFiles, True);
	Lists.Insert(Metadata.Catalogs.BudgetFlowItems, True);
	Lists.Insert(Metadata.Catalogs.BudgetingScenarios, True);
	Lists.Insert(Metadata.Catalogs.BudgetEntryFormAttachedFiles, True);
	Lists.Insert(Metadata.Catalogs.LeaseContract, True);
	Lists.Insert(Metadata.Catalogs.LeaseContractAttachedFiles, True);
	Lists.Insert(Metadata.Catalogs.RulesForCalculationOfInventoryImpairmentProvision, True); 
	Lists.Insert(Metadata.Documents.InternalAcceptanceCertificate, True);
	Lists.Insert(Metadata.Documents.WorkOutput, True);
	Lists.Insert(Metadata.Documents.MovementOfProductsAndMaterials, True);
	Lists.Insert(Metadata.Documents.OrderOfMaterialsForProduction, True);
	Lists.Insert(Metadata.Documents.SubcontractOrder2_5, True);
	Lists.Insert(Metadata.Documents.AccrualAndWriteOffOfBadDebtAlowances, True);
	Lists.Insert(Metadata.Documents.FutureExpenseCommitmentsAccrualWriteOff, True);
	Lists.Insert(Metadata.Documents.PostingPayrollExpensesInFinancialAccounting2_5, True);
	Lists.Insert(Metadata.Documents.SubcontractorReport2_5, True);
	Lists.Insert(Metadata.Documents.ProductionPlan, True);
	Lists.Insert(Metadata.Documents.BackflushProduction, True);
	Lists.Insert(Metadata.Documents.RecyclableWasteAllocation, True);
	Lists.Insert(Metadata.Documents.SetValuesForNonFinancialItems, True);
	Lists.Insert(Metadata.Documents.SettingOfEstimatesOpeningBalance, True);
	Lists.Insert(Metadata.Documents.BudgetEntryForm, True);
	Lists.Insert(Metadata.Documents.CalculationOfInventoryImpairmentProvision, True); 
	Lists.Insert(Metadata.InformationRegisters.AllocationBaseForIndirectExpensesAllocation, True);
	Lists.Insert(Metadata.InformationRegisters.JobsForCalculatingFixedAssetDepreciation, True);
	Lists.Insert(Metadata.InformationRegisters.JobsForCalculatingIntangibleAssetAmortization, True);
	Lists.Insert(Metadata.InformationRegisters.JobsForCalculatingNonCurrentAssetCost, True);
	Lists.Insert(Metadata.InformationRegisters.JobsForGeneratingFixedAssetRecords, True);
	Lists.Insert(Metadata.InformationRegisters.NonFinancialItemValues, True);
	Lists.Insert(Metadata.InformationRegisters.OpeningBalanceOfEstimates, True);
	Lists.Insert(Metadata.InformationRegisters.ProductionSupplySchemes, True);
	Lists.Insert(Metadata.AccumulationRegisters.OtherAssetsAndLiabilitiesRecords, True);
	Lists.Insert(Metadata.AccumulationRegisters.OrdersOfMaterialsForProduction, True);
	Lists.Insert(Metadata.AccumulationRegisters.LimitsByBudgetingData, True);
	Lists.Insert(Metadata.AccumulationRegisters.BudgetTurnovers, True);
	Lists.Insert(Metadata.AccumulationRegisters.ReleasePlansProducts_, True);
	Lists.Insert(Metadata.AccumulationRegisters.ProductionPlans, True);
	Lists.Insert(Metadata.AccumulationRegisters.FutureExpenseCommitments, True);
	Lists.Insert(Metadata.AccumulationRegisters.LossAllowance, True);
	Lists.Insert(Metadata.AccumulationRegisters.LaborCostsToRegister, True);
	Lists.Insert(Metadata.AccumulationRegisters.WIPLaborCosts, True);
	Lists.Insert(Metadata.AccumulationRegisters.OtherWorkInProgressExpenses, True);
	Lists.Insert(Metadata.AccumulationRegisters.PlansOfHumanResourcesOccupancy, True);
	Lists.Insert(Metadata.AccumulationRegisters.MaterialConsumptionPlans, True);
	Lists.Insert(Metadata.AccumulationRegisters.ActualBudgetingData, True);
	Lists.Insert(Metadata.Catalogs.MaterialProviderOrder2_5AttachedFiles, True);
	Lists.Insert(Metadata.Catalogs.ProductionOrder2_2AttachedFiles, True);
	Lists.Insert(Metadata.Catalogs.ReportToMaterialProvider2_5AttachedFiles, True);
	Lists.Insert(Metadata.Catalogs.ConsumptionReportSubcontractingServicesDeliveredIntercompanyAttachedFiles, True);
	Lists.Insert(Metadata.Documents.ProductionOrder2_2, True);
	Lists.Insert(Metadata.Documents.MaterialProviderOrder2_5, True);
	Lists.Insert(Metadata.Documents.WIPOpeningBalancesByProductionLots, True);
	Lists.Insert(Metadata.Documents.InitialWIPBalancesByBusinessUnits, True);
	Lists.Insert(Metadata.Documents.ReportToMaterialProvider2_5, True);
	Lists.Insert(Metadata.Documents.ConsumptionReportSubcontractingServicesDeliveredIntercompany, True);
	Lists.Insert(Metadata.Documents.StandardCosting2_2, True);
	Lists.Insert(Metadata.Documents.ProductionOperation2_2, True);
	Lists.Insert(Metadata.Documents.ShiftTask, True);
	Lists.Insert(Metadata.Documents.SetProductionExpenseStandards, True);
	Lists.Insert(Metadata.Documents.ProductionStage2_2, True);
	Lists.Insert(Metadata.Documents.RegistrarOfBudgetTurnover, True);
	Lists.Insert(Metadata.InformationRegisters.QueueOfProductionOperations, True);
	Lists.Insert(Metadata.AccumulationRegisters.OccupancyPlansForWorkCenterTypes, True);
	Lists.Insert(Metadata.AccumulationRegisters.ReferencesToTransferFromProduction, True);
	Lists.Insert(Metadata.Tasks.BudgetTask, True);
	Lists.Insert(Metadata.BusinessProcesses.ApprovalOfEngineeringChangeOrders, True);
	//++ WE
	Lists.Insert(Metadata.Documents.ShiftScheduleHR, True);
	Lists.Insert(Metadata.Documents.TimesheetHR, True);
	Lists.Insert(Metadata.Documents.PayrollStatementHR, True);

	If Not Common.SubsystemExists("SalaryPersonnelSubsystems") Then
		Lists.Insert(Metadata.Catalogs.EmployeesHR, False);
	EndIf;
	
	//-- WE
	
EndProcedure

// Fills descriptions of built-in access group profiles and
// overrides update parameters of profiles and access groups.
//
// To generate the procedure code automatically, it is recommended that you use the developer
// tools from the Access management subsystem.
//
// Parameters:
//  ProfilesDetails - Array of See AccessManagement.NewAccessGroupProfileDescription,
//                               See AccessManagement.NewDescriptionOfTheAccessGroupProfilesFolder
//  ParametersOfUpdate - Structure:
//   * UpdateModifiedProfiles - Boolean - an initial value is True.
//   * DenyProfilesChange - Boolean - an initial value is True.
//        If False, the built-in profiles can not only be viewed but also edited.
//   * UpdatingAccessGroups     - Boolean - an initial value is True.
//   * UpdatingAccessGroupsWithObsoleteSettings - Boolean - the initial value is False.
//       If True, the value settings made by the administrator for
//       he access kind, which was deleted from the profile, are also deleted from the access groups.
//
// Example:
//  ProfileDetails = AccessManagement.NewAccessGroupProfileDescription();
//  ProfileDetails.Name = "Manager";
//  ProfileDetails.ID = "75fa0ecb-98aa-11df-b54f-e0cb4ed5f655";
//  ProfileDetails.Description = NStr("en = 'Sales representative'; fa = 'نماینده فروش'", Common.DefaultLanguageCode());
//  ProfileDetails.Roles.Add("StartWebClient");
//  ProfileDetails.Roles.Add("StartThinClient");
//  ProfileDetails.Roles.Add("BasicAccessSSL");
//  ProfileDetails.Roles.Add("Subsystem_Sales");
//  ProfileDetails.Roles.Add("AddEditCustomersDocuments");
//  ProfileDetails.Roles.Add("ViewReportPurchaseLedger");
//  ProfileDetails.Roles.Add(ProfileDetails);
//
//  FolderDetails = AccessManagement.NewAccessGroupsProfilesFolderDetails();
//  FolderDetails.Name = "AdditionalProfiles";
//  FolderDetails.ID = "69a066e7-ce81-11eb-881c-b06ebfbf08c7";
//  FolderDetails.Description = NStr("en = 'Additional profiles'; fa = 'Additional profiles'", Common.DefaultLanguageCode());
//  ProfilesDetails.Add(FolderDetails);
//
//  ProfileDetails = AccessManagement.NewAccessGroupProfileDescription();
//  ProfileDetails.Parent = "AdditionalProfiles";
//  ProfileDetails.ID = "70179f20-2315-11e6-9bff-d850e648b60c";
//  ProfileDetails.Description = NStr("en = 'Editing, sending by email, saving a print form to a file (additionally)'; fa = 'Editing, sending by email, saving a print form to a file (additionally)'",
//  	Common.DefaultLanguageCode());
//  ProfileDetails.Details = NStr("en = It is additionally assigned to those users who must be able to edit
//  	|before printing, sending by email and saving print forms to a file.'");
//  ProfileDetails.Roles.Add("PrintFormsEdit");
//  ProfilesDetails.Add(ProfileDetails);
//
Procedure OnFillSuppliedAccessGroupProfiles(ProfilesDetails, ParametersOfUpdate) Export
	TMAccessManagement.OnFillSuppliedAccessGroupProfiles(ProfilesDetails, ParametersOfUpdate);
	CAAccessManagement.FillInSuppliedAccessGroupProfiles(ProfilesDetails, ParametersOfUpdate);
	AccessManagementERP.FillInSuppliedAccessGroupProfiles(ProfilesDetails, ParametersOfUpdate);
	AccessManagementLocalization.FillInSuppliedAccessGroupProfiles(ProfilesDetails, ParametersOfUpdate);
	//++WE
	AccessManagementPayrollAndHumanResources.FillInSuppliedAccessGroupProfiles(ProfilesDetails, ParametersOfUpdate);
	//--WE
	
EndProcedure

// Fills in non-standard access right dependencies of the subordinate object on the main object. For example, access right dependencies
// of the PerformerTask task on the Job business process.
//
// Access right dependencies are used in the standard access restriction template for Object access kind.
// 1. By default, when reading a subordinate object,
//    the right to read a leading object is checked and
//    if there are no restrictions to read the leading object.
// 2. When adding, changing, or deleting a subordinate object,
//    a right to edit a leading object is checked and
//    whether there are no restrictions to edit the leading object.
//
// Only one reassignment is allowed, compared to the standard dependencies, that is,
// in clause 2, checking the right to change the leading object can be replaced with checking
// the right to read the leading object.
//
// Parameters:
//  RightsDependencies - ValueTable:
//   * LeadingTable     - String - for example, Metadata.BusinessProcesses.Job.FullName().
//   * SubordinateTable - String - for example, Metadata.Tasks.PerformerTask.FullName().
//
Procedure OnFillAccessRightsDependencies(RightsDependencies) Export
	TMAccessManagement.OnFillAccessRightsDependencies(RightsDependencies);
EndProcedure

// Fills in details of available rights assigned to the objects of the specified types.
//
// Parameters:
//  AvailableRights - ValueTable:
//   * RightsOwner - String - a full name of the access value table.
//
//   * Name          - String - a right ID, for example, FoldersChange. The RightsManagement right
//                  must be defined for the "Access rights" common form for setting rights.
//                  RightsManagement is a right to change rights by the owner checked
//                  upon opening CommonForm.ObjectsRightsSettings.
//
//   * Title    - String - Access right title. For example, in the ObjectsRightsSettings form::
//                  "Edit
//                  |folders".
//
//   * ToolTip    - String - a tooltip of the right title.
//                  For example, "Add, change, and mark folders for deletion".
//
//   * InitialValue - Boolean - an initial value of right check box when adding a new row
//                  in the "Access rights" form.
//
//   * RequiredRights1 - Array of String - names of rights required by this right.
//                  For example, the ChangeFiles right is required by the AddFiles right.
//
//   * ReadInTables - Array of String - full names of tables, for which this right means the Read right.
//                  You can use the "*" character that means "for all other tables",
//                  as the Read right depends only on the Read right, only the "*" character makes sense
//                  (it is required for access restriction templates).
//
//   * ChangeInTables - Array of String - full names of tables, for which this right means the Update right.
//                  You can use an asterisk (*), which means "for all other tables"
//                  (it is required for access restriction templates).
//
Procedure OnFillAvailableRightsForObjectsRightsSettings(AvailableRights) Export
	TMAccessManagement.OnFillAvailableRightsForObjectsRightsSettings(AvailableRights);
EndProcedure

// Defines the user interface type used for access setup.
//
// Parameters:
//  SimplifiedInterface - Boolean - the initial value is False.
//
Procedure OnDefineAccessSettingInterface(SimplifiedInterface) Export
	TMAccessManagement.OnDefineAccessSettingInterface(SimplifiedInterface);
EndProcedure

// Fills in the usage of access kinds depending on functional options of the configuration,
// for example, UseProductsAccessGroups.
//
// Parameters:
//  AccessKind    - String - an access kind name specified in the OnFillAccessKinds procedure.
//  Use - Boolean - an initial value is True.
// 
Procedure OnFillAccessKindUsage(AccessKind, Use) Export
	TMAccessManagement.OnFillAccessKindUsage(AccessKind, Use);
	
EndProcedure

// Allows to override the restriction specified in the metadata object manager module.
//
// Parameters:
//  List - MetadataObject - a list, for which restriction text return is required.
//                              Specify False for the list
//                              in the OnFillListsWithAccessRestriction procedure, otherwise, a call will not be made.
//
//  Restriction - Structure:
//    * Text                             - String - access restriction for users.
//                                          If the string is blank, access is granted.
//    * TextForExternalUsers1      - String - access restriction for external users.
//                                          If the string is blank, access denied.
//    * ByOwnerWithoutSavingAccessKeys - Undefined - define automatically.
//                                        - Boolean - if False, always write access keys.
//                                          If True, do not write access keys,
//                                          but use owner access keys (the restriction
//                                          must be by the owner object only).
//   * ByOwnerWithoutSavingAccessKeysForExternalUsers - Undefined, Boolean - the same
//                                          as the ByOwnerWithoutSavingAccessKeys parameter.
//
Procedure OnFillAccessRestriction(List, Restriction) Export
	TMAccessManagement.OnFillAccessRestriction(List, Restriction);
	AccessManagementLocalization.OnFillAccessRestriction(List, Restriction);
	//++ WE
	If Not Common.SubsystemExists("SalaryPersonnelSubsystems") Then
		AccessManagementPayrollAndHumanResources.OnFillAccessRestriction(List, Restriction);
	EndIf;
	//--WE
	
EndProcedure

// Fills in the list of access kinds used to set metadata object right restrictions.
// If the list of access kinds is not filled, the Access rights report displays incorrect data.
//
// Only access kinds explicitly used in access restriction templates must be filled.
// Access kinds used in access value sets can be obtained from the current
// state of the AccessValuesSets information register.
//
//  To generate the procedure code automatically, it is recommended that you use the developer
// tools from the Access management subsystem.
//
// Parameters:
//  LongDesc     - String - a multiline string of the <Table>.<Right>.<AccessKind>[.Object table] format.
//                 For example "Document.PurchaseInvoice.Read.Companies",
//                           "Document.PurchaseInvoice.Read.Counterparties",
//                           "Document.PurchaseInvoice.Change.Companies",
//                           "Document.PurchaseInvoice.Change.Counterparties",
//                           "Document.Emails.Read.Object.Document.Emails",
//                           "Document.Emails.Change.Object.Document.Emails",
//                           "Document.Files.Read.Object.Catalog.FilesFolders",
//                           "Document.Files.Read.Object.Document.Email",
//                           "Document.Files.Change.Object.Catalog.FilesFolders",
//                           "Document.Files.Change.Object.Document.Email".
//                 The Object access kind is predefined as a literal. This access kind is used in
//                 access restriction templates as a reference to another object used for
//                 applying restrictions to the current object of the table.
//                 When the Object access kind is set, set table types
//                 used for this access kind. That means to enumerate types
//                 corresponding to the field used in the access restriction template
//                 together with the "Object" access kind. When listing types by the Object access kind,
//                 list only those field types that
//                 the InformationRegisters.AccessValuesSets.Object field has, other types are excess.
// 
Procedure OnFillMetadataObjectsAccessRestrictionKinds(LongDesc) Export

	AccessManagementLocalization.OnFillMetadataObjectsAccessRestrictionKinds(LongDesc);

	LongDesc = LongDesc + "
	|Catalog.ExpenseReportAttachedFiles.Read.PartnerGroups
	|Catalog.ExpenseReportAttachedFiles.Read.GroupsOfIndividuals
	|Catalog.ExpenseReportAttachedFiles.Read.Companies
	|Catalog.ExpenseReportAttachedFiles.Read.Departments
	|Catalog.ExpenseReportAttachedFiles.Update.PartnerGroups
	|Catalog.ExpenseReportAttachedFiles.Update.GroupsOfIndividuals
	|Catalog.ExpenseReportAttachedFiles.Update.Companies
	|Catalog.ExpenseReportAttachedFiles.Update.Departments
	|Catalog.CustomerInvoiceServicesAttachedFiles.Read.PartnerGroups
	|Catalog.CustomerInvoiceServicesAttachedFiles.Read.Companies
	|Catalog.CustomerInvoiceServicesAttachedFiles.Read.Departments
	|Catalog.CustomerInvoiceServicesAttachedFiles.Update.PartnerGroups
	|Catalog.CustomerInvoiceServicesAttachedFiles.Update.Companies
	|Catalog.CustomerInvoiceServicesAttachedFiles.Update.Departments
	|Catalog.GoodsQualityControlCertificateAttachedFiles.Read.PartnerGroups
	|Catalog.GoodsQualityControlCertificateAttachedFiles.Read.Companies
	|Catalog.GoodsQualityControlCertificateAttachedFiles.Read.Departments
	|Catalog.GoodsQualityControlCertificateAttachedFiles.Read.Warehouses
	|Catalog.GoodsQualityControlCertificateAttachedFiles.Read.BusinessTransactions
	|Catalog.GoodsQualityControlCertificateAttachedFiles.Update.PartnerGroups
	|Catalog.GoodsQualityControlCertificateAttachedFiles.Update.Companies
	|Catalog.GoodsQualityControlCertificateAttachedFiles.Update.Departments
	|Catalog.GoodsQualityControlCertificateAttachedFiles.Update.Warehouses
	|Catalog.GoodsQualityControlCertificateAttachedFiles.Update.BusinessTransactions
	|Catalog.DiscrepancyReportFollowingShipmentAttachedFiles.Read.PartnerGroups
	|Catalog.DiscrepancyReportFollowingShipmentAttachedFiles.Read.Companies
	|Catalog.DiscrepancyReportFollowingShipmentAttachedFiles.Read.TypesOfGroundsForActOfDiscrepancies
	|Catalog.DiscrepancyReportFollowingShipmentAttachedFiles.Update.PartnerGroups
	|Catalog.DiscrepancyReportFollowingShipmentAttachedFiles.Update.Companies
	|Catalog.DiscrepancyReportFollowingShipmentAttachedFiles.Update.TypesOfGroundsForActOfDiscrepancies
	|Catalog.DiscrepancyReportFollowingTransferAttachedFiles.Read.Companies
	|Catalog.DiscrepancyReportFollowingTransferAttachedFiles.Read.Warehouses
	|Catalog.DiscrepancyReportFollowingTransferAttachedFiles.Update.Companies
	|Catalog.DiscrepancyReportFollowingTransferAttachedFiles.Update.Warehouses
	|Catalog.DiscrepancyReportFollowingReceiptAttachedFiles.Read.PartnerGroups
	|Catalog.DiscrepancyReportFollowingReceiptAttachedFiles.Read.Companies
	|Catalog.DiscrepancyReportFollowingReceiptAttachedFiles.Read.TypesOfGroundsForActOfDiscrepancies
	|Catalog.DiscrepancyReportFollowingReceiptAttachedFiles.Update.PartnerGroups
	|Catalog.DiscrepancyReportFollowingReceiptAttachedFiles.Update.Companies
	|Catalog.DiscrepancyReportFollowingReceiptAttachedFiles.Update.TypesOfGroundsForActOfDiscrepancies
	|Catalog.CustomerBonusCertificateAttachedFiles.Read.Companies
	|Catalog.CustomerBonusCertificateAttachedFiles.Update.Companies
	|Catalog.VendorBonusCertificateAttachedFiles.Read.Companies
	|Catalog.VendorBonusCertificateAttachedFiles.Update.Companies
	|Catalog.CounterpartyBankAccounts.Read.ExternalUsers
	|Catalog.CounterpartyBankAccounts.Update.ExternalUsers
	|Catalog.CounterpartyBankAccounts.Update.PartnerGroups
	|Catalog.CounterpartyBankAccounts.Update.GroupsOfIndividuals
	|Catalog.CompaniesBankAccounts.Read.Companies
	|Catalog.ProductKitConfigurations.Update.ProductGroups
	|Catalog.FilesVersions.Read.Object.BusinessProcess.Job
	|Catalog.FilesVersions.Read.Object.Document.RetailReturnsReport
	|Catalog.FilesVersions.Read.Object.Document.RetailSalesReport
	|Catalog.FilesVersions.Read.Object.Catalog.FilesFolders
	|Catalog.FilesVersions.Read.Object.Catalog.Persons
	|Catalog.FilesVersions.Update.Object.BusinessProcess.Job
	|Catalog.FilesVersions.Update.Object.Document.RetailReturnsReport
	|Catalog.FilesVersions.Update.Object.Document.RetailSalesReport
	|Catalog.FilesVersions.Update.Object.Catalog.FilesFolders
	|Catalog.FilesVersions.Update.Object.Catalog.Persons
	|Catalog.ARAPSettlementAttachedFiles.Read.PartnerGroups
	|Catalog.ARAPSettlementAttachedFiles.Read.Companies
	|Catalog.ARAPSettlementAttachedFiles.Update.PartnerGroups
	|Catalog.ARAPSettlementAttachedFiles.Update.Companies
	|Catalog.InventoryKinds.Read.Companies
	|Catalog.ItemKinds.Update.ProductGroups
	|Catalog.ItemKindsAttachedFiles.Update.ProductGroups
	|Catalog.TypesOfPrices.Read.TypesOfPrices
	|Catalog.TypesOfPrices.Update.TypesOfPrices
	|Catalog.VendorPriceTypes.Read.PartnerGroups
	|Catalog.VendorPriceTypes.Update.PartnerGroups
	|Catalog.ExternalUsers.Read.ExternalUsers
	|Catalog.ExternalUsers.Update.ExternalUsers
	|Catalog.InventoryConsumptionAttachedFiles.Read.Companies
	|Catalog.InventoryConsumptionAttachedFiles.Read.Departments
	|Catalog.InventoryConsumptionAttachedFiles.Read.Warehouses
	|Catalog.InventoryConsumptionAttachedFiles.Update.Companies
	|Catalog.InventoryConsumptionAttachedFiles.Update.Departments
	|Catalog.InventoryConsumptionAttachedFiles.Update.Warehouses
	|Catalog.IntercompanyGoodsReturnAttachedFiles.Read.PartnerGroups
	|Catalog.IntercompanyGoodsReturnAttachedFiles.Read.Companies
	|Catalog.IntercompanyGoodsReturnAttachedFiles.Read.Departments
	|Catalog.IntercompanyGoodsReturnAttachedFiles.Read.Warehouses
	|Catalog.IntercompanyGoodsReturnAttachedFiles.Update.PartnerGroups
	|Catalog.IntercompanyGoodsReturnAttachedFiles.Update.Companies
	|Catalog.IntercompanyGoodsReturnAttachedFiles.Update.Departments
	|Catalog.IntercompanyGoodsReturnAttachedFiles.Update.Warehouses
	|Catalog.ReturnOfGoodsFromCustomerAttachedFiles.Read.PartnerGroups
	|Catalog.ReturnOfGoodsFromCustomerAttachedFiles.Read.Companies
	|Catalog.ReturnOfGoodsFromCustomerAttachedFiles.Read.Departments
	|Catalog.ReturnOfGoodsFromCustomerAttachedFiles.Read.Warehouses
	|Catalog.ReturnOfGoodsFromCustomerAttachedFiles.Update.PartnerGroups
	|Catalog.ReturnOfGoodsFromCustomerAttachedFiles.Update.Companies
	|Catalog.ReturnOfGoodsFromCustomerAttachedFiles.Update.Departments
	|Catalog.ReturnOfGoodsFromCustomerAttachedFiles.Update.Warehouses
	|Catalog.ReturnOfGoodsToVendorAttachedFiles.Read.PartnerGroups
	|Catalog.ReturnOfGoodsToVendorAttachedFiles.Read.Companies
	|Catalog.ReturnOfGoodsToVendorAttachedFiles.Read.Departments
	|Catalog.ReturnOfGoodsToVendorAttachedFiles.Read.Warehouses
	|Catalog.ReturnOfGoodsToVendorAttachedFiles.Update.PartnerGroups
	|Catalog.ReturnOfGoodsToVendorAttachedFiles.Update.Companies
	|Catalog.ReturnOfGoodsToVendorAttachedFiles.Update.Departments
	|Catalog.ReturnOfGoodsToVendorAttachedFiles.Update.Warehouses
	|Catalog.MeetingAttachedFiles.Read.Object.Document.Meeting
	|Catalog.MeetingAttachedFiles.Update.Object.Document.Meeting
	|Catalog.ReturnablePackagingRedemptionByCustomerAttachedFiles.Read.Companies
	|Catalog.ReturnablePackagingRedemptionByCustomerAttachedFiles.Update.Companies
	|Catalog.RedemptionOfReturnablePackagingFromVendorAttachedFiles.Read.Companies
	|Catalog.RedemptionOfReturnablePackagingFromVendorAttachedFiles.Update.Companies
	|Catalog.RedemptionOfGoodsFromStorageAttachedFiles.Read.PartnerGroups
	|Catalog.RedemptionOfGoodsFromStorageAttachedFiles.Read.Companies
	|Catalog.RedemptionOfGoodsFromStorageAttachedFiles.Read.Departments
	|Catalog.RedemptionOfGoodsFromStorageAttachedFiles.Read.BusinessTransactions
	|Catalog.RedemptionOfGoodsFromStorageAttachedFiles.Update.PartnerGroups
	|Catalog.RedemptionOfGoodsFromStorageAttachedFiles.Update.Companies
	|Catalog.RedemptionOfGoodsFromStorageAttachedFiles.Update.Departments
	|Catalog.RedemptionOfGoodsFromStorageAttachedFiles.Update.BusinessTransactions
	|Catalog.RedemptionOfGoodsByCustodianAttachedFiles.Read.PartnerGroups
	|Catalog.RedemptionOfGoodsByCustodianAttachedFiles.Read.Companies
	|Catalog.RedemptionOfGoodsByCustodianAttachedFiles.Read.Departments
	|Catalog.RedemptionOfGoodsByCustodianAttachedFiles.Read.BusinessTransactions
	|Catalog.RedemptionOfGoodsByCustodianAttachedFiles.Update.PartnerGroups
	|Catalog.RedemptionOfGoodsByCustodianAttachedFiles.Update.Companies
	|Catalog.RedemptionOfGoodsByCustodianAttachedFiles.Update.Departments
	|Catalog.RedemptionOfGoodsByCustodianAttachedFiles.Update.BusinessTransactions
	|Catalog.ExternalUsersGroups.Read.ExternalUsers
	|Catalog.PartnerAccessGroups.Read.PartnerGroups
	|Catalog.UserGroups.Read.Users
	|Catalog.CounterpartyContracts.Read.ExternalUsers
	|Catalog.CounterpartyContracts.Read.PartnerGroups
	|Catalog.CounterpartyContracts.Read.Companies
	|Catalog.CounterpartyContracts.Read.Departments
	|Catalog.CounterpartyContracts.Read.BusinessTransactions
	|Catalog.CounterpartyContracts.Update.PartnerGroups
	|Catalog.CounterpartyContracts.Update.Companies
	|Catalog.CounterpartyContracts.Update.Departments
	|Catalog.CounterpartyContracts.Update.BusinessTransactions
	|Catalog.CounterpartyContractsAttachedFiles.Read.PartnerGroups
	|Catalog.CounterpartyContractsAttachedFiles.Read.Companies
	|Catalog.CounterpartyContractsAttachedFiles.Read.BusinessTransactions
	|Catalog.CounterpartyContractsAttachedFiles.Update.PartnerGroups
	|Catalog.CounterpartyContractsAttachedFiles.Update.Companies
	|Catalog.CounterpartyContractsAttachedFiles.Update.BusinessTransactions
	|Catalog.LoanAndDepositContracts.Read.PartnerGroups
	|Catalog.LoanAndDepositContracts.Read.Companies
	|Catalog.LoanAndDepositContracts.Update.PartnerGroups
	|Catalog.LoanAndDepositContracts.Update.Companies
	|Catalog.LoanAndDepositContractsAttachedFiles.Read.PartnerGroups
	|Catalog.LoanAndDepositContractsAttachedFiles.Read.Companies
	|Catalog.LoanAndDepositContractsAttachedFiles.Update.PartnerGroups
	|Catalog.LoanAndDepositContractsAttachedFiles.Update.Companies
	|Catalog.IntercompanyContracts.Read.Companies
	|Catalog.IntercompanyContractsAttachedFiles.Read.Companies
	|Catalog.AcquiringContracts.Read.PartnerGroups
	|Catalog.AcquiringContracts.Read.Companies
	|Catalog.AcquiringContracts.Update.PartnerGroups
	|Catalog.AcquiringContracts.Update.Companies
	|Catalog.AcquiringContractsAttachedFiles.Read.PartnerGroups
	|Catalog.AcquiringContractsAttachedFiles.Read.Companies
	|Catalog.AcquiringContractsAttachedFiles.Update.PartnerGroups
	|Catalog.AcquiringContractsAttachedFiles.Update.Companies
	|Catalog.AdditionalReportsAndDataProcessors.Read.AdditionalReportsAndDataProcessors
	|Catalog.TransportationJobAttachedFiles.Read.Warehouses
	|Catalog.TransportationJobAttachedFiles.Update.Warehouses
	|Catalog.JobForSalesRepresentativeAttachedFiles.Read.PartnerGroups
	|Catalog.JobForSalesRepresentativeAttachedFiles.Read.Companies
	|Catalog.JobForSalesRepresentativeAttachedFiles.Read.Warehouses
	|Catalog.JobForSalesRepresentativeAttachedFiles.Update.PartnerGroups
	|Catalog.JobForSalesRepresentativeAttachedFiles.Update.Companies
	|Catalog.JobForSalesRepresentativeAttachedFiles.Update.Warehouses
	|Catalog.ProjectTasks.Read.PartnerGroups
	|Catalog.ProjectTasks.Read.Object.Catalog.MarketingActivities
	|Catalog.ProjectTasks.Read.Object.Catalog.Complaints
	|Catalog.ProjectTasks.Read.Object.Catalog.Projects
	|Catalog.ProjectTasks.Read.Object.Catalog.SalesOpportunitiesToCustomer
	|Catalog.ProjectTasks.Update.PartnerGroups
	|Catalog.ProjectTasks.Update.Object.Catalog.MarketingActivities
	|Catalog.ProjectTasks.Update.Object.Catalog.Complaints
	|Catalog.ProjectTasks.Update.Object.Catalog.Projects
	|Catalog.ProjectTasks.Update.Object.Catalog.SalesOpportunitiesToCustomer
	|Catalog.SalesOrderAttachedFiles.Read.PartnerGroups
	|Catalog.SalesOrderAttachedFiles.Read.Companies
	|Catalog.SalesOrderAttachedFiles.Read.Departments
	|Catalog.SalesOrderAttachedFiles.Read.Warehouses
	|Catalog.SalesOrderAttachedFiles.Update.PartnerGroups
	|Catalog.SalesOrderAttachedFiles.Update.Companies
	|Catalog.SalesOrderAttachedFiles.Update.Departments
	|Catalog.SalesOrderAttachedFiles.Update.Warehouses
	|Catalog.InventoryConsumptionOrderAttachedFiles.Read.Companies
	|Catalog.InventoryConsumptionOrderAttachedFiles.Read.Departments
	|Catalog.InventoryConsumptionOrderAttachedFiles.Read.Warehouses
	|Catalog.InventoryConsumptionOrderAttachedFiles.Update.Companies
	|Catalog.InventoryConsumptionOrderAttachedFiles.Update.Departments
	|Catalog.InventoryConsumptionOrderAttachedFiles.Update.Warehouses
	|Catalog.DeliveryOrderAttachedFiles.Read.Companies
	|Catalog.DeliveryOrderAttachedFiles.Update.Companies
	|Catalog.ByAssemblyDisassemblyOrderAttachedFiles.Read.Companies
	|Catalog.ByAssemblyDisassemblyOrderAttachedFiles.Read.Warehouses
	|Catalog.ByAssemblyDisassemblyOrderAttachedFiles.Update.Companies
	|Catalog.ByAssemblyDisassemblyOrderAttachedFiles.Update.Warehouses
	|Catalog.PurchaseOrderAttachedFiles.Read.PartnerGroups
	|Catalog.PurchaseOrderAttachedFiles.Read.Companies
	|Catalog.PurchaseOrderAttachedFiles.Read.Departments
	|Catalog.PurchaseOrderAttachedFiles.Read.Warehouses
	|Catalog.PurchaseOrderAttachedFiles.Update.PartnerGroups
	|Catalog.PurchaseOrderAttachedFiles.Update.Companies
	|Catalog.PurchaseOrderAttachedFiles.Update.Departments
	|Catalog.PurchaseOrderAttachedFiles.Update.Warehouses
	|Catalog.PlannedInteractionAttachedFiles.Read.Object.Document.PlannedInteraction
	|Catalog.PlannedInteractionAttachedFiles.Update.Object.Document.PlannedInteraction
	|Catalog.RequestForReturnOfGoodsFromCustomerAttachedFiles.Read.PartnerGroups
	|Catalog.RequestForReturnOfGoodsFromCustomerAttachedFiles.Read.Companies
	|Catalog.RequestForReturnOfGoodsFromCustomerAttachedFiles.Read.Warehouses
	|Catalog.RequestForReturnOfGoodsFromCustomerAttachedFiles.Update.PartnerGroups
	|Catalog.RequestForReturnOfGoodsFromCustomerAttachedFiles.Update.Companies
	|Catalog.RequestForReturnOfGoodsFromCustomerAttachedFiles.Update.Warehouses
	|Catalog.PurchaseRequestAttachedFiles.Read.Companies
	|Catalog.PurchaseRequestAttachedFiles.Read.Departments
	|Catalog.PurchaseRequestAttachedFiles.Read.Warehouses
	|Catalog.PurchaseRequestAttachedFiles.Update.Companies
	|Catalog.PurchaseRequestAttachedFiles.Update.Departments
	|Catalog.PurchaseRequestAttachedFiles.Update.Warehouses
	|Catalog.RequestForGoodsQualityControlAttachedFiles.Read.Companies
	|Catalog.RequestForGoodsQualityControlAttachedFiles.Read.Departments
	|Catalog.RequestForGoodsQualityControlAttachedFiles.Read.Warehouses
	|Catalog.RequestForGoodsQualityControlAttachedFiles.Update.Companies
	|Catalog.RequestForGoodsQualityControlAttachedFiles.Update.Departments
	|Catalog.RequestForGoodsQualityControlAttachedFiles.Update.Warehouses
	|Catalog.ApplicationForCollateralAttachedFiles.Read.Companies
	|Catalog.ApplicationForCollateralAttachedFiles.Read.Departments
	|Catalog.ApplicationForCollateralAttachedFiles.Read.Warehouses
	|Catalog.ApplicationForCollateralAttachedFiles.Update.Companies
	|Catalog.ApplicationForCollateralAttachedFiles.Update.Departments
	|Catalog.ApplicationForCollateralAttachedFiles.Update.Warehouses
	|Catalog.PaymentRequestAttachedFiles.Read.PartnerGroups
	|Catalog.PaymentRequestAttachedFiles.Read.GroupsOfIndividuals
	|Catalog.PaymentRequestAttachedFiles.Read.Companies
	|Catalog.PaymentRequestAttachedFiles.Read.Departments
	|Catalog.PaymentRequestAttachedFiles.Read.Users
	|Catalog.PaymentRequestAttachedFiles.Read.BusinessTransactions
	|Catalog.PaymentRequestAttachedFiles.Update.PartnerGroups
	|Catalog.PaymentRequestAttachedFiles.Update.GroupsOfIndividuals
	|Catalog.PaymentRequestAttachedFiles.Update.Companies
	|Catalog.PaymentRequestAttachedFiles.Update.Departments
	|Catalog.PaymentRequestAttachedFiles.Update.Users
	|Catalog.PaymentRequestAttachedFiles.Update.BusinessTransactions
	|Catalog.ObjectsPropertiesValues.Read.AdditionalInfo
	|Catalog.ObjectPropertyValueHierarchy.Read.AdditionalInfo
	|Catalog.CashAccounts.Read.CashAccounts
	|Catalog.CashAccounts.Read.Companies
	|Catalog.CashRegisters.Read.CashRegisters
	|Catalog.CashRegisters.Read.Companies
	|Catalog.CommercialProposalForCustomerAttachedFiles.Read.PartnerGroups
	|Catalog.CommercialProposalForCustomerAttachedFiles.Read.Companies
	|Catalog.CommercialProposalForCustomerAttachedFiles.Update.PartnerGroups
	|Catalog.CommercialProposalForCustomerAttachedFiles.Update.Companies
	|Catalog.ContactPersonsForPartners.Read.ExternalUsers
	|Catalog.ContactPersonsForPartners.Read.PartnerGroups
	|Catalog.ContactPersonsForPartners.Update.ExternalUsers
	|Catalog.ContactPersonsForPartners.Update.PartnerGroups
	|Catalog.Counterparties.Read.ExternalUsers
	|Catalog.Counterparties.Read.PartnerGroups
	|Catalog.Counterparties.Update.ExternalUsers
	|Catalog.Counterparties.Update.PartnerGroups
	|Catalog.ARAPAccountingScheduleAdjustmentAttachedFiles.Read.PartnerGroups
	|Catalog.ARAPAccountingScheduleAdjustmentAttachedFiles.Read.Companies
	|Catalog.ARAPAccountingScheduleAdjustmentAttachedFiles.Update.PartnerGroups
	|Catalog.ARAPAccountingScheduleAdjustmentAttachedFiles.Update.Companies
	|Catalog.ARAPAdjustmentAttachedFiles.Read.PartnerGroups
	|Catalog.ARAPAdjustmentAttachedFiles.Read.Companies
	|Catalog.ARAPAdjustmentAttachedFiles.Update.PartnerGroups
	|Catalog.ARAPAdjustmentAttachedFiles.Update.Companies
	|Catalog.AdjustmentOfPlannedDemandAttachedFiles.Read.PlanProfiles
	|Catalog.AdjustmentOfPlannedDemandAttachedFiles.Read.SalesOperationsPlanningScenarios
	|Catalog.AdjustmentOfPlannedDemandAttachedFiles.Update.PlanProfiles
	|Catalog.AdjustmentOfPlannedDemandAttachedFiles.Update.SalesOperationsPlanningScenarios
	|Catalog.PurchaseAdjustmentAttachedFiles.Read.PartnerGroups
	|Catalog.PurchaseAdjustmentAttachedFiles.Read.Companies
	|Catalog.PurchaseAdjustmentAttachedFiles.Read.Departments
	|Catalog.PurchaseAdjustmentAttachedFiles.Read.Warehouses
	|Catalog.PurchaseAdjustmentAttachedFiles.Update.PartnerGroups
	|Catalog.PurchaseAdjustmentAttachedFiles.Update.Companies
	|Catalog.PurchaseAdjustmentAttachedFiles.Update.Departments
	|Catalog.PurchaseAdjustmentAttachedFiles.Update.Warehouses
	|Catalog.AdjustmentOfARAPAccountingForAdvanceHoldersAttachedFiles.Read.GroupsOfIndividuals
	|Catalog.AdjustmentOfARAPAccountingForAdvanceHoldersAttachedFiles.Read.Companies
	|Catalog.AdjustmentOfARAPAccountingForAdvanceHoldersAttachedFiles.Read.Departments
	|Catalog.AdjustmentOfARAPAccountingForAdvanceHoldersAttachedFiles.Update.GroupsOfIndividuals
	|Catalog.AdjustmentOfARAPAccountingForAdvanceHoldersAttachedFiles.Update.Companies
	|Catalog.AdjustmentOfARAPAccountingForAdvanceHoldersAttachedFiles.Update.Departments
	|Catalog.SaleAdjustmentAttachedFiles.Read.PartnerGroups
	|Catalog.SaleAdjustmentAttachedFiles.Read.Companies
	|Catalog.SaleAdjustmentAttachedFiles.Read.Departments
	|Catalog.SaleAdjustmentAttachedFiles.Read.Warehouses
	|Catalog.SaleAdjustmentAttachedFiles.Update.PartnerGroups
	|Catalog.SaleAdjustmentAttachedFiles.Update.Companies
	|Catalog.SaleAdjustmentAttachedFiles.Update.Departments
	|Catalog.SaleAdjustmentAttachedFiles.Update.Warehouses
	|Catalog.AdditionalAttributesAndInfoSets.Update.ProductGroups
	|Catalog.ReverseVATAccrualAttachedFiles.Read.Companies
	|Catalog.ReverseVATAccrualAttachedFiles.Update.Companies
	|Catalog.AccrualOfCustomerRebatesAttachedFiles.Read.Companies
	|Catalog.AccrualOfCustomerRebatesAttachedFiles.Update.Companies
	|Catalog.AccrualOfVendorRebatesAttachedFiles.Read.Companies
	|Catalog.AccrualOfVendorRebatesAttachedFiles.Update.Companies
	|Catalog.Products.Update.ProductGroups
	|Catalog.ProductCrossReferences.Read.PartnerGroups
	|Catalog.ProductCrossReferences.Update.PartnerGroups
	|Catalog.ProductCrossReferencesAttachedFiles.Read.PartnerGroups
	|Catalog.ProductCrossReferencesAttachedFiles.Update.PartnerGroups
	|Catalog.ProductsAttachedFiles.Update.ProductGroups
	|Catalog.StorageAreas.Read.Warehouses
	|Catalog.StorageAreas.Update.Warehouses
	|Catalog.PlannedCashReceiptAttachedFiles.Read.CashAccounts
	|Catalog.PlannedCashReceiptAttachedFiles.Read.Companies
	|Catalog.PlannedCashReceiptAttachedFiles.Update.CashAccounts
	|Catalog.PlannedCashReceiptAttachedFiles.Update.Companies
	|Catalog.RecognitionOfStockSurplusShippedToCustomerAttachedFiles.Read.PartnerGroups
	|Catalog.RecognitionOfStockSurplusShippedToCustomerAttachedFiles.Read.Companies
	|Catalog.RecognitionOfStockSurplusShippedToCustomerAttachedFiles.Read.Departments
	|Catalog.RecognitionOfStockSurplusShippedToCustomerAttachedFiles.Read.BusinessTransactions
	|Catalog.RecognitionOfStockSurplusShippedToCustomerAttachedFiles.Update.PartnerGroups
	|Catalog.RecognitionOfStockSurplusShippedToCustomerAttachedFiles.Update.Companies
	|Catalog.RecognitionOfStockSurplusShippedToCustomerAttachedFiles.Update.Departments
	|Catalog.RecognitionOfStockSurplusShippedToCustomerAttachedFiles.Update.BusinessTransactions
	|Catalog.Companies.Read.Companies
	|Catalog.CompaniesAttachedFiles.Read.Companies
	|Catalog.PersonsResponsibleAndCompanies.Read.Companies
	|Catalog.GoodsShipmentToCustomerAttachedFiles.Read.PartnerGroups
	|Catalog.GoodsShipmentToCustomerAttachedFiles.Read.Companies
	|Catalog.GoodsShipmentToCustomerAttachedFiles.Read.Departments
	|Catalog.GoodsShipmentToCustomerAttachedFiles.Read.Warehouses
	|Catalog.GoodsShipmentToCustomerAttachedFiles.Read.BusinessTransactions
	|Catalog.GoodsShipmentToCustomerAttachedFiles.Update.PartnerGroups
	|Catalog.GoodsShipmentToCustomerAttachedFiles.Update.Companies
	|Catalog.GoodsShipmentToCustomerAttachedFiles.Update.Departments
	|Catalog.GoodsShipmentToCustomerAttachedFiles.Update.Warehouses
	|Catalog.GoodsShipmentToCustomerAttachedFiles.Update.BusinessTransactions
	|Catalog.GoodsShipmentFromStorageAttachedFiles.Read.PartnerGroups
	|Catalog.GoodsShipmentFromStorageAttachedFiles.Read.Companies
	|Catalog.GoodsShipmentFromStorageAttachedFiles.Read.Departments
	|Catalog.GoodsShipmentFromStorageAttachedFiles.Read.Warehouses
	|Catalog.GoodsShipmentFromStorageAttachedFiles.Read.BusinessTransactions
	|Catalog.GoodsShipmentFromStorageAttachedFiles.Update.PartnerGroups
	|Catalog.GoodsShipmentFromStorageAttachedFiles.Update.Companies
	|Catalog.GoodsShipmentFromStorageAttachedFiles.Update.Departments
	|Catalog.GoodsShipmentFromStorageAttachedFiles.Update.Warehouses
	|Catalog.GoodsShipmentFromStorageAttachedFiles.Update.BusinessTransactions
	|Catalog.WriteOffReportFromCommissionAgentAttachedFiles.Read.PartnerGroups
	|Catalog.WriteOffReportFromCommissionAgentAttachedFiles.Read.Companies
	|Catalog.WriteOffReportFromCommissionAgentAttachedFiles.Read.Departments
	|Catalog.WriteOffReportFromCommissionAgentAttachedFiles.Update.PartnerGroups
	|Catalog.WriteOffReportFromCommissionAgentAttachedFiles.Update.Companies
	|Catalog.WriteOffReportFromCommissionAgentAttachedFiles.Update.Departments
	|Catalog.ConsignmentReportFromCustomerAttachedFiles.Read.PartnerGroups
	|Catalog.ConsignmentReportFromCustomerAttachedFiles.Read.Companies
	|Catalog.ConsignmentReportFromCustomerAttachedFiles.Read.Departments
	|Catalog.ConsignmentReportFromCustomerAttachedFiles.Update.PartnerGroups
	|Catalog.ConsignmentReportFromCustomerAttachedFiles.Update.Companies
	|Catalog.ConsignmentReportFromCustomerAttachedFiles.Update.Departments
	|Catalog.PurchasingReportToConsignorPrincipalAttachedFiles.Read.PartnerGroups
	|Catalog.PurchasingReportToConsignorPrincipalAttachedFiles.Read.Companies
	|Catalog.PurchasingReportToConsignorPrincipalAttachedFiles.Read.Departments
	|Catalog.PurchasingReportToConsignorPrincipalAttachedFiles.Update.PartnerGroups
	|Catalog.PurchasingReportToConsignorPrincipalAttachedFiles.Update.Companies
	|Catalog.PurchasingReportToConsignorPrincipalAttachedFiles.Update.Departments
	|Catalog.PurchaseInvoiceConsignmentStockLostAttachedFiles.Read.PartnerGroups
	|Catalog.PurchaseInvoiceConsignmentStockLostAttachedFiles.Read.Companies
	|Catalog.PurchaseInvoiceConsignmentStockLostAttachedFiles.Read.Departments
	|Catalog.PurchaseInvoiceConsignmentStockLostAttachedFiles.Update.PartnerGroups
	|Catalog.PurchaseInvoiceConsignmentStockLostAttachedFiles.Update.Companies
	|Catalog.PurchaseInvoiceConsignmentStockLostAttachedFiles.Update.Departments
	|Catalog.ConsignmentReportToVendorAttachedFiles.Read.PartnerGroups
	|Catalog.ConsignmentReportToVendorAttachedFiles.Read.Companies
	|Catalog.ConsignmentReportToVendorAttachedFiles.Read.Departments
	|Catalog.ConsignmentReportToVendorAttachedFiles.Update.PartnerGroups
	|Catalog.ConsignmentReportToVendorAttachedFiles.Update.Companies
	|Catalog.ConsignmentReportToVendorAttachedFiles.Update.Departments
	|Catalog.ReportOnVMIAdjustmentAttachedFiles.Read.PartnerGroups
	|Catalog.ReportOnVMIAdjustmentAttachedFiles.Read.Companies
	|Catalog.ReportOnVMIAdjustmentAttachedFiles.Read.Departments
	|Catalog.ReportOnVMIAdjustmentAttachedFiles.Read.BusinessTransactions
	|Catalog.ReportOnVMIAdjustmentAttachedFiles.Update.PartnerGroups
	|Catalog.ReportOnVMIAdjustmentAttachedFiles.Update.Companies
	|Catalog.ReportOnVMIAdjustmentAttachedFiles.Update.Departments
	|Catalog.ReportOnVMIAdjustmentAttachedFiles.Update.BusinessTransactions
	|Catalog.FilesFolders.Read.RightsSettings.Catalog.FilesFolders
	|Catalog.FilesFolders.Update.RightsSettings.Catalog.FilesFolders
	|Catalog.EmailMessageFolders.Read.Users
	|Catalog.EmailMessageFolders.Read.EmailAccounts
	|Catalog.EmailMessageFolders.Update.Users
	|Catalog.EmailMessageFolders.Update.EmailAccounts
	|Catalog.Partners.Read.ExternalUsers
	|Catalog.Partners.Read.PartnerGroups
	|Catalog.Partners.Update.PartnerGroups
	|Catalog.PartnersAttachedFiles.Read.PartnerGroups
	|Catalog.PartnersAttachedFiles.Update.PartnerGroups
	|Catalog.CustomerInvoiceIntercompanyAttachedFiles.Read.PartnerGroups
	|Catalog.CustomerInvoiceIntercompanyAttachedFiles.Read.Companies
	|Catalog.CustomerInvoiceIntercompanyAttachedFiles.Read.Departments
	|Catalog.CustomerInvoiceIntercompanyAttachedFiles.Read.Warehouses
	|Catalog.CustomerInvoiceIntercompanyAttachedFiles.Update.PartnerGroups
	|Catalog.CustomerInvoiceIntercompanyAttachedFiles.Update.Companies
	|Catalog.CustomerInvoiceIntercompanyAttachedFiles.Update.Departments
	|Catalog.CustomerInvoiceIntercompanyAttachedFiles.Update.Warehouses
	|Catalog.TransferOfGoodsToBaileeAttachedFiles.Read.PartnerGroups
	|Catalog.TransferOfGoodsToBaileeAttachedFiles.Read.Companies
	|Catalog.TransferOfGoodsToBaileeAttachedFiles.Read.Departments
	|Catalog.TransferOfGoodsToBaileeAttachedFiles.Read.Warehouses
	|Catalog.TransferOfGoodsToBaileeAttachedFiles.Read.BusinessTransactions
	|Catalog.TransferOfGoodsToBaileeAttachedFiles.Update.PartnerGroups
	|Catalog.TransferOfGoodsToBaileeAttachedFiles.Update.Companies
	|Catalog.TransferOfGoodsToBaileeAttachedFiles.Update.Departments
	|Catalog.TransferOfGoodsToBaileeAttachedFiles.Update.Warehouses
	|Catalog.TransferOfGoodsToBaileeAttachedFiles.Update.BusinessTransactions
	|Catalog.InventoryTransferAttachedFiles.Read.Companies
	|Catalog.InventoryTransferAttachedFiles.Read.Warehouses
	|Catalog.InventoryTransferAttachedFiles.Update.Companies
	|Catalog.InventoryTransferAttachedFiles.Update.Warehouses
	|Catalog.MisgradingOfGoodsAtCustodianAttachedFiles.Read.PartnerGroups
	|Catalog.MisgradingOfGoodsAtCustodianAttachedFiles.Read.Companies
	|Catalog.MisgradingOfGoodsAtCustodianAttachedFiles.Read.Departments
	|Catalog.MisgradingOfGoodsAtCustodianAttachedFiles.Read.BusinessTransactions
	|Catalog.MisgradingOfGoodsAtCustodianAttachedFiles.Update.PartnerGroups
	|Catalog.MisgradingOfGoodsAtCustodianAttachedFiles.Update.Companies
	|Catalog.MisgradingOfGoodsAtCustodianAttachedFiles.Update.Departments
	|Catalog.MisgradingOfGoodsAtCustodianAttachedFiles.Update.BusinessTransactions
	|Catalog.InventoryConsumptionPlanAttachedFiles.Read.PlanProfiles
	|Catalog.InventoryConsumptionPlanAttachedFiles.Read.Departments
	|Catalog.InventoryConsumptionPlanAttachedFiles.Read.Warehouses
	|Catalog.InventoryConsumptionPlanAttachedFiles.Read.SalesOperationsPlanningScenarios
	|Catalog.InventoryConsumptionPlanAttachedFiles.Update.PlanProfiles
	|Catalog.InventoryConsumptionPlanAttachedFiles.Update.Departments
	|Catalog.InventoryConsumptionPlanAttachedFiles.Update.Warehouses
	|Catalog.InventoryConsumptionPlanAttachedFiles.Update.SalesOperationsPlanningScenarios
	|Catalog.PurchasePlanAttachedFiles.Read.PlanProfiles
	|Catalog.PurchasePlanAttachedFiles.Read.PartnerGroups
	|Catalog.PurchasePlanAttachedFiles.Read.Departments
	|Catalog.PurchasePlanAttachedFiles.Read.Warehouses
	|Catalog.PurchasePlanAttachedFiles.Read.SalesOperationsPlanningScenarios
	|Catalog.PurchasePlanAttachedFiles.Update.PlanProfiles
	|Catalog.PurchasePlanAttachedFiles.Update.PartnerGroups
	|Catalog.PurchasePlanAttachedFiles.Update.Departments
	|Catalog.PurchasePlanAttachedFiles.Update.Warehouses
	|Catalog.PurchasePlanAttachedFiles.Update.SalesOperationsPlanningScenarios
	|Catalog.PlanOfGoodsStockAttachedFiles.Read.PlanProfiles
	|Catalog.PlanOfGoodsStockAttachedFiles.Read.Warehouses
	|Catalog.PlanOfGoodsStockAttachedFiles.Read.SalesOperationsPlanningScenarios
	|Catalog.PlanOfGoodsStockAttachedFiles.Update.PlanProfiles
	|Catalog.PlanOfGoodsStockAttachedFiles.Update.Warehouses
	|Catalog.PlanOfGoodsStockAttachedFiles.Update.SalesOperationsPlanningScenarios
	|Catalog.SalesPlanByCategoriesAttachedFiles.Read.PlanProfiles
	|Catalog.SalesPlanByCategoriesAttachedFiles.Read.Departments
	|Catalog.SalesPlanByCategoriesAttachedFiles.Read.Warehouses
	|Catalog.SalesPlanByCategoriesAttachedFiles.Read.SalesOperationsPlanningScenarios
	|Catalog.SalesPlanByCategoriesAttachedFiles.Update.PlanProfiles
	|Catalog.SalesPlanByCategoriesAttachedFiles.Update.Departments
	|Catalog.SalesPlanByCategoriesAttachedFiles.Update.Warehouses
	|Catalog.SalesPlanByCategoriesAttachedFiles.Update.SalesOperationsPlanningScenarios
	|Catalog.SalesPlanAttachedFiles.Read.PlanProfiles
	|Catalog.SalesPlanAttachedFiles.Read.PartnerGroups
	|Catalog.SalesPlanAttachedFiles.Read.Departments
	|Catalog.SalesPlanAttachedFiles.Read.Warehouses
	|Catalog.SalesPlanAttachedFiles.Read.SalesOperationsPlanningScenarios
	|Catalog.SalesPlanAttachedFiles.Update.PlanProfiles
	|Catalog.SalesPlanAttachedFiles.Update.PartnerGroups
	|Catalog.SalesPlanAttachedFiles.Update.Departments
	|Catalog.SalesPlanAttachedFiles.Update.Warehouses
	|Catalog.SalesPlanAttachedFiles.Update.SalesOperationsPlanningScenarios
	|Catalog.AssemblyDisassemblyPlanAttachedFiles.Read.PlanProfiles
	|Catalog.AssemblyDisassemblyPlanAttachedFiles.Read.Warehouses
	|Catalog.AssemblyDisassemblyPlanAttachedFiles.Read.SalesOperationsPlanningScenarios
	|Catalog.AssemblyDisassemblyPlanAttachedFiles.Update.PlanProfiles
	|Catalog.AssemblyDisassemblyPlanAttachedFiles.Update.Warehouses
	|Catalog.AssemblyDisassemblyPlanAttachedFiles.Update.SalesOperationsPlanningScenarios
	|Catalog.SubscriptionsToCustomerMailoutsAndNotifications.Read.ExternalUsers
	|Catalog.SubscriptionsToCustomerMailoutsAndNotifications.Read.PartnerGroups
	|Catalog.SubscriptionsToCustomerMailoutsAndNotifications.Update.ExternalUsers
	|Catalog.SubscriptionsToCustomerMailoutsAndNotifications.Update.PartnerGroups
	|Catalog.BankConfirmationAboutCashReceiptOnEmployeeAccountAttachedFiles.Read.GroupsOfIndividuals
	|Catalog.BankConfirmationAboutCashReceiptOnEmployeeAccountAttachedFiles.Read.Companies
	|Catalog.BankConfirmationAboutCashReceiptOnEmployeeAccountAttachedFiles.Update.GroupsOfIndividuals
	|Catalog.BankConfirmationAboutCashReceiptOnEmployeeAccountAttachedFiles.Update.Companies
	|Catalog.Users.Read.Users
	|Catalog.Users.Update.Users
	|Catalog.DamageAtCustodianAttachedFiles.Read.PartnerGroups
	|Catalog.DamageAtCustodianAttachedFiles.Read.Companies
	|Catalog.DamageAtCustodianAttachedFiles.Read.Departments
	|Catalog.DamageAtCustodianAttachedFiles.Read.BusinessTransactions
	|Catalog.DamageAtCustodianAttachedFiles.Update.PartnerGroups
	|Catalog.DamageAtCustodianAttachedFiles.Update.Companies
	|Catalog.DamageAtCustodianAttachedFiles.Update.Departments
	|Catalog.DamageAtCustodianAttachedFiles.Update.BusinessTransactions
	|Catalog.BankAccountReceiptNoteAttachedFiles.Read.PartnerGroups
	|Catalog.BankAccountReceiptNoteAttachedFiles.Read.Companies
	|Catalog.BankAccountReceiptNoteAttachedFiles.Read.BusinessTransactions
	|Catalog.BankAccountReceiptNoteAttachedFiles.Update.PartnerGroups
	|Catalog.BankAccountReceiptNoteAttachedFiles.Update.Companies
	|Catalog.BankAccountReceiptNoteAttachedFiles.Update.BusinessTransactions
	|Catalog.ReceiptOfGoodsToWarehouseAttachedFiles.Read.PartnerGroups
	|Catalog.ReceiptOfGoodsToWarehouseAttachedFiles.Read.Companies
	|Catalog.ReceiptOfGoodsToWarehouseAttachedFiles.Read.Departments
	|Catalog.ReceiptOfGoodsToWarehouseAttachedFiles.Read.Warehouses
	|Catalog.ReceiptOfGoodsToWarehouseAttachedFiles.Update.PartnerGroups
	|Catalog.ReceiptOfGoodsToWarehouseAttachedFiles.Update.Companies
	|Catalog.ReceiptOfGoodsToWarehouseAttachedFiles.Update.Departments
	|Catalog.ReceiptOfGoodsToWarehouseAttachedFiles.Update.Warehouses
	|Catalog.GoodsReceiptFromCustomerAttachedFiles.Read.PartnerGroups
	|Catalog.GoodsReceiptFromCustomerAttachedFiles.Read.Companies
	|Catalog.GoodsReceiptFromCustomerAttachedFiles.Read.Departments
	|Catalog.GoodsReceiptFromCustomerAttachedFiles.Read.Warehouses
	|Catalog.GoodsReceiptFromCustomerAttachedFiles.Read.BusinessTransactions
	|Catalog.GoodsReceiptFromCustomerAttachedFiles.Update.PartnerGroups
	|Catalog.GoodsReceiptFromCustomerAttachedFiles.Update.Companies
	|Catalog.GoodsReceiptFromCustomerAttachedFiles.Update.Departments
	|Catalog.GoodsReceiptFromCustomerAttachedFiles.Update.Warehouses
	|Catalog.GoodsReceiptFromCustomerAttachedFiles.Update.BusinessTransactions
	|Catalog.ReceiptOfGoodsFromCustodianAttachedFiles.Read.PartnerGroups
	|Catalog.ReceiptOfGoodsFromCustodianAttachedFiles.Read.Companies
	|Catalog.ReceiptOfGoodsFromCustodianAttachedFiles.Read.Departments
	|Catalog.ReceiptOfGoodsFromCustodianAttachedFiles.Read.BusinessTransactions
	|Catalog.ReceiptOfGoodsFromCustodianAttachedFiles.Update.PartnerGroups
	|Catalog.ReceiptOfGoodsFromCustodianAttachedFiles.Update.Companies
	|Catalog.ReceiptOfGoodsFromCustodianAttachedFiles.Update.Departments
	|Catalog.ReceiptOfGoodsFromCustodianAttachedFiles.Update.BusinessTransactions
	|Catalog.ReceiptOfServicesToBusinessUnitAttachedFiles.Read.PartnerGroups
	|Catalog.ReceiptOfServicesToBusinessUnitAttachedFiles.Read.Companies
	|Catalog.ReceiptOfServicesToBusinessUnitAttachedFiles.Read.Departments
	|Catalog.ReceiptOfServicesToBusinessUnitAttachedFiles.Update.PartnerGroups
	|Catalog.ReceiptOfServicesToBusinessUnitAttachedFiles.Update.Companies
	|Catalog.ReceiptOfServicesToBusinessUnitAttachedFiles.Update.Departments
	|Catalog.EmailProcessingRules.Read.Users
	|Catalog.EmailProcessingRules.Read.EmailAccounts
	|Catalog.EmailProcessingRules.Update.Users
	|Catalog.EmailProcessingRules.Update.EmailAccounts
	|Catalog.Complaints.Read.ExternalUsers
	|Catalog.Complaints.Read.PartnerGroups
	|Catalog.Complaints.Update.ExternalUsers
	|Catalog.Complaints.Update.PartnerGroups
	|Catalog.ComplaintsAttachedFiles.Read.ExternalUsers
	|Catalog.ComplaintsAttachedFiles.Read.PartnerGroups
	|Catalog.ComplaintsAttachedFiles.Update.PartnerGroups
	|Catalog.GoodsReceiptForStorageAttachedFiles.Read.PartnerGroups
	|Catalog.GoodsReceiptForStorageAttachedFiles.Read.Companies
	|Catalog.GoodsReceiptForStorageAttachedFiles.Read.Departments
	|Catalog.GoodsReceiptForStorageAttachedFiles.Read.Warehouses
	|Catalog.GoodsReceiptForStorageAttachedFiles.Read.BusinessTransactions
	|Catalog.GoodsReceiptForStorageAttachedFiles.Update.PartnerGroups
	|Catalog.GoodsReceiptForStorageAttachedFiles.Update.Companies
	|Catalog.GoodsReceiptForStorageAttachedFiles.Update.Departments
	|Catalog.GoodsReceiptForStorageAttachedFiles.Update.Warehouses
	|Catalog.GoodsReceiptForStorageAttachedFiles.Update.BusinessTransactions
	|Catalog.VendorInvoiceAttachedFiles.Read.PartnerGroups
	|Catalog.VendorInvoiceAttachedFiles.Read.Companies
	|Catalog.VendorInvoiceAttachedFiles.Read.Departments
	|Catalog.VendorInvoiceAttachedFiles.Read.Warehouses
	|Catalog.VendorInvoiceAttachedFiles.Update.PartnerGroups
	|Catalog.VendorInvoiceAttachedFiles.Update.Companies
	|Catalog.VendorInvoiceAttachedFiles.Update.Departments
	|Catalog.VendorInvoiceAttachedFiles.Update.Warehouses
	|Catalog.VendorInvoiceServicesAndAssetsAttachedFiles.Read.PartnerGroups
	|Catalog.VendorInvoiceServicesAndAssetsAttachedFiles.Read.Companies
	|Catalog.VendorInvoiceServicesAndAssetsAttachedFiles.Read.Departments
	|Catalog.VendorInvoiceServicesAndAssetsAttachedFiles.Update.PartnerGroups
	|Catalog.VendorInvoiceServicesAndAssetsAttachedFiles.Update.Companies
	|Catalog.VendorInvoiceServicesAndAssetsAttachedFiles.Update.Departments
	|Catalog.OtherIncomeExpensesAttachedFiles.Read.Companies
	|Catalog.OtherIncomeExpensesAttachedFiles.Update.Companies
	|Catalog.WarehouseZones.Read.Warehouses
	|Catalog.WarehouseZones.Update.Warehouses
	|Catalog.MailoutToCustomersAttachedFiles.Read.Object.Document.MailoutToCustomers
	|Catalog.CustomerInvoiceAttachedFiles.Read.PartnerGroups
	|Catalog.CustomerInvoiceAttachedFiles.Read.Companies
	|Catalog.CustomerInvoiceAttachedFiles.Read.Departments
	|Catalog.CustomerInvoiceAttachedFiles.Read.Warehouses
	|Catalog.CustomerInvoiceAttachedFiles.Update.PartnerGroups
	|Catalog.CustomerInvoiceAttachedFiles.Update.Companies
	|Catalog.CustomerInvoiceAttachedFiles.Update.Departments
	|Catalog.CustomerInvoiceAttachedFiles.Update.Warehouses
	|Catalog.CustomerInvoiceServicesAndAssetsAttachedFiles.Read.PartnerGroups
	|Catalog.CustomerInvoiceServicesAndAssetsAttachedFiles.Read.Companies
	|Catalog.CustomerInvoiceServicesAndAssetsAttachedFiles.Read.Departments
	|Catalog.CustomerInvoiceServicesAndAssetsAttachedFiles.Update.PartnerGroups
	|Catalog.CustomerInvoiceServicesAndAssetsAttachedFiles.Update.Companies
	|Catalog.CustomerInvoiceServicesAndAssetsAttachedFiles.Update.Departments
	|Catalog.VendorPriceListAttachedFiles.Read.PartnerGroups
	|Catalog.VendorPriceListAttachedFiles.Update.PartnerGroups
	|Catalog.TripAttachedFiles.Read.Companies
	|Catalog.TripAttachedFiles.Update.Companies
	|Catalog.ARAPReconciliation2_4AttachedFiles.Read.PartnerGroups
	|Catalog.ARAPReconciliation2_4AttachedFiles.Read.Companies
	|Catalog.ARAPReconciliation2_4AttachedFiles.Update.PartnerGroups
	|Catalog.ARAPReconciliation2_4AttachedFiles.Update.Companies
	|Catalog.ARAPReconciliation2_5_11AttachedFiles.Read.PartnerGroups
	|Catalog.ARAPReconciliation2_5_11AttachedFiles.Read.Companies
	|Catalog.ARAPReconciliation2_5_11AttachedFiles.Update.PartnerGroups
	|Catalog.ARAPReconciliation2_5_11AttachedFiles.Update.Companies
	|Catalog.SalesOpportunitiesToCustomer.Read.Object.Catalog.SalesOpportunitiesToCustomer
	|Catalog.SalesOpportunitiesToCustomer.Update.Object.Catalog.SalesOpportunitiesToCustomer
	|Catalog.SalesOpportunitiesToCustomerAttachedFiles.Read.Object.Catalog.SalesOpportunitiesToCustomer
	|Catalog.SalesOpportunitiesToCustomerAttachedFiles.Update.Object.Catalog.SalesOpportunitiesToCustomer
	|Catalog.DigitalSignatureAndEncryptionKeysCertificates.Read.Companies
	|Catalog.DigitalSignatureAndEncryptionKeysCertificates.Read.Users
	|Catalog.DigitalSignatureAndEncryptionKeysCertificates.Update.Companies
	|Catalog.DigitalSignatureAndEncryptionKeysCertificates.Update.Users
	|Catalog.Warerooms.Read.Warehouses
	|Catalog.StorageBins.Read.Warehouses
	|Catalog.StorageBins.Update.Warehouses
	|Catalog.Warehouses.Read.Warehouses
	|Catalog.Warehouses.Update.Warehouses
	|Catalog.TermsOfSale.Read.ExternalUsers
	|Catalog.TermsOfSale.Read.PartnerGroups
	|Catalog.TermsOfSale.Read.Companies
	|Catalog.TermsOfSale.Read.Warehouses
	|Catalog.TermsOfSale.Read.CustomerAgreementsReading
	|Catalog.TermsOfSale.Update.PartnerGroups
	|Catalog.TermsOfSale.Update.Companies
	|Catalog.TermsOfSale.Update.Warehouses
	|Catalog.TermsOfSale.Update.TermsOfSaleUpdate
	|Catalog.TermsOfSaleAttachedFiles.Read.PartnerGroups
	|Catalog.TermsOfSaleAttachedFiles.Read.Companies
	|Catalog.TermsOfSaleAttachedFiles.Read.Warehouses
	|Catalog.TermsOfSaleAttachedFiles.Read.CustomerAgreementsReading
	|Catalog.TermsOfSaleAttachedFiles.Update.PartnerGroups
	|Catalog.TermsOfSaleAttachedFiles.Update.Companies
	|Catalog.TermsOfSaleAttachedFiles.Update.Warehouses
	|Catalog.TermsOfSaleAttachedFiles.Update.TermsOfSaleUpdate
	|Catalog.TermsOfPurchaseFromVendors.Read.PartnerGroups
	|Catalog.TermsOfPurchaseFromVendors.Read.Companies
	|Catalog.TermsOfPurchaseFromVendors.Read.Warehouses
	|Catalog.TermsOfPurchaseFromVendors.Update.PartnerGroups
	|Catalog.TermsOfPurchaseFromVendors.Update.Companies
	|Catalog.TermsOfPurchaseFromVendors.Update.Warehouses
	|Catalog.TermsOfPurchaseFromVendorsAttachedFiles.Read.PartnerGroups
	|Catalog.TermsOfPurchaseFromVendorsAttachedFiles.Read.Companies
	|Catalog.TermsOfPurchaseFromVendorsAttachedFiles.Read.Warehouses
	|Catalog.TermsOfPurchaseFromVendorsAttachedFiles.Update.PartnerGroups
	|Catalog.TermsOfPurchaseFromVendorsAttachedFiles.Update.Companies
	|Catalog.TermsOfPurchaseFromVendorsAttachedFiles.Update.Warehouses
	|Catalog.SMSMessageAttachedFiles.Read.Object.Document.SMSMessage
	|Catalog.SMSMessageAttachedFiles.Update.Object.Document.SMSMessage
	|Catalog.BankAccountIssueAttachedFiles.Read.PartnerGroups
	|Catalog.BankAccountIssueAttachedFiles.Read.GroupsOfIndividuals
	|Catalog.BankAccountIssueAttachedFiles.Read.Companies
	|Catalog.BankAccountIssueAttachedFiles.Read.BusinessTransactions
	|Catalog.BankAccountIssueAttachedFiles.Update.PartnerGroups
	|Catalog.BankAccountIssueAttachedFiles.Update.GroupsOfIndividuals
	|Catalog.BankAccountIssueAttachedFiles.Update.Companies
	|Catalog.BankAccountIssueAttachedFiles.Update.BusinessTransactions
	|Catalog.WriteOffOfShippedGoodsAttachedFiles.Read.PartnerGroups
	|Catalog.WriteOffOfShippedGoodsAttachedFiles.Read.Companies
	|Catalog.WriteOffOfShippedGoodsAttachedFiles.Read.Departments
	|Catalog.WriteOffOfShippedGoodsAttachedFiles.Read.BusinessTransactions
	|Catalog.WriteOffOfShippedGoodsAttachedFiles.Update.PartnerGroups
	|Catalog.WriteOffOfShippedGoodsAttachedFiles.Update.Companies
	|Catalog.WriteOffOfShippedGoodsAttachedFiles.Update.Departments
	|Catalog.WriteOffOfShippedGoodsAttachedFiles.Update.BusinessTransactions
	|Catalog.WriteOffDiscrepanciesBetweenReceiptAndPurchaseAttachedFiles.Read.PartnerGroups
	|Catalog.WriteOffDiscrepanciesBetweenReceiptAndPurchaseAttachedFiles.Read.Companies
	|Catalog.WriteOffDiscrepanciesBetweenReceiptAndPurchaseAttachedFiles.Read.Departments
	|Catalog.DebitCustomerRebatesAttachedFiles.Read.Companies
	|Catalog.DebitCustomerRebatesAttachedFiles.Update.Companies
	|Catalog.WriteOffVendorRebatesAttachedFiles.Read.Companies
	|Catalog.WriteOffVendorRebatesAttachedFiles.Update.Companies
	|Catalog.ReversingEntryAttachedFiles.Read.Companies
	|Catalog.ReversingEntryAttachedFiles.Update.Companies
	|Catalog.BusinessStructure.Read.Departments
	|Catalog.CustomerCommercialInvoiceAttachedFiles.Read.PartnerGroups
	|Catalog.CustomerCommercialInvoiceAttachedFiles.Read.Companies
	|Catalog.CustomerCommercialInvoiceAttachedFiles.Update.PartnerGroups
	|Catalog.CustomerCommercialInvoiceAttachedFiles.Update.Companies
	|Catalog.IssuedTaxInvoicePrepaymentAttachedFiles.Read.Companies
	|Catalog.IssuedTaxInvoicePrepaymentAttachedFiles.Update.Companies
	|Catalog.ReceivedTaxInvoicePrepaymentAttachedFiles.Read.Companies
	|Catalog.ReceivedTaxInvoicePrepaymentAttachedFiles.Update.Companies
	|Catalog.CCDImportAttachedFiles.Read.PartnerGroups
	|Catalog.CCDImportAttachedFiles.Read.Companies
	|Catalog.CCDImportAttachedFiles.Read.Departments
	|Catalog.CCDImportAttachedFiles.Update.PartnerGroups
	|Catalog.CCDImportAttachedFiles.Update.Companies
	|Catalog.CCDImportAttachedFiles.Update.Departments
	|Catalog.PhoneCallAttachedFiles.Read.Object.Document.PhoneCall
	|Catalog.PhoneCallAttachedFiles.Update.Object.Document.PhoneCall
	|Catalog.DeliveryPoints.Read.ExternalUsers
	|Catalog.DeliveryPoints.Read.PartnerGroups
	|Catalog.DeliveryPoints.Read.Warehouses
	|Catalog.DeliveryPoints.Update.PartnerGroups
	|Catalog.DeliveryPoints.Update.Warehouses
	|Catalog.PackagesAndUnitsOfMeasure.Update.ProductGroups
	|Catalog.TermsAndConditionsOfServicesProvidedToCustomersBySalesRepresentatives.Read.PartnerGroups
	|Catalog.TermsAndConditionsOfServicesProvidedToCustomersBySalesRepresentatives.Update.PartnerGroups
	|Catalog.ConditionsOfCustomerRebatesAttachedFiles.Read.Companies
	|Catalog.ConditionsOfCustomerRebatesAttachedFiles.Update.Companies
	|Catalog.ConditionsOfVendorRebatesAttachedFiles.Read.Companies
	|Catalog.ConditionsOfVendorRebatesAttachedFiles.Update.Companies
	|Catalog.PriceSetupAttachedFiles.Read.Object.Document.PriceSetup
	|Catalog.PriceSetupAttachedFiles.Update.Object.Document.PriceSetup
	|Catalog.EmailAccounts.Read.Users
	|Catalog.EmailAccounts.Read.EmailAccounts
	|Catalog.EmailAccounts.Update.Users
	|Catalog.Files.Read.ExternalUsers
	|Catalog.Files.Read.RightsSettings.Catalog.FilesFolders
	|Catalog.Files.Read.Object.BusinessProcess.Job
	|Catalog.Files.Read.Object.Document.RetailReturnsReport
	|Catalog.Files.Read.Object.Document.RetailSalesReport
	|Catalog.Files.Read.Object.Catalog.FilesFolders
	|Catalog.Files.Read.Object.Catalog.Persons
	|Catalog.Files.Update.ExternalUsers
	|Catalog.Files.Update.RightsSettings.Catalog.FilesFolders
	|Catalog.Files.Update.Object.BusinessProcess.Job
	|Catalog.Files.Update.Object.Document.RetailReturnsReport
	|Catalog.Files.Update.Object.Document.RetailSalesReport
	|Catalog.Files.Update.Object.Catalog.FilesFolders
	|Catalog.Files.Update.Object.Catalog.Persons
	|Catalog.Persons.Read.GroupsOfIndividuals
	|Catalog.Persons.Update.GroupsOfIndividuals
	|Catalog.PersonsAttachedFiles.Read.GroupsOfIndividuals
	|Catalog.PersonsAttachedFiles.Update.GroupsOfIndividuals
	|Catalog.ItemsCharacteristics.Update.ProductGroups
	|Catalog.MessageTemplates.Read.Users
	|Catalog.MessageTemplates.Update.Users
	|Catalog.MessageTemplatesAttachedFiles.Read.Users
	|Catalog.MessageTemplatesAttachedFiles.Update.Users
	|Catalog.POSTerminals.Read.Companies
	|Catalog.POSTerminals.Read.POSTerminals
	|Catalog.IncomingEmailAttachedFiles.Read.Object.Document.IncomingEmail
	|Catalog.IncomingEmailAttachedFiles.Update.Object.Document.IncomingEmail
	|Catalog.OutgoingEmailAttachedFiles.Read.Object.Document.OutgoingEmail
	|Catalog.OutgoingEmailAttachedFiles.Update.Object.Document.OutgoingEmail
	|Document.ExpenseReport.Read.PartnerGroups
	|Document.ExpenseReport.Read.GroupsOfIndividuals
	|Document.ExpenseReport.Read.Companies
	|Document.ExpenseReport.Read.Departments
	|Document.ExpenseReport.Update.PartnerGroups
	|Document.ExpenseReport.Update.GroupsOfIndividuals
	|Document.ExpenseReport.Update.Companies
	|Document.ExpenseReport.Update.Departments
	|Document.CustomerInvoiceServices.Read.ExternalUsers
	|Document.CustomerInvoiceServices.Read.PartnerGroups
	|Document.CustomerInvoiceServices.Read.Companies
	|Document.CustomerInvoiceServices.Read.Departments
	|Document.CustomerInvoiceServices.Update.PartnerGroups
	|Document.CustomerInvoiceServices.Update.Companies
	|Document.CustomerInvoiceServices.Update.Departments
	|Document.GoodsQualityControlCertificate.Read.PartnerGroups
	|Document.GoodsQualityControlCertificate.Read.Companies
	|Document.GoodsQualityControlCertificate.Read.Departments
	|Document.GoodsQualityControlCertificate.Read.Warehouses
	|Document.GoodsQualityControlCertificate.Read.BusinessTransactions
	|Document.GoodsQualityControlCertificate.Update.PartnerGroups
	|Document.GoodsQualityControlCertificate.Update.Companies
	|Document.GoodsQualityControlCertificate.Update.Departments
	|Document.GoodsQualityControlCertificate.Update.Warehouses
	|Document.GoodsQualityControlCertificate.Update.BusinessTransactions
	|Document.DiscrepancyReportFollowingShipment.Read.ExternalUsers
	|Document.DiscrepancyReportFollowingShipment.Read.PartnerGroups
	|Document.DiscrepancyReportFollowingShipment.Read.Companies
	|Document.DiscrepancyReportFollowingShipment.Read.TypesOfGroundsForActOfDiscrepancies
	|Document.DiscrepancyReportFollowingShipment.Update.ExternalUsers
	|Document.DiscrepancyReportFollowingShipment.Update.PartnerGroups
	|Document.DiscrepancyReportFollowingShipment.Update.Companies
	|Document.DiscrepancyReportFollowingShipment.Update.TypesOfGroundsForActOfDiscrepancies
	|Document.DiscrepancyReportFollowingTransfer.Read.Companies
	|Document.DiscrepancyReportFollowingTransfer.Read.Warehouses
	|Document.DiscrepancyReportFollowingTransfer.Update.Companies
	|Document.DiscrepancyReportFollowingTransfer.Update.Warehouses
	|Document.DiscrepancyReportFollowingReceipt.Read.PartnerGroups
	|Document.DiscrepancyReportFollowingReceipt.Read.Companies
	|Document.DiscrepancyReportFollowingReceipt.Read.TypesOfGroundsForActOfDiscrepancies
	|Document.DiscrepancyReportFollowingReceipt.Update.PartnerGroups
	|Document.DiscrepancyReportFollowingReceipt.Update.Companies
	|Document.DiscrepancyReportFollowingReceipt.Update.TypesOfGroundsForActOfDiscrepancies
	|Document.CustomerBonusCertificate.Read.PartnerGroups
	|Document.CustomerBonusCertificate.Read.Companies
	|Document.CustomerBonusCertificate.Update.PartnerGroups
	|Document.CustomerBonusCertificate.Update.Companies
	|Document.VendorBonusCertificate.Read.PartnerGroups
	|Document.VendorBonusCertificate.Read.Companies
	|Document.VendorBonusCertificate.Update.PartnerGroups
	|Document.VendorBonusCertificate.Update.Companies
	|Document.OBEntry.Read.Companies
	|Document.OBEntry.Read.Warehouses
	|Document.OBEntryARAP.Read.Companies
	|Document.OBEntryARAP.Update.Companies
	|Document.OBEntryCash.Read.Companies
	|Document.OBEntryCash.Update.Companies
	|Document.OBEntrySalesForPastPeriods.Read.Companies
	|Document.OBEntrySalesForPastPeriods.Read.Warehouses
	|Document.OBEntrySalesForPastPeriods.Update.Companies
	|Document.OBEntrySalesForPastPeriods.Update.Warehouses
	|Document.OBEntryFinancialInstruments.Read.Companies
	|Document.OBEntryFinancialInstruments.Update.Companies
	|Document.OBEntryOtherExpenses.Read.Companies
	|Document.OBEntryOtherExpenses.Update.Companies
	|Document.OBEntryOtherAssetsAndLiabilities.Read.Companies
	|Document.OBEntryOtherAssetsAndLiabilities.Update.Companies
	|Document.OBEntryAcquiringContractARAP.Read.Companies
	|Document.OBEntryAcquiringContractARAP.Update.Companies
	|Document.OBEntryARAPAdvanceHolders.Read.Companies
	|Document.OBEntryARAPAdvanceHolders.Update.Companies
	|Document.OBEntryInventoryInOperation.Read.Companies
	|Document.OBEntryInventoryInOperation.Update.Companies
	|Document.OBEntryGoods.Read.Companies
	|Document.OBEntryGoods.Read.Warehouses
	|Document.OBEntryGoods.Update.Companies
	|Document.OBEntryGoods.Update.Warehouses
	|Document.ARAPSettlement.Read.PartnerGroups
	|Document.ARAPSettlement.Read.Companies
	|Document.ARAPSettlement.Update.KindsOfARAPSettlements
	|Document.ARAPSettlement.Update.PartnerGroups
	|Document.ARAPSettlement.Update.Companies
	|Document.DepositCashIntoCashRegister.Read.CashAccounts
	|Document.DepositCashIntoCashRegister.Read.CashRegisters
	|Document.DepositCashIntoCashRegister.Read.Companies
	|Document.DepositCashIntoCashRegister.Update.CashAccounts
	|Document.DepositCashIntoCashRegister.Update.CashRegisters
	|Document.DepositCashIntoCashRegister.Update.Companies
	|Document.InventoryConsumption.Read.Companies
	|Document.InventoryConsumption.Read.Departments
	|Document.InventoryConsumption.Read.Warehouses
	|Document.InventoryConsumption.Update.Companies
	|Document.InventoryConsumption.Update.Departments
	|Document.InventoryConsumption.Update.Warehouses
	|Document.IntercompanyGoodsReturn.Read.PartnerGroups
	|Document.IntercompanyGoodsReturn.Read.Companies
	|Document.IntercompanyGoodsReturn.Read.Departments
	|Document.IntercompanyGoodsReturn.Read.Warehouses
	|Document.IntercompanyGoodsReturn.Update.PartnerGroups
	|Document.IntercompanyGoodsReturn.Update.Companies
	|Document.IntercompanyGoodsReturn.Update.Departments
	|Document.IntercompanyGoodsReturn.Update.Warehouses
	|Document.ReturnOfGoodsFromCustomer.Read.ExternalUsers
	|Document.ReturnOfGoodsFromCustomer.Read.PartnerGroups
	|Document.ReturnOfGoodsFromCustomer.Read.Companies
	|Document.ReturnOfGoodsFromCustomer.Read.Departments
	|Document.ReturnOfGoodsFromCustomer.Read.Warehouses
	|Document.ReturnOfGoodsFromCustomer.Update.PartnerGroups
	|Document.ReturnOfGoodsFromCustomer.Update.Companies
	|Document.ReturnOfGoodsFromCustomer.Update.Departments
	|Document.ReturnOfGoodsFromCustomer.Update.Warehouses
	|Document.ReturnOfGoodsToVendor.Read.PartnerGroups
	|Document.ReturnOfGoodsToVendor.Read.Companies
	|Document.ReturnOfGoodsToVendor.Read.Departments
	|Document.ReturnOfGoodsToVendor.Read.Warehouses
	|Document.ReturnOfGoodsToVendor.Update.PartnerGroups
	|Document.ReturnOfGoodsToVendor.Update.Companies
	|Document.ReturnOfGoodsToVendor.Update.Departments
	|Document.ReturnOfGoodsToVendor.Update.Warehouses
	|Document.Meeting.Read.Object.Document.Meeting
	|Document.Meeting.Update.Object.Document.Meeting
	|Document.CashWithdrawalFromCashRegister.Read.CashRegisters
	|Document.CashWithdrawalFromCashRegister.Read.Companies
	|Document.CashWithdrawalFromCashRegister.Update.CashRegisters
	|Document.CashWithdrawalFromCashRegister.Update.Companies
	|Document.ReturnablePackagingRedemptionByCustomer.Read.Companies
	|Document.ReturnablePackagingRedemptionByCustomer.Update.Companies
	|Document.RedemptionOfReturnablePackagingFromVendor.Read.Companies
	|Document.RedemptionOfReturnablePackagingFromVendor.Update.Companies
	|Document.RedemptionOfGoodsFromStorage.Read.PartnerGroups
	|Document.RedemptionOfGoodsFromStorage.Read.Companies
	|Document.RedemptionOfGoodsFromStorage.Read.Departments
	|Document.RedemptionOfGoodsFromStorage.Read.BusinessTransactions
	|Document.RedemptionOfGoodsFromStorage.Update.PartnerGroups
	|Document.RedemptionOfGoodsFromStorage.Update.Companies
	|Document.RedemptionOfGoodsFromStorage.Update.Departments
	|Document.RedemptionOfGoodsFromStorage.Update.BusinessTransactions
	|Document.RedemptionOfGoodsByCustodian.Read.PartnerGroups
	|Document.RedemptionOfGoodsByCustodian.Read.Companies
	|Document.RedemptionOfGoodsByCustodian.Read.Departments
	|Document.RedemptionOfGoodsByCustodian.Read.BusinessTransactions
	|Document.RedemptionOfGoodsByCustodian.Update.PartnerGroups
	|Document.RedemptionOfGoodsByCustodian.Update.Companies
	|Document.RedemptionOfGoodsByCustodian.Update.Departments
	|Document.RedemptionOfGoodsByCustodian.Update.BusinessTransactions
	|Document.MovementOfOtherAssetsAndLiabilities.Read.Companies
	|Document.MovementOfOtherAssetsAndLiabilities.Update.Companies
	|Document.IssuedLetterOfAuthority.Read.PartnerGroups
	|Document.IssuedLetterOfAuthority.Read.GroupsOfIndividuals
	|Document.IssuedLetterOfAuthority.Read.Companies
	|Document.IssuedLetterOfAuthority.Update.PartnerGroups
	|Document.IssuedLetterOfAuthority.Update.GroupsOfIndividuals
	|Document.IssuedLetterOfAuthority.Update.Companies
	|Document.TransportationJob.Read.Warehouses
	|Document.TransportationJob.Update.Warehouses
	|Document.JobForSalesRepresentative.Read.PartnerGroups
	|Document.JobForSalesRepresentative.Read.Companies
	|Document.JobForSalesRepresentative.Read.Warehouses
	|Document.JobForSalesRepresentative.Update.PartnerGroups
	|Document.JobForSalesRepresentative.Update.Companies
	|Document.JobForSalesRepresentative.Update.Warehouses
	|Document.SalesOrder.Read.ExternalUsers
	|Document.SalesOrder.Read.PartnerGroups
	|Document.SalesOrder.Read.Companies
	|Document.SalesOrder.Read.Departments
	|Document.SalesOrder.Read.Warehouses
	|Document.SalesOrder.Update.ExternalUsers
	|Document.SalesOrder.Update.PartnerGroups
	|Document.SalesOrder.Update.Companies
	|Document.SalesOrder.Update.Departments
	|Document.SalesOrder.Update.Warehouses
	|Document.InventoryConsumptionOrder.Read.Companies
	|Document.InventoryConsumptionOrder.Read.Departments
	|Document.InventoryConsumptionOrder.Read.Warehouses
	|Document.InventoryConsumptionOrder.Update.Companies
	|Document.InventoryConsumptionOrder.Update.Departments
	|Document.InventoryConsumptionOrder.Update.Warehouses
	|Document.DeliveryOrder.Read.PartnerGroups
	|Document.DeliveryOrder.Read.Companies
	|Document.DeliveryOrder.Read.Warehouses
	|Document.DeliveryOrder.Update.PartnerGroups
	|Document.DeliveryOrder.Update.Companies
	|Document.DeliveryOrder.Update.Warehouses
	|Document.TransferOrder.Read.Companies
	|Document.TransferOrder.Read.Warehouses
	|Document.TransferOrder.Update.Companies
	|Document.TransferOrder.Update.Warehouses
	|Document.ByAssemblyDisassemblyOrder.Read.Companies
	|Document.ByAssemblyDisassemblyOrder.Read.Warehouses
	|Document.ByAssemblyDisassemblyOrder.Update.Companies
	|Document.ByAssemblyDisassemblyOrder.Update.Warehouses
	|Document.PurchaseOrder.Read.PartnerGroups
	|Document.PurchaseOrder.Read.Companies
	|Document.PurchaseOrder.Read.Departments
	|Document.PurchaseOrder.Read.Warehouses
	|Document.PurchaseOrder.Update.PartnerGroups
	|Document.PurchaseOrder.Update.Companies
	|Document.PurchaseOrder.Update.Departments
	|Document.PurchaseOrder.Update.Warehouses
	|Document.PlannedInteraction.Read.Object.Document.PlannedInteraction
	|Document.PlannedInteraction.Update.Object.Document.PlannedInteraction
	|Document.RequestForReturnOfGoodsFromCustomer.Read.ExternalUsers
	|Document.RequestForReturnOfGoodsFromCustomer.Read.PartnerGroups
	|Document.RequestForReturnOfGoodsFromCustomer.Read.Companies
	|Document.RequestForReturnOfGoodsFromCustomer.Read.Warehouses
	|Document.RequestForReturnOfGoodsFromCustomer.Update.ExternalUsers
	|Document.RequestForReturnOfGoodsFromCustomer.Update.PartnerGroups
	|Document.RequestForReturnOfGoodsFromCustomer.Update.Companies
	|Document.RequestForReturnOfGoodsFromCustomer.Update.Warehouses
	|Document.PurchaseRequest.Read.Companies
	|Document.PurchaseRequest.Read.Departments
	|Document.PurchaseRequest.Read.Warehouses
	|Document.PurchaseRequest.Update.Companies
	|Document.PurchaseRequest.Update.Departments
	|Document.PurchaseRequest.Update.Warehouses
	|Document.ApplicationForBusinessTrip.Read.Companies
	|Document.ApplicationForBusinessTrip.Read.Departments
	|Document.ApplicationForBusinessTrip.Read.Users
	|Document.ApplicationForBusinessTrip.Update.Companies
	|Document.ApplicationForBusinessTrip.Update.Departments
	|Document.ApplicationForBusinessTrip.Update.Users
	|Document.RequestForGoodsQualityControl.Read.Companies
	|Document.RequestForGoodsQualityControl.Read.Departments
	|Document.RequestForGoodsQualityControl.Read.Warehouses
	|Document.RequestForGoodsQualityControl.Update.Companies
	|Document.RequestForGoodsQualityControl.Update.Departments
	|Document.RequestForGoodsQualityControl.Update.Warehouses
	|Document.ApplicationForCollateral.Read.Companies
	|Document.ApplicationForCollateral.Read.Departments
	|Document.ApplicationForCollateral.Read.Warehouses
	|Document.ApplicationForCollateral.Update.Companies
	|Document.ApplicationForCollateral.Update.Departments
	|Document.ApplicationForCollateral.Update.Warehouses
	|Document.PaymentRequest.Read.PartnerGroups
	|Document.PaymentRequest.Read.GroupsOfIndividuals
	|Document.PaymentRequest.Read.Companies
	|Document.PaymentRequest.Read.Departments
	|Document.PaymentRequest.Read.Users
	|Document.PaymentRequest.Read.BusinessTransactions
	|Document.PaymentRequest.Update.PartnerGroups
	|Document.PaymentRequest.Update.GroupsOfIndividuals
	|Document.PaymentRequest.Update.Companies
	|Document.PaymentRequest.Update.Departments
	|Document.PaymentRequest.Update.Users
	|Document.PaymentRequest.Update.BusinessTransactions
	|Document.ApplicationForImportationOfGoods.Read.PartnerGroups
	|Document.ApplicationForImportationOfGoods.Read.Companies
	|Document.ApplicationForImportationOfGoods.Read.Departments
	|Document.ApplicationForImportationOfGoods.Update.PartnerGroups
	|Document.ApplicationForImportationOfGoods.Update.Companies
	|Document.ApplicationForImportationOfGoods.Update.Departments
	|Document.ProductRangeChange.Read.Object.Document.ProductRangeChange
	|Document.ProductRangeChange.Update.Object.Document.ProductRangeChange
	|Document.PhysicalCountReport.Read.Companies
	|Document.PhysicalCountReport.Read.Warehouses
	|Document.PhysicalCountReport.Update.Companies
	|Document.PhysicalCountReport.Update.Warehouses
	|Document.PhysicalCountOfCashAccounts.Read.Companies
	|Document.PhysicalCountOfCashAccounts.Update.Companies
	|Document.CommercialProposalForCustomer.Read.PartnerGroups
	|Document.CommercialProposalForCustomer.Read.Companies
	|Document.CommercialProposalForCustomer.Update.PartnerGroups
	|Document.CommercialProposalForCustomer.Update.Companies
	|Document.ARAPAccountingScheduleAdjustment.Read.PartnerGroups
	|Document.ARAPAccountingScheduleAdjustment.Read.Companies
	|Document.ARAPAccountingScheduleAdjustment.Update.PartnerGroups
	|Document.ARAPAccountingScheduleAdjustment.Update.Companies
	|Document.ARAPAdjustment.Read.PartnerGroups
	|Document.ARAPAdjustment.Read.Companies
	|Document.ARAPAdjustment.Update.PartnerGroups
	|Document.ARAPAdjustment.Update.Companies
	|Document.ARAPAdjustmentFinancialInstruments.Read.PartnerGroups
	|Document.ARAPAdjustmentFinancialInstruments.Read.Companies
	|Document.ARAPAdjustmentFinancialInstruments.Update.PartnerGroups
	|Document.ARAPAdjustmentFinancialInstruments.Update.Companies
	|Document.InventoryAdjustmentSurplusesAndShortages.Read.Warehouses
	|Document.InventoryAdjustmentSurplusesAndShortages.Update.Warehouses
	|Document.InventoryAssignmentAdjustment.Read.Companies
	|Document.InventoryAssignmentAdjustment.Update.Companies
	|Document.AdjustmentOfPlannedDemand.Read.PlanProfiles
	|Document.AdjustmentOfPlannedDemand.Read.SalesOperationsPlanningScenarios
	|Document.AdjustmentOfPlannedDemand.Update.PlanProfiles
	|Document.AdjustmentOfPlannedDemand.Update.SalesOperationsPlanningScenarios
	|Document.InventoryAdjustmentGoodsShipmentOrder.Read.Warehouses
	|Document.InventoryAdjustmentGoodsShipmentOrder.Update.Warehouses
	|Document.PurchaseAdjustment.Read.PartnerGroups
	|Document.PurchaseAdjustment.Read.Companies
	|Document.PurchaseAdjustment.Read.Departments
	|Document.PurchaseAdjustment.Read.Warehouses
	|Document.PurchaseAdjustment.Update.PartnerGroups
	|Document.PurchaseAdjustment.Update.Companies
	|Document.PurchaseAdjustment.Update.Departments
	|Document.PurchaseAdjustment.Update.Warehouses
	|Document.AdjustmentOfARAPAccountingForAdvanceHolders.Read.GroupsOfIndividuals
	|Document.AdjustmentOfARAPAccountingForAdvanceHolders.Read.Companies
	|Document.AdjustmentOfARAPAccountingForAdvanceHolders.Read.Departments
	|Document.AdjustmentOfARAPAccountingForAdvanceHolders.Update.GroupsOfIndividuals
	|Document.AdjustmentOfARAPAccountingForAdvanceHolders.Update.Companies
	|Document.AdjustmentOfARAPAccountingForAdvanceHolders.Update.Departments
	|Document.SaleAdjustment.Read.ExternalUsers
	|Document.SaleAdjustment.Read.PartnerGroups
	|Document.SaleAdjustment.Read.Companies
	|Document.SaleAdjustment.Read.Departments
	|Document.SaleAdjustment.Read.Warehouses
	|Document.SaleAdjustment.Update.PartnerGroups
	|Document.SaleAdjustment.Update.Companies
	|Document.SaleAdjustment.Update.Departments
	|Document.SaleAdjustment.Update.Warehouses
	|Document.CashFlowLimits.Read.Companies
	|Document.CashFlowLimits.Read.Departments
	|Document.CashFlowLimits.Update.Companies
	|Document.CashFlowLimits.Update.Departments
	|Document.ReverseVATAccrual.Read.Companies
	|Document.ReverseVATAccrual.Update.Companies
	|Document.AccrualOfCustomerRebates.Read.Companies
	|Document.AccrualOfCustomerRebates.Update.Companies
	|Document.AccrualOfVendorRebates.Read.Companies
	|Document.AccrualOfVendorRebates.Update.Companies
	|Document.LoanAndDepositInterestCharge.Read.Companies
	|Document.LoanAndDepositInterestCharge.Update.Companies
	|Document.PlannedCashReceipt.Read.CashAccounts
	|Document.PlannedCashReceipt.Read.Companies
	|Document.PlannedCashReceipt.Update.CashAccounts
	|Document.PlannedCashReceipt.Update.Companies
	|Document.PaymentCardTransaction.Read.PartnerGroups
	|Document.PaymentCardTransaction.Read.Companies
	|Document.PaymentCardTransaction.Read.POSTerminals
	|Document.PaymentCardTransaction.Update.PartnerGroups
	|Document.PaymentCardTransaction.Update.Companies
	|Document.PaymentCardTransaction.Update.POSTerminals
	|Document.ElectronicTicketTransaction.Read.PartnerGroups
	|Document.ElectronicTicketTransaction.Read.Companies
	|Document.ElectronicTicketTransaction.Read.Departments
	|Document.ElectronicTicketTransaction.Update.PartnerGroups
	|Document.ElectronicTicketTransaction.Update.Companies
	|Document.ElectronicTicketTransaction.Update.Departments
	|Document.RecognitionOfStockSurplusShippedToCustomer.Read.PartnerGroups
	|Document.RecognitionOfStockSurplusShippedToCustomer.Read.Companies
	|Document.RecognitionOfStockSurplusShippedToCustomer.Read.Departments
	|Document.RecognitionOfStockSurplusShippedToCustomer.Read.BusinessTransactions
	|Document.RecognitionOfStockSurplusShippedToCustomer.Update.PartnerGroups
	|Document.RecognitionOfStockSurplusShippedToCustomer.Update.Companies
	|Document.RecognitionOfStockSurplusShippedToCustomer.Update.Departments
	|Document.RecognitionOfStockSurplusShippedToCustomer.Update.BusinessTransactions
	|Document.InventorySurplusRecognition.Read.Companies
	|Document.InventorySurplusRecognition.Read.Departments
	|Document.InventorySurplusRecognition.Read.Warehouses
	|Document.InventorySurplusRecognition.Update.Companies
	|Document.InventorySurplusRecognition.Update.Departments
	|Document.InventorySurplusRecognition.Update.Warehouses
	|Document.GoodsSurplusesNote.Read.Warehouses
	|Document.GoodsSurplusesNote.Update.Warehouses
	|Document.GoodsShortageNote.Read.Warehouses
	|Document.GoodsShortageNote.Update.Warehouses
	|Document.GoodsMisgradingNote.Read.Warehouses
	|Document.GoodsMisgradingNote.Update.Warehouses
	|Document.DamageNote.Read.Warehouses
	|Document.DamageNote.Update.Warehouses
	|Document.GoodsTransferNote.Read.Warehouses
	|Document.GoodsTransferNote.Update.Warehouses
	|Document.GoodsPickingPlacement.Read.Warehouses
	|Document.GoodsPickingPlacement.Update.Warehouses
	|Document.GoodsShipmentToCustomer.Read.ExternalUsers
	|Document.GoodsShipmentToCustomer.Read.PartnerGroups
	|Document.GoodsShipmentToCustomer.Read.Companies
	|Document.GoodsShipmentToCustomer.Read.Departments
	|Document.GoodsShipmentToCustomer.Read.Warehouses
	|Document.GoodsShipmentToCustomer.Read.BusinessTransactions
	|Document.GoodsShipmentToCustomer.Update.PartnerGroups
	|Document.GoodsShipmentToCustomer.Update.Companies
	|Document.GoodsShipmentToCustomer.Update.Departments
	|Document.GoodsShipmentToCustomer.Update.Warehouses
	|Document.GoodsShipmentToCustomer.Update.BusinessTransactions
	|Document.GoodsShipmentFromStorage.Read.PartnerGroups
	|Document.GoodsShipmentFromStorage.Read.Companies
	|Document.GoodsShipmentFromStorage.Read.Departments
	|Document.GoodsShipmentFromStorage.Read.Warehouses
	|Document.GoodsShipmentFromStorage.Read.BusinessTransactions
	|Document.GoodsShipmentFromStorage.Update.PartnerGroups
	|Document.GoodsShipmentFromStorage.Update.Companies
	|Document.GoodsShipmentFromStorage.Update.Departments
	|Document.GoodsShipmentFromStorage.Update.Warehouses
	|Document.GoodsShipmentFromStorage.Update.BusinessTransactions
	|Document.CashDepositWithdrawalDiscrepancies.Read.Companies
	|Document.CashDepositWithdrawalDiscrepancies.Update.Companies
	|Document.BankReportOnAcquiringTransactions.Read.Companies
	|Document.BankReportOnAcquiringTransactions.Read.Departments
	|Document.BankReportOnAcquiringTransactions.Update.Companies
	|Document.BankReportOnAcquiringTransactions.Update.Departments
	|Document.ConsignmentReportFromCustomer.Read.ExternalUsers
	|Document.ConsignmentReportFromCustomer.Read.PartnerGroups
	|Document.ConsignmentReportFromCustomer.Read.Companies
	|Document.ConsignmentReportFromCustomer.Read.Departments
	|Document.ConsignmentReportFromCustomer.Update.ExternalUsers
	|Document.ConsignmentReportFromCustomer.Update.PartnerGroups
	|Document.ConsignmentReportFromCustomer.Update.Companies
	|Document.ConsignmentReportFromCustomer.Update.Departments
	|Document.WriteOffReportFromCommissionAgent.Read.PartnerGroups
	|Document.WriteOffReportFromCommissionAgent.Read.Companies
	|Document.WriteOffReportFromCommissionAgent.Read.Departments
	|Document.WriteOffReportFromCommissionAgent.Update.PartnerGroups
	|Document.WriteOffReportFromCommissionAgent.Update.Companies
	|Document.WriteOffReportFromCommissionAgent.Update.Departments
	|Document.ConsignmentReportToVendor.Read.PartnerGroups
	|Document.ConsignmentReportToVendor.Read.Companies
	|Document.ConsignmentReportToVendor.Read.Departments
	|Document.ConsignmentReportToVendor.Update.PartnerGroups
	|Document.ConsignmentReportToVendor.Update.Companies
	|Document.ConsignmentReportToVendor.Update.Departments
	|Document.PurchasingReportToConsignorPrincipal.Read.PartnerGroups
	|Document.PurchasingReportToConsignorPrincipal.Read.Companies
	|Document.PurchasingReportToConsignorPrincipal.Read.Departments
	|Document.PurchasingReportToConsignorPrincipal.Update.PartnerGroups
	|Document.PurchasingReportToConsignorPrincipal.Update.Companies
	|Document.PurchasingReportToConsignorPrincipal.Update.Departments
	|Document.PurchaseInvoiceConsignmentStockLost.Read.PartnerGroups
	|Document.PurchaseInvoiceConsignmentStockLost.Read.Companies
	|Document.PurchaseInvoiceConsignmentStockLost.Read.Departments
	|Document.PurchaseInvoiceConsignmentStockLost.Update.PartnerGroups
	|Document.PurchaseInvoiceConsignmentStockLost.Update.Companies
	|Document.PurchaseInvoiceConsignmentStockLost.Update.Departments
	|Document.RetailReturnsReport.Read.CashRegisters
	|Document.RetailReturnsReport.Read.Companies
	|Document.RetailReturnsReport.Read.Departments
	|Document.RetailReturnsReport.Read.Warehouses
	|Document.RetailReturnsReport.Update.CashRegisters
	|Document.RetailReturnsReport.Update.Companies
	|Document.RetailReturnsReport.Update.Departments
	|Document.RetailReturnsReport.Update.Warehouses
	|Document.RetailSalesReport.Read.CashRegisters
	|Document.RetailSalesReport.Read.Companies
	|Document.RetailSalesReport.Read.Departments
	|Document.RetailSalesReport.Read.Warehouses
	|Document.RetailSalesReport.Update.CashRegisters
	|Document.RetailSalesReport.Update.Companies
	|Document.RetailSalesReport.Update.Departments
	|Document.RetailSalesReport.Update.Warehouses
	|Document.ReportOnVMIAdjustment.Read.PartnerGroups
	|Document.ReportOnVMIAdjustment.Read.Companies
	|Document.ReportOnVMIAdjustment.Read.Departments
	|Document.ReportOnVMIAdjustment.Read.BusinessTransactions
	|Document.ReportOnVMIAdjustment.Update.PartnerGroups
	|Document.ReportOnVMIAdjustment.Update.Companies
	|Document.ReportOnVMIAdjustment.Update.Departments
	|Document.ReportOnVMIAdjustment.Update.BusinessTransactions
	|Document.CommissionReportIntercompany.Read.PartnerGroups
	|Document.CommissionReportIntercompany.Read.Companies
	|Document.CommissionReportIntercompany.Read.Departments
	|Document.CommissionReportIntercompany.Update.PartnerGroups
	|Document.CommissionReportIntercompany.Update.Companies
	|Document.CommissionReportIntercompany.Update.Departments
	|Document.CommissionWriteOffReportIntercompany.Read.PartnerGroups
	|Document.CommissionWriteOffReportIntercompany.Read.Companies
	|Document.CommissionWriteOffReportIntercompany.Read.Departments
	|Document.CommissionWriteOffReportIntercompany.Update.PartnerGroups
	|Document.CommissionWriteOffReportIntercompany.Update.Companies
	|Document.CommissionWriteOffReportIntercompany.Update.Departments
	|Document.SourceDocument.Read.Companies
	|Document.SourceDocument.Update.Companies
	|Document.CustomerInvoiceIntercompany.Read.PartnerGroups
	|Document.CustomerInvoiceIntercompany.Read.Companies
	|Document.CustomerInvoiceIntercompany.Read.Departments
	|Document.CustomerInvoiceIntercompany.Read.Warehouses
	|Document.CustomerInvoiceIntercompany.Update.PartnerGroups
	|Document.CustomerInvoiceIntercompany.Update.Companies
	|Document.CustomerInvoiceIntercompany.Update.Departments
	|Document.CustomerInvoiceIntercompany.Update.Warehouses
	|Document.TransferOfGoodsToBailee.Read.PartnerGroups
	|Document.TransferOfGoodsToBailee.Read.Companies
	|Document.TransferOfGoodsToBailee.Read.Departments
	|Document.TransferOfGoodsToBailee.Read.Warehouses
	|Document.TransferOfGoodsToBailee.Read.BusinessTransactions
	|Document.TransferOfGoodsToBailee.Update.PartnerGroups
	|Document.TransferOfGoodsToBailee.Update.Companies
	|Document.TransferOfGoodsToBailee.Update.Departments
	|Document.TransferOfGoodsToBailee.Update.Warehouses
	|Document.TransferOfGoodsToBailee.Update.BusinessTransactions
	|Document.InventoryTransfer.Read.Companies
	|Document.InventoryTransfer.Read.Warehouses
	|Document.InventoryTransfer.Update.Companies
	|Document.InventoryTransfer.Update.Warehouses
	|Document.GoodsMisgrading.Read.Companies
	|Document.GoodsMisgrading.Read.Departments
	|Document.GoodsMisgrading.Read.Warehouses
	|Document.GoodsMisgrading.Update.Companies
	|Document.GoodsMisgrading.Update.Departments
	|Document.GoodsMisgrading.Update.Warehouses
	|Document.MisgradingOfGoodsAtCustodian.Read.PartnerGroups
	|Document.MisgradingOfGoodsAtCustodian.Read.Companies
	|Document.MisgradingOfGoodsAtCustodian.Read.Departments
	|Document.MisgradingOfGoodsAtCustodian.Read.BusinessTransactions
	|Document.MisgradingOfGoodsAtCustodian.Update.PartnerGroups
	|Document.MisgradingOfGoodsAtCustodian.Update.Companies
	|Document.MisgradingOfGoodsAtCustodian.Update.Departments
	|Document.MisgradingOfGoodsAtCustodian.Update.BusinessTransactions
	|Document.InventoryRecount.Read.Warehouses
	|Document.InventoryRecount.Update.Warehouses
	|Document.InventoryConsumptionPlan.Read.PlanProfiles
	|Document.InventoryConsumptionPlan.Read.Departments
	|Document.InventoryConsumptionPlan.Read.Warehouses
	|Document.InventoryConsumptionPlan.Read.SalesOperationsPlanningScenarios
	|Document.InventoryConsumptionPlan.Update.PlanProfiles
	|Document.InventoryConsumptionPlan.Update.Departments
	|Document.InventoryConsumptionPlan.Update.Warehouses
	|Document.InventoryConsumptionPlan.Update.SalesOperationsPlanningScenarios
	|Document.PurchasePlan.Read.PlanProfiles
	|Document.PurchasePlan.Read.PartnerGroups
	|Document.PurchasePlan.Read.Departments
	|Document.PurchasePlan.Read.Warehouses
	|Document.PurchasePlan.Read.SalesOperationsPlanningScenarios
	|Document.PurchasePlan.Update.PlanProfiles
	|Document.PurchasePlan.Update.PartnerGroups
	|Document.PurchasePlan.Update.Departments
	|Document.PurchasePlan.Update.Warehouses
	|Document.PurchasePlan.Update.SalesOperationsPlanningScenarios
	|Document.PlanOfGoodsStock.Read.PlanProfiles
	|Document.PlanOfGoodsStock.Read.Warehouses
	|Document.PlanOfGoodsStock.Read.SalesOperationsPlanningScenarios
	|Document.PlanOfGoodsStock.Update.PlanProfiles
	|Document.PlanOfGoodsStock.Update.Warehouses
	|Document.PlanOfGoodsStock.Update.SalesOperationsPlanningScenarios
	|Document.SalesPlan.Read.PlanProfiles
	|Document.SalesPlan.Read.ExternalUsers
	|Document.SalesPlan.Read.PartnerGroups
	|Document.SalesPlan.Read.Departments
	|Document.SalesPlan.Read.Warehouses
	|Document.SalesPlan.Read.SalesOperationsPlanningScenarios
	|Document.SalesPlan.Update.PlanProfiles
	|Document.SalesPlan.Update.ExternalUsers
	|Document.SalesPlan.Update.PartnerGroups
	|Document.SalesPlan.Update.Departments
	|Document.SalesPlan.Update.Warehouses
	|Document.SalesPlan.Update.SalesOperationsPlanningScenarios
	|Document.SalesPlanByCategories.Read.PlanProfiles
	|Document.SalesPlanByCategories.Read.Departments
	|Document.SalesPlanByCategories.Read.Warehouses
	|Document.SalesPlanByCategories.Read.SalesOperationsPlanningScenarios
	|Document.SalesPlanByCategories.Update.PlanProfiles
	|Document.SalesPlanByCategories.Update.Departments
	|Document.SalesPlanByCategories.Update.Warehouses
	|Document.SalesPlanByCategories.Update.SalesOperationsPlanningScenarios
	|Document.AssemblyDisassemblyPlan.Read.PlanProfiles
	|Document.AssemblyDisassemblyPlan.Read.Warehouses
	|Document.AssemblyDisassemblyPlan.Read.SalesOperationsPlanningScenarios
	|Document.AssemblyDisassemblyPlan.Update.PlanProfiles
	|Document.AssemblyDisassemblyPlan.Update.Warehouses
	|Document.AssemblyDisassemblyPlan.Update.SalesOperationsPlanningScenarios
	|Document.BankConfirmationAboutCashReceiptOnEmployeeAccount.Read.GroupsOfIndividuals
	|Document.BankConfirmationAboutCashReceiptOnEmployeeAccount.Read.Companies
	|Document.BankConfirmationAboutCashReceiptOnEmployeeAccount.Update.GroupsOfIndividuals
	|Document.BankConfirmationAboutCashReceiptOnEmployeeAccount.Update.Companies
	|Document.InstructionForShippingAgent.Read.PartnerGroups
	|Document.InstructionForShippingAgent.Read.GroupsOfIndividuals
	|Document.InstructionForShippingAgent.Read.Departments
	|Document.InstructionForShippingAgent.Read.Warehouses
	|Document.InstructionForShippingAgent.Update.PartnerGroups
	|Document.InstructionForShippingAgent.Update.GroupsOfIndividuals
	|Document.InstructionForShippingAgent.Update.Departments
	|Document.InstructionForShippingAgent.Update.Warehouses
	|Document.GoodsDamage.Read.Companies
	|Document.GoodsDamage.Read.Departments
	|Document.GoodsDamage.Read.Warehouses
	|Document.GoodsDamage.Update.Companies
	|Document.GoodsDamage.Update.Departments
	|Document.GoodsDamage.Update.Warehouses
	|Document.DamageAtCustodian.Read.PartnerGroups
	|Document.DamageAtCustodian.Read.Companies
	|Document.DamageAtCustodian.Read.Departments
	|Document.DamageAtCustodian.Read.BusinessTransactions
	|Document.DamageAtCustodian.Update.PartnerGroups
	|Document.DamageAtCustodian.Update.Companies
	|Document.DamageAtCustodian.Update.Departments
	|Document.DamageAtCustodian.Update.BusinessTransactions
	|Document.BankAccountReceiptNote.Read.PartnerGroups
	|Document.BankAccountReceiptNote.Read.Companies
	|Document.BankAccountReceiptNote.Read.BusinessTransactions
	|Document.BankAccountReceiptNote.Update.PartnerGroups
	|Document.BankAccountReceiptNote.Update.Companies
	|Document.BankAccountReceiptNote.Update.BusinessTransactions
	|Document.ReceiptOfGoodsToWarehouse.Read.PartnerGroups
	|Document.ReceiptOfGoodsToWarehouse.Read.Companies
	|Document.ReceiptOfGoodsToWarehouse.Read.Departments
	|Document.ReceiptOfGoodsToWarehouse.Read.Warehouses
	|Document.ReceiptOfGoodsToWarehouse.Update.PartnerGroups
	|Document.ReceiptOfGoodsToWarehouse.Update.Companies
	|Document.ReceiptOfGoodsToWarehouse.Update.Departments
	|Document.ReceiptOfGoodsToWarehouse.Update.Warehouses
	|Document.GoodsReceiptFromCustomer.Read.PartnerGroups
	|Document.GoodsReceiptFromCustomer.Read.Companies
	|Document.GoodsReceiptFromCustomer.Read.Departments
	|Document.GoodsReceiptFromCustomer.Read.Warehouses
	|Document.GoodsReceiptFromCustomer.Read.BusinessTransactions
	|Document.GoodsReceiptFromCustomer.Update.PartnerGroups
	|Document.GoodsReceiptFromCustomer.Update.Companies
	|Document.GoodsReceiptFromCustomer.Update.Departments
	|Document.GoodsReceiptFromCustomer.Update.Warehouses
	|Document.GoodsReceiptFromCustomer.Update.BusinessTransactions
	|Document.ReceiptOfGoodsFromCustodian.Read.PartnerGroups
	|Document.ReceiptOfGoodsFromCustodian.Read.Companies
	|Document.ReceiptOfGoodsFromCustodian.Read.Departments
	|Document.ReceiptOfGoodsFromCustodian.Read.BusinessTransactions
	|Document.ReceiptOfGoodsFromCustodian.Update.PartnerGroups
	|Document.ReceiptOfGoodsFromCustodian.Update.Companies
	|Document.ReceiptOfGoodsFromCustodian.Update.Departments
	|Document.ReceiptOfGoodsFromCustodian.Update.BusinessTransactions
	|Document.ReceiptOfServicesToBusinessUnit.Read.PartnerGroups
	|Document.ReceiptOfServicesToBusinessUnit.Read.Companies
	|Document.ReceiptOfServicesToBusinessUnit.Read.Departments
	|Document.ReceiptOfServicesToBusinessUnit.Update.PartnerGroups
	|Document.ReceiptOfServicesToBusinessUnit.Update.Companies
	|Document.ReceiptOfServicesToBusinessUnit.Update.Departments
	|Document.GoodsReceiptForStorage.Read.PartnerGroups
	|Document.GoodsReceiptForStorage.Read.Companies
	|Document.GoodsReceiptForStorage.Read.Departments
	|Document.GoodsReceiptForStorage.Read.Warehouses
	|Document.GoodsReceiptForStorage.Read.BusinessTransactions
	|Document.GoodsReceiptForStorage.Update.PartnerGroups
	|Document.GoodsReceiptForStorage.Update.Companies
	|Document.GoodsReceiptForStorage.Update.Departments
	|Document.GoodsReceiptForStorage.Update.Warehouses
	|Document.GoodsReceiptForStorage.Update.BusinessTransactions
	|Document.VendorInvoice.Read.PartnerGroups
	|Document.VendorInvoice.Read.Companies
	|Document.VendorInvoice.Read.Departments
	|Document.VendorInvoice.Read.Warehouses
	|Document.VendorInvoice.Update.PartnerGroups
	|Document.VendorInvoice.Update.Companies
	|Document.VendorInvoice.Update.Departments
	|Document.VendorInvoice.Update.Warehouses
	|Document.VendorInvoiceServicesAndAssets.Read.PartnerGroups
	|Document.VendorInvoiceServicesAndAssets.Read.Companies
	|Document.VendorInvoiceServicesAndAssets.Read.Departments
	|Document.VendorInvoiceServicesAndAssets.Update.PartnerGroups
	|Document.VendorInvoiceServicesAndAssets.Update.Companies
	|Document.VendorInvoiceServicesAndAssets.Update.Departments
	|Document.CashAccountReceiptNote.Read.PartnerGroups
	|Document.CashAccountReceiptNote.Read.GroupsOfIndividuals
	|Document.CashAccountReceiptNote.Read.CashAccounts
	|Document.CashAccountReceiptNote.Read.CashRegisters
	|Document.CashAccountReceiptNote.Read.Companies
	|Document.CashAccountReceiptNote.Read.BusinessTransactions
	|Document.CashAccountReceiptNote.Update.PartnerGroups
	|Document.CashAccountReceiptNote.Update.GroupsOfIndividuals
	|Document.CashAccountReceiptNote.Update.CashAccounts
	|Document.CashAccountReceiptNote.Update.CashRegisters
	|Document.CashAccountReceiptNote.Update.Companies
	|Document.CashAccountReceiptNote.Update.BusinessTransactions
	|Document.GoodsReceiptNote.Read.Warehouses
	|Document.GoodsReceiptNote.Update.Warehouses
	|Document.OtherGoodsRecordingAsReceived.Read.Companies
	|Document.OtherGoodsRecordingAsReceived.Read.Departments
	|Document.OtherGoodsRecordingAsReceived.Read.Warehouses
	|Document.OtherGoodsRecordingAsReceived.Update.Companies
	|Document.OtherGoodsRecordingAsReceived.Update.Departments
	|Document.OtherGoodsRecordingAsReceived.Update.Warehouses
	|Document.OtherIncomeExpenses.Read.Companies
	|Document.OtherIncomeExpenses.Update.Companies
	|Document.CashTransferReferenceOrder.Read.CashAccounts
	|Document.CashTransferReferenceOrder.Read.Companies
	|Document.CashTransferReferenceOrder.Read.BusinessTransactions
	|Document.CashTransferReferenceOrder.Update.CashAccounts
	|Document.CashTransferReferenceOrder.Update.Companies
	|Document.CashTransferReferenceOrder.Update.BusinessTransactions
	|Document.AllocationOfIncomeByLinesOfBusiness.Read.Companies
	|Document.AllocationOfIncomeByLinesOfBusiness.Update.Companies
	|Document.VATAllocation.Read.Companies
	|Document.VATAllocation.Update.Companies
	|Document.AllocationOfOtherCosts.Read.Companies
	|Document.AllocationOfOtherCosts.Read.Departments
	|Document.AllocationOfOtherCosts.Update.Companies
	|Document.AllocationOfOtherCosts.Update.Departments
	|Document.DeferredExpensesAllocation.Read.Companies
	|Document.DeferredExpensesAllocation.Update.Companies
	|Document.CashVoucher.Read.PartnerGroups
	|Document.CashVoucher.Read.GroupsOfIndividuals
	|Document.CashVoucher.Read.CashAccounts
	|Document.CashVoucher.Read.CashRegisters
	|Document.CashVoucher.Read.Companies
	|Document.CashVoucher.Read.Departments
	|Document.CashVoucher.Read.BusinessTransactions
	|Document.CashVoucher.Update.PartnerGroups
	|Document.CashVoucher.Update.GroupsOfIndividuals
	|Document.CashVoucher.Update.CashAccounts
	|Document.CashVoucher.Update.CashRegisters
	|Document.CashVoucher.Update.Companies
	|Document.CashVoucher.Update.Departments
	|Document.CashVoucher.Update.BusinessTransactions
	|Document.GoodsIssueNote.Read.Warehouses
	|Document.GoodsIssueNote.Update.Warehouses
	|Document.ExchangeDifferenceCalculation.Read.Companies
	|Document.ExchangeDifferenceCalculation.Update.Companies
	|Document.InventoryCostCalculation.Read.Companies
	|Document.InventoryCostCalculation.Update.Companies
	|Document.CustomerInvoice.Read.ExternalUsers
	|Document.CustomerInvoice.Read.PartnerGroups
	|Document.CustomerInvoice.Read.Companies
	|Document.CustomerInvoice.Read.Departments
	|Document.CustomerInvoice.Read.Warehouses
	|Document.CustomerInvoice.Update.PartnerGroups
	|Document.CustomerInvoice.Update.Companies
	|Document.CustomerInvoice.Update.Departments
	|Document.CustomerInvoice.Update.Warehouses
	|Document.CustomerInvoiceServicesAndAssets.Read.PartnerGroups
	|Document.CustomerInvoiceServicesAndAssets.Read.Companies
	|Document.CustomerInvoiceServicesAndAssets.Read.Departments
	|Document.CustomerInvoiceServicesAndAssets.Update.PartnerGroups
	|Document.CustomerInvoiceServicesAndAssets.Update.Companies
	|Document.CustomerInvoiceServicesAndAssets.Update.Departments
	|Document.VendorContractVendorAgreementRecorder.Read.PartnerGroups
	|Document.CostCalculationRecorder.Read.Companies
	|Document.VendorPriceList.Read.PartnerGroups
	|Document.VendorPriceList.Update.PartnerGroups
	|Document.Trip.Read.Companies
	|Document.Trip.Read.Warehouses
	|Document.Trip.Update.Companies
	|Document.Trip.Update.Warehouses
	|Document.AssemblyFromComponents.Read.Companies
	|Document.AssemblyFromComponents.Read.Warehouses
	|Document.AssemblyFromComponents.Update.Companies
	|Document.AssemblyFromComponents.Update.Warehouses
	|Document.ARAPReconciliation2_4.Read.PartnerGroups
	|Document.ARAPReconciliation2_4.Read.Companies
	|Document.ARAPReconciliation2_4.Update.PartnerGroups
	|Document.ARAPReconciliation2_4.Update.Companies
	|Document.ARAPReconciliation2_5_11.Read.PartnerGroups
	|Document.ARAPReconciliation2_5_11.Read.Companies
	|Document.ARAPReconciliation2_5_11.Update.PartnerGroups
	|Document.ARAPReconciliation2_5_11.Update.Companies
	|Document.ReconcileOpeningBalancesByWarehouses.Read.Companies
	|Document.ReconcileOpeningBalancesByWarehouses.Read.Warehouses
	|Document.ReconcileOpeningBalancesByWarehouses.Update.Companies
	|Document.ReconcileOpeningBalancesByWarehouses.Update.Warehouses
	|Document.SMSMessage.Read.Object.Document.SMSMessage
	|Document.SMSMessage.Update.Object.Document.SMSMessage
	|Document.BankAccountIssue.Read.PartnerGroups
	|Document.BankAccountIssue.Read.GroupsOfIndividuals
	|Document.BankAccountIssue.Read.Companies
	|Document.BankAccountIssue.Read.BusinessTransactions
	|Document.BankAccountIssue.Update.PartnerGroups
	|Document.BankAccountIssue.Update.GroupsOfIndividuals
	|Document.BankAccountIssue.Update.Companies
	|Document.BankAccountIssue.Update.BusinessTransactions
	|Document.VATWritingOffAsExpenses.Read.Companies
	|Document.VATWritingOffAsExpenses.Update.Companies
	|Document.WriteOffOfGoodsShortages.Read.Companies
	|Document.WriteOffOfGoodsShortages.Read.Departments
	|Document.WriteOffOfGoodsShortages.Read.Warehouses
	|Document.WriteOffOfGoodsShortages.Update.Companies
	|Document.WriteOffOfGoodsShortages.Update.Departments
	|Document.WriteOffOfGoodsShortages.Update.Warehouses
	|Document.WriteOffOfShippedGoods.Read.PartnerGroups
	|Document.WriteOffOfShippedGoods.Read.Companies
	|Document.WriteOffOfShippedGoods.Read.Departments
	|Document.WriteOffOfShippedGoods.Read.BusinessTransactions
	|Document.WriteOffOfShippedGoods.Update.PartnerGroups
	|Document.WriteOffOfShippedGoods.Update.Companies
	|Document.WriteOffOfShippedGoods.Update.Departments
	|Document.WriteOffOfShippedGoods.Update.BusinessTransactions
	|Document.WriteOffDiscrepanciesBetweenReceiptAndPurchase.Read.PartnerGroups
	|Document.WriteOffDiscrepanciesBetweenReceiptAndPurchase.Read.Companies
	|Document.WriteOffDiscrepanciesBetweenReceiptAndPurchase.Read.Departments
	|Document.WriteOffDiscrepanciesBetweenReceiptAndPurchase.Read.Warehouses
	|Document.WriteOffDiscrepanciesBetweenReceiptAndPurchase.Update.PartnerGroups
	|Document.WriteOffDiscrepanciesBetweenReceiptAndPurchase.Update.Companies
	|Document.WriteOffDiscrepanciesBetweenReceiptAndPurchase.Update.Departments
	|Document.WriteOffDiscrepanciesBetweenReceiptAndPurchase.Update.Warehouses
	|Document.DebitCustomerRebates.Read.Companies
	|Document.DebitCustomerRebates.Update.Companies
	|Document.WriteOffVendorRebates.Read.Companies
	|Document.WriteOffVendorRebates.Update.Companies
	|Document.ReversingEntry.Read.Companies
	|Document.ReversingEntry.Update.Companies
	|Document.CustomerCommercialInvoice.Read.ExternalUsers
	|Document.CustomerCommercialInvoice.Read.PartnerGroups
	|Document.CustomerCommercialInvoice.Read.Companies
	|Document.CustomerCommercialInvoice.Update.PartnerGroups
	|Document.CustomerCommercialInvoice.Update.Companies
	|Document.IssuedTaxInvoicePrepayment.Read.Companies
	|Document.IssuedTaxInvoicePrepayment.Update.Companies
	|Document.ReceivedTaxInvoicePrepayment.Read.Companies
	|Document.ReceivedTaxInvoicePrepayment.Update.Companies
	|Document.CCDImport.Read.PartnerGroups
	|Document.CCDImport.Read.Companies
	|Document.CCDImport.Read.Departments
	|Document.CCDImport.Update.PartnerGroups
	|Document.CCDImport.Update.Companies
	|Document.CCDImport.Update.Departments
	|Document.PhoneCall.Read.Object.Document.PhoneCall
	|Document.PhoneCall.Update.Object.Document.PhoneCall
	|Document.ConditionsOfCustomerRebates.Read.Companies
	|Document.ConditionsOfCustomerRebates.Update.Companies
	|Document.ConditionsOfVendorRebates.Read.Companies
	|Document.ConditionsOfVendorRebates.Update.Companies
	|Document.SetStorageBinLocks.Read.Warehouses
	|Document.SetStorageBinLocks.Update.Warehouses
	|Document.PriceSetup.Read.Object.Document.PriceSetup
	|Document.PriceSetup.Update.Object.Document.PriceSetup
	|Document.CashRegisterReceipt.Read.CashRegisters
	|Document.CashRegisterReceipt.Read.Companies
	|Document.CashRegisterReceipt.Read.Warehouses
	|Document.CashRegisterReceipt.Update.CashRegisters
	|Document.CashRegisterReceipt.Update.Companies
	|Document.CashRegisterReceipt.Update.Warehouses
	|Document.CashRegisterReceiptReturn.Read.CashRegisters
	|Document.CashRegisterReceiptReturn.Read.Companies
	|Document.CashRegisterReceiptReturn.Read.Warehouses
	|Document.CashRegisterReceiptReturn.Update.CashRegisters
	|Document.CashRegisterReceiptReturn.Update.Companies
	|Document.CashRegisterReceiptReturn.Update.Warehouses
	|Document.ReceiptOfCashRegisterAdjustment.Read.CashRegisters
	|Document.ReceiptOfCashRegisterAdjustment.Read.Companies
	|Document.ReceiptOfCashRegisterAdjustment.Read.Warehouses
	|Document.ReceiptOfCashRegisterAdjustment.Update.CashRegisters
	|Document.ReceiptOfCashRegisterAdjustment.Update.Companies
	|Document.ReceiptOfCashRegisterAdjustment.Update.Warehouses
	|Document.IncomingEmail.Read.Object.Document.IncomingEmail
	|Document.IncomingEmail.Update.Object.Document.IncomingEmail
	|Document.OutgoingEmail.Read.Object.Document.OutgoingEmail
	|Document.OutgoingEmail.Update.Object.Document.OutgoingEmail
	|DocumentJournal.Interactions.Read.Object.Document.Meeting
	|DocumentJournal.Interactions.Read.Object.Document.PlannedInteraction
	|DocumentJournal.Interactions.Read.Object.Document.SMSMessage
	|DocumentJournal.Interactions.Read.Object.Document.PhoneCall
	|DocumentJournal.Interactions.Read.Object.Document.IncomingEmail
	|DocumentJournal.Interactions.Read.Object.Document.OutgoingEmail
	|DocumentJournal.ARAPReconciliations.Read.PartnerGroups
	|DocumentJournal.ARAPReconciliations.Read.Companies
	|DocumentJournal.GoodsReceiptIssue.Read.Warehouses
	|DocumentJournal.SurplusesShortagesAndDamageOfGoods.Read.Warehouses
	|DocumentJournal.CashRegisterReceipts.Read.CashRegisters
	|DocumentJournal.CashRegisterReceipts.Read.Companies
	|DocumentJournal.CashRegisterReceipts.Read.Warehouses
	|ChartOfCharacteristicTypes.AdditionalAttributesAndInfo.Read.AdditionalInfo
	|InformationRegister.ABCXYZCustomerClassification.Read.PartnerGroups
	|InformationRegister.ABCXYZCustomerClassification.Update.PartnerGroups
	|InformationRegister.ABCXYZInventoryClassification.Update.ProductGroups
	|InformationRegister.GoodsProcurementStrategy.Read.Warehouses
	|InformationRegister.GoodsProcurementStrategy.Update.Warehouses
	|InformationRegister.ScheduleOfPayments.Read.Companies
	|InformationRegister.BusinessProcessesData.Read.Object.BusinessProcess.Job
	|InformationRegister.BusinessProcessesData.Read.Object.BusinessProcess.ApprovalOfInventoryConsumptionOrder
	|InformationRegister.BusinessProcessesData.Read.Object.BusinessProcess.PurchaseApproval
	|InformationRegister.BusinessProcessesData.Read.Object.BusinessProcess.ApprovalOfRequestForReturnOfGoodsFromCustomer
	|InformationRegister.BusinessProcessesData.Read.Object.BusinessProcess.SaleApproval
	|InformationRegister.BusinessProcessesData.Read.Object.BusinessProcess.PriceApproval
	|InformationRegister.BusinessProcessesData.Read.Object.BusinessProcess.StandardSale
	|InformationRegister.SourceDocumentsData.Read.Companies
	|InformationRegister.DatesOfConsignmentGoodsTransfer.Read.Companies
	|InformationRegister.ItemizeGoodsLotCost.Read.Companies
	|InformationRegister.ItemizeLotCostItemizedAndOtherCosts.Read.Companies
	|InformationRegister.ItemizeGoodsCostItemizedAndOtherCosts.Read.Companies
	|InformationRegister.DocumentsPersons.Read.PartnerGroups
	|InformationRegister.DocumentsPersons.Read.GroupsOfIndividuals
	|InformationRegister.DocumentsPersons.Update.PartnerGroups
	|InformationRegister.DocumentsPersons.Update.GroupsOfIndividuals
	|InformationRegister.AdditionalInfo.Read.AdditionalInfo
	|InformationRegister.AdditionalInfo.Update.AdditionalInfo
	|InformationRegister.GoodsAvailabilityForExternalUsers.Read.Warehouses
	|InformationRegister.AvailableStockBalances.Read.Warehouses
	|InformationRegister.CompletedConditionsOfVendorRebates.Read.Companies
	|InformationRegister.CompletedConditionsOfVendorRebatesHistory.Read.Companies
	|InformationRegister.JobsForAllocatingInventory.Read.Departments
	|InformationRegister.JobsForAllocatingInventory.Read.Warehouses
	|InformationRegister.JobsForAllocatingCustomersARAP.Read.PartnerGroups
	|InformationRegister.JobsForAllocatingCustomersARAP.Read.Companies
	|InformationRegister.JobsForAllocatingVendorsARAP.Read.PartnerGroups
	|InformationRegister.JobsForAllocatingVendorsARAP.Read.Companies
	|InformationRegister.SourcesOfInitialRequests.Read.PartnerGroups
	|InformationRegister.CustomerShoppingCart.Read.ExternalUsers
	|InformationRegister.SetUpSupplyControl.Read.Warehouses
	|InformationRegister.SetUpSupplyControl.Update.Warehouses
	|InformationRegister.CustomizeCustomerInvoiceIntercompany.Read.Companies
	|InformationRegister.SettingsOfBinLocationWarehouses.Read.Warehouses
	|InformationRegister.SettingsOfBinLocationWarehouses.Update.Warehouses
	|InformationRegister.TaxationSystemSettings.Read.Companies
	|InformationRegister.VATAccountingSettings.Read.Companies
	|InformationRegister.EmailAccountSettings.Read.Users
	|InformationRegister.EmailAccountSettings.Read.EmailAccounts
	|InformationRegister.BankAccountBalanceAccordingToStatementData.Read.Companies
	|InformationRegister.InventoryAdjustmentSurplusesAndShortagesGenerationQueue.Read.Warehouses
	|InformationRegister.LotAndCostCalculationErrors.Read.Companies
	|InformationRegister.SegmentPartners.Read.ExternalUsers
	|InformationRegister.SegmentPartners.Read.PartnerGroups
	|InformationRegister.SegmentPartners.Update.PartnerGroups
	|InformationRegister.GoodsPlacementRules.Read.Warehouses
	|InformationRegister.GoodsPlacementRules.Update.Warehouses
	|InformationRegister.InteractionsFolderSubjects.Update.Object.Document.Meeting
	|InformationRegister.InteractionsFolderSubjects.Update.Object.Document.PlannedInteraction
	|InformationRegister.InteractionsFolderSubjects.Update.Object.Document.SMSMessage
	|InformationRegister.InteractionsFolderSubjects.Update.Object.Document.PhoneCall
	|InformationRegister.InteractionsFolderSubjects.Update.Object.Document.IncomingEmail
	|InformationRegister.InteractionsFolderSubjects.Update.Object.Document.OutgoingEmail
	|InformationRegister.PackageConsumptionForecasts.Read.Warehouses
	|InformationRegister.PackageConsumptionForecasts.Update.Warehouses
	|InformationRegister.PlaceProductsInStorageBins.Read.Warehouses
	|InformationRegister.PlaceProductsInStorageBins.Update.Warehouses
	|InformationRegister.InventoryAllocation.Read.Departments
	|InformationRegister.InventoryAllocation.Read.Warehouses
	|InformationRegister.CalculationOfPlanShortagesByStages.Read.PlanProfiles
	|InformationRegister.CalculationOfPlanShortagesByStages.Read.SalesOperationsPlanningScenarios
	|InformationRegister.DocumentsRegistry.Read.PartnerGroups
	|InformationRegister.DocumentsRegistry.Read.GroupsOfIndividuals
	|InformationRegister.DocumentsRegistry.Read.CashAccounts
	|InformationRegister.DocumentsRegistry.Read.Companies
	|InformationRegister.DocumentsRegistry.Read.Departments
	|InformationRegister.DocumentsRegistry.Read.Warehouses
	|InformationRegister.DocumentsRegistry.Read.BusinessTransactions
	|InformationRegister.CustomerRebatesContractsTermsOfSales.Read.Companies
	|InformationRegister.CustomerRebatesTIN.Read.Companies
	|InformationRegister.CustomerRebatesCounterparties.Read.Companies
	|InformationRegister.CustomerRebatesAccrualPeriods.Read.Companies
	|InformationRegister.CustomerRebatesItemProperties.Read.Companies
	|InformationRegister.CustomerRebatesPartnerSegments.Read.Companies
	|InformationRegister.CustomerRebatesItemSegments.Read.Companies
	|InformationRegister.CustomerRebatesItems.Read.Companies
	|InformationRegister.CustomerRebatesConditions.Read.Companies
	|InformationRegister.VendorRebatesTIN.Read.Companies
	|InformationRegister.VendorRebatesCounterparties.Read.Companies
	|InformationRegister.VendorRebatesVendors.Read.Companies
	|InformationRegister.VendorRebatesItemProperties.Read.Companies
	|InformationRegister.VendorRebatesGoodsSegments.Read.Companies
	|InformationRegister.VendorRebatesWarehouses.Read.Companies
	|InformationRegister.VendorRebatesGoods.Read.Companies
	|InformationRegister.VendorRebatesConditions.Read.Companies
	|InformationRegister.RebatesCalculationScales.Read.Companies
	|InformationRegister.RelationshipsBetweenPartners.Read.PartnerGroups
	|InformationRegister.RelationshipsBetweenPartners.Update.PartnerGroups
	|InformationRegister.UserGroupCompositions.Read.ExternalUsers
	|InformationRegister.UserGroupCompositions.Read.Users
	|InformationRegister.StatesAndDetailsOfDelivery.Read.Warehouses
	|InformationRegister.DiscountRates.Read.Companies
	|InformationRegister.GoodsCost.Read.Companies
	|InformationRegister.SupplySchemes.Read.Warehouses
	|InformationRegister.SupplySchemes.Update.Warehouses
	|InformationRegister.ProductRestrictions.Read.Warehouses
	|InformationRegister.ProductRestrictions.Update.Warehouses
	|InformationRegister.FinancialAccountingPolicy.Read.Companies
	|InformationRegister.FullNameOfPersons.Read.GroupsOfIndividuals
	|InformationRegister.FullNameOfPersons.Update.GroupsOfIndividuals
	|InformationRegister.ItemsPrices.Read.TypesOfPrices
	|InformationRegister.ItemsPrices25.Read.TypesOfPrices
	|InformationRegister.ItemsPricesOfVendor.Read.PartnerGroups
	|InformationRegister.ItemsBarcodes.Update.ProductGroups
	|AccumulationRegister.RevenueAndCOGS.Read.PartnerGroups
	|AccumulationRegister.RevenueAndCOGS.Read.Companies
	|AccumulationRegister.RevenueAndCOGS.Read.Departments
	|AccumulationRegister.RecordsCashIncomeExpenses.Read.GroupsOfIndividuals
	|AccumulationRegister.RecordsCashIncomeExpenses.Read.CashAccounts
	|AccumulationRegister.RecordsCashIncomeExpenses.Read.CashRegisters
	|AccumulationRegister.RecordsCashIncomeExpenses.Read.Companies
	|AccumulationRegister.RecordsCashIncomeExpenses.Read.Departments
	|AccumulationRegister.RecordsCashCounterparty.Read.PartnerGroups
	|AccumulationRegister.RecordsCashCounterparty.Read.GroupsOfIndividuals
	|AccumulationRegister.RecordsCashCounterparty.Read.CashAccounts
	|AccumulationRegister.RecordsCashCounterparty.Read.CashRegisters
	|AccumulationRegister.RecordsCashCounterparty.Read.Companies
	|AccumulationRegister.RecordsCashCounterparty.Read.Departments
	|AccumulationRegister.CashFlow.Read.GroupsOfIndividuals
	|AccumulationRegister.CashFlow.Read.CashAccounts
	|AccumulationRegister.CashFlow.Read.CashRegisters
	|AccumulationRegister.CashFlow.Read.Companies
	|AccumulationRegister.CashFlow.Read.Departments
	|AccumulationRegister.RecordsIncomeExpensesOtherAssetsLiabilities.Read.Companies
	|AccumulationRegister.RecordsIncomeExpensesOtherAssetsLiabilities.Read.Departments
	|AccumulationRegister.RecordsCounterpartyIncomeExpenses.Read.PartnerGroups
	|AccumulationRegister.RecordsCounterpartyIncomeExpenses.Read.Companies
	|AccumulationRegister.RecordsCounterpartyIncomeExpenses.Read.Departments
	|AccumulationRegister.RecordsCounterpartyCounterparty.Read.PartnerGroups
	|AccumulationRegister.RecordsCounterpartyCounterparty.Read.Companies
	|AccumulationRegister.RecordsCounterpartyCounterparty.Read.Departments
	|AccumulationRegister.RegisterRecordsProductsIncomeExpenses.Read.Companies
	|AccumulationRegister.RecordsProductsProducts.Read.Companies
	|AccumulationRegister.RegisterRecordsByExcises.Read.Companies
	|AccumulationRegister.VATRegisterRecords.Read.Companies
	|AccumulationRegister.OtherAssetsAndLiabilitiesRecords.Read.Companies
	|AccumulationRegister.GoodsBatchMovement.Read.Warehouses
	|AccumulationRegister.BankAccountCash.Read.Companies
	|AccumulationRegister.CashInCashRegistersCR.Read.CashRegisters
	|AccumulationRegister.CashInCashRegistersCR.Read.Companies
	|AccumulationRegister.CashInTransit.Read.CashAccounts
	|AccumulationRegister.CashInTransit.Read.Companies
	|AccumulationRegister.CashToBePaid.Read.Companies
	|AccumulationRegister.CashAccountBalance.Read.CashAccounts
	|AccumulationRegister.CashAccountBalance.Read.Companies
	|AccumulationRegister.AdvanceHolderCash.Read.GroupsOfIndividuals
	|AccumulationRegister.AdvanceHolderCash.Read.Companies
	|AccumulationRegister.Delivery.Read.PartnerGroups
	|AccumulationRegister.Delivery.Read.Companies
	|AccumulationRegister.Delivery.Read.Warehouses
	|AccumulationRegister.InventoryConsumptionOrders.Read.Companies
	|AccumulationRegister.InventoryConsumptionOrders.Read.Departments
	|AccumulationRegister.InventoryConsumptionOrders.Read.Warehouses
	|AccumulationRegister.TransferOrders.Read.Companies
	|AccumulationRegister.TransferOrders.Read.Warehouses
	|AccumulationRegister.AssemblyOrders.Read.Companies
	|AccumulationRegister.AssemblyOrders.Read.Warehouses
	|AccumulationRegister.PurchaseOrders.Read.PartnerGroups
	|AccumulationRegister.PurchaseOrders.Read.Companies
	|AccumulationRegister.PurchaseOrders.Read.Warehouses
	|AccumulationRegister.Purchases.Read.PartnerGroups
	|AccumulationRegister.Purchases.Read.Companies
	|AccumulationRegister.Purchases.Read.Departments
	|AccumulationRegister.Purchases.Read.Warehouses
	|AccumulationRegister.InventoryAndDemands.Read.Departments
	|AccumulationRegister.InventoryAndDemands.Read.Warehouses
	|AccumulationRegister.AdjustmentsToPlannedDemands.Read.PlanProfiles
	|AccumulationRegister.AdjustmentsToPlannedDemands.Read.SalesOperationsPlanningScenarios
	|AccumulationRegister.CashFlowLimits.Read.Companies
	|AccumulationRegister.CashFlowLimits.Read.Departments
	|AccumulationRegister.MaterialsAndWorksInProduction.Read.Companies
	|AccumulationRegister.VATPrepaymentsToVendor.Read.Companies
	|AccumulationRegister.VATPrepaymentsFromCustomer.Read.Companies
	|AccumulationRegister.VATInvoiced.Read.Companies
	|AccumulationRegister.GoodsCostVariances.Read.Companies
	|AccumulationRegister.ItemisedExpensesLots.Read.Companies
	|AccumulationRegister.TransferredReturnablePackaging.Read.PartnerGroups
	|AccumulationRegister.TransferredReturnablePackaging.Read.Companies
	|AccumulationRegister.TransferredReturnablePackaging.Read.Warehouses
	|AccumulationRegister.InventoryConsumptionPlans.Read.PlanProfiles
	|AccumulationRegister.InventoryConsumptionPlans.Read.Departments
	|AccumulationRegister.InventoryConsumptionPlans.Read.Warehouses
	|AccumulationRegister.InventoryConsumptionPlans.Read.SalesOperationsPlanningScenarios
	|AccumulationRegister.PurchasePlans.Read.PlanProfiles
	|AccumulationRegister.PurchasePlans.Read.PartnerGroups
	|AccumulationRegister.PurchasePlans.Read.Departments
	|AccumulationRegister.PurchasePlans.Read.Warehouses
	|AccumulationRegister.PurchasePlans.Read.SalesOperationsPlanningScenarios
	|AccumulationRegister.CashFlowPlansCustomers.Read.PartnerGroups
	|AccumulationRegister.CashFlowPlansCustomers.Read.SalesOperationsPlanningScenarios
	|AccumulationRegister.CashFlowPlansVendors.Read.PartnerGroups
	|AccumulationRegister.CashFlowPlansVendors.Read.SalesOperationsPlanningScenarios
	|AccumulationRegister.PlansOfGoodsStock.Read.PlanProfiles
	|AccumulationRegister.PlansOfGoodsStock.Read.Warehouses
	|AccumulationRegister.PlansOfGoodsStock.Read.SalesOperationsPlanningScenarios
	|AccumulationRegister.ComponentsConsumptionPlans.Read.PlanProfiles
	|AccumulationRegister.ComponentsConsumptionPlans.Read.Warehouses
	|AccumulationRegister.ComponentsConsumptionPlans.Read.SalesOperationsPlanningScenarios
	|AccumulationRegister.SalesPlans.Read.PlanProfiles
	|AccumulationRegister.SalesPlans.Read.PartnerGroups
	|AccumulationRegister.SalesPlans.Read.Departments
	|AccumulationRegister.SalesPlans.Read.Warehouses
	|AccumulationRegister.SalesPlans.Read.SalesOperationsPlanningScenarios
	|AccumulationRegister.SalesPlansByCategories.Read.PlanProfiles
	|AccumulationRegister.SalesPlansByCategories.Read.Departments
	|AccumulationRegister.SalesPlansByCategories.Read.Warehouses
	|AccumulationRegister.SalesPlansByCategories.Read.SalesOperationsPlanningScenarios
	|AccumulationRegister.AssemblyDisassemblyPlans.Read.PlanProfiles
	|AccumulationRegister.AssemblyDisassemblyPlans.Read.Warehouses
	|AccumulationRegister.AssemblyDisassemblyPlans.Read.SalesOperationsPlanningScenarios
	|AccumulationRegister.ReceivedReturnablePackaging.Read.PartnerGroups
	|AccumulationRegister.ReceivedReturnablePackaging.Read.Companies
	|AccumulationRegister.ReceivedReturnablePackaging.Read.Warehouses
	|AccumulationRegister.DiscountInterestExpense.Read.PartnerGroups
	|AccumulationRegister.DiscountInterestExpense.Read.Companies
	|AccumulationRegister.RevenueServicesAndAssets.Read.PartnerGroups
	|AccumulationRegister.RevenueServicesAndAssets.Read.Companies
	|AccumulationRegister.RevenueServicesAndAssets.Read.Departments
	|AccumulationRegister.OtherAssetsLiabilities.Read.Companies
	|AccumulationRegister.OtherIncome.Read.Companies
	|AccumulationRegister.OtherIncome.Read.Departments
	|AccumulationRegister.OtherExpenses.Read.Companies
	|AccumulationRegister.OtherExpenses.Read.Departments
	|AccumulationRegister.ShipmentAndReturnReferences.Read.ExternalUsers
	|AccumulationRegister.ShipmentAndReturnReferences.Read.PartnerGroups
	|AccumulationRegister.ShipmentAndReturnReferences.Read.Companies
	|AccumulationRegister.ShipmentAndReturnReferences.Read.Warehouses
	|AccumulationRegister.FinancialInstrumentsARAP.Read.Companies
	|AccumulationRegister.AcquiringContractARAP.Read.Companies
	|AccumulationRegister.AcquiringContractARAP.Read.POSTerminals
	|AccumulationRegister.CustomersARAPAccounting.Read.ExternalUsers
	|AccumulationRegister.CustomersARAPAccounting.Read.PartnerGroups
	|AccumulationRegister.CustomersARAPAccounting.Read.Companies
	|AccumulationRegister.CustomersARAPAccountingCashFlowPlan.Read.ExternalUsers
	|AccumulationRegister.CustomersARAPAccountingCashFlowPlan.Read.PartnerGroups
	|AccumulationRegister.CustomersARAPAccountingCashFlowPlan.Read.Companies
	|AccumulationRegister.CustomersARAPAccountingPlannedShipments.Read.ExternalUsers
	|AccumulationRegister.CustomersARAPAccountingPlannedShipments.Read.PartnerGroups
	|AccumulationRegister.CustomersARAPAccountingPlannedShipments.Read.Companies
	|AccumulationRegister.CustomersARAPAccountingByDocuments.Read.PartnerGroups
	|AccumulationRegister.CustomersARAPAccountingByDocuments.Read.Companies
	|AccumulationRegister.CustomersARAPAccountingByDueDates.Read.ExternalUsers
	|AccumulationRegister.CustomersARAPAccountingByDueDates.Read.PartnerGroups
	|AccumulationRegister.CustomersARAPAccountingByDueDates.Read.Companies
	|AccumulationRegister.VendorsARAPAccounting.Read.PartnerGroups
	|AccumulationRegister.VendorsARAPAccounting.Read.Companies
	|AccumulationRegister.VendorsARAPAccountingCashFlowPlan.Read.PartnerGroups
	|AccumulationRegister.VendorsARAPAccountingCashFlowPlan.Read.Companies
	|AccumulationRegister.VendorsARAPAccountingPlannedDeliveries.Read.PartnerGroups
	|AccumulationRegister.VendorsARAPAccountingPlannedDeliveries.Read.Companies
	|AccumulationRegister.VendorsARAPAccountingByDocuments.Read.PartnerGroups
	|AccumulationRegister.VendorsARAPAccountingByDocuments.Read.Companies
	|AccumulationRegister.VendorsARAPAccountingByDueDates.Read.PartnerGroups
	|AccumulationRegister.VendorsARAPAccountingByDueDates.Read.Companies
	|AccumulationRegister.CompanySafeStock.Read.Companies
	|AccumulationRegister.CustomerRebates.Read.Companies
	|AccumulationRegister.VendorRebates.Read.Companies
	|AccumulationRegister.InventoryCost.Read.Companies
	|AccumulationRegister.CargoItemsForRecordingSurplusesAndShortages.Read.Warehouses
	|AccumulationRegister.GoodsInStorageBins.Read.Warehouses
	|AccumulationRegister.GoodsForIssue.Read.Warehouses
	|AccumulationRegister.GoodsForRegistrationOfImportDocuments.Read.PartnerGroups
	|AccumulationRegister.GoodsForRegistrationOfImportDocuments.Read.Companies
	|AccumulationRegister.GoodsForRegistrationOfSurplusesAndShortages.Read.Warehouses
	|AccumulationRegister.GoodsToBeRegisteredInReportsToConsignor.Read.PartnerGroups
	|AccumulationRegister.GoodsToBeRegisteredInReportsToConsignor.Read.Companies
	|AccumulationRegister.GoodsToReceive.Read.Warehouses
	|AccumulationRegister.ProductStock.Read.Warehouses
	|AccumulationRegister.CompanyGoods.Read.Companies
	|AccumulationRegister.CompanyGoodsForTransfer.Read.Companies
	|AccumulationRegister.GoodsTransferredToCommissionAgent.Read.Companies
	|AccumulationRegister.ServicesForRegistrationOfReportsToPrincipal.Read.PartnerGroups
	|AccumulationRegister.ServicesForRegistrationOfReportsToPrincipal.Read.Companies
	|AccumulationRegister.FinancialResults.Read.Companies
	|AccumulationRegister.FinancialResults.Read.Departments
	|BusinessProcess.Job.Read.Users
	|BusinessProcess.Job.Update.Users
	|BusinessProcess.PriceApproval.Update.Users
	|BusinessProcess.StandardSale.Read.PartnerGroups
	|BusinessProcess.StandardSale.Read.Users
	|BusinessProcess.StandardSale.Update.PartnerGroups
	|BusinessProcess.StandardSale.Update.Users
	|Task.PerformerTask.Read.Object.BusinessProcess.Job
	|Task.PerformerTask.Read.Object.BusinessProcess.ApprovalOfInventoryConsumptionOrder
	|Task.PerformerTask.Read.Object.BusinessProcess.PurchaseApproval
	|Task.PerformerTask.Read.Object.BusinessProcess.ApprovalOfRequestForReturnOfGoodsFromCustomer
	|Task.PerformerTask.Read.Object.BusinessProcess.SaleApproval
	|Task.PerformerTask.Read.Object.BusinessProcess.PriceApproval
	|Task.PerformerTask.Read.Object.BusinessProcess.StandardSale
	|Task.PerformerTask.Read.Users
	|Task.PerformerTask.Update.Users
	|Catalog.InternalAcceptanceCertificateAttachedFiles.Read.Companies
	|Catalog.InternalAcceptanceCertificateAttachedFiles.Read.Departments
	|Catalog.InternalAcceptanceCertificateAttachedFiles.Read.StatusesOfInternalAcceptanceCertificate
	|Catalog.InternalAcceptanceCertificateAttachedFiles.Update.Companies
	|Catalog.InternalAcceptanceCertificateAttachedFiles.Update.Departments
	|Catalog.InternalAcceptanceCertificateAttachedFiles.Update.StatusesOfInternalAcceptanceCertificate
	|Catalog.BudgetProfiles.Read.GroupsOfBudgetTypes
	|Catalog.BudgetProfiles.Read.GroupsOfBudgetItemsAndIndicators
	|Catalog.BudgetProfiles.Update.GroupsOfBudgetTypes
	|Catalog.BudgetProfiles.Update.GroupsOfBudgetItemsAndIndicators
	|Catalog.MovementOfProductsAndMaterialsAttachedFiles.Read.Companies
	|Catalog.MovementOfProductsAndMaterialsAttachedFiles.Read.Departments
	|Catalog.MovementOfProductsAndMaterialsAttachedFiles.Read.Warehouses
	|Catalog.MovementOfProductsAndMaterialsAttachedFiles.Read.StatusesOfRegisteredRecordsOfProductsAndMaterials
	|Catalog.MovementOfProductsAndMaterialsAttachedFiles.Read.BusinessTransactions
	|Catalog.MovementOfProductsAndMaterialsAttachedFiles.Update.Companies
	|Catalog.MovementOfProductsAndMaterialsAttachedFiles.Update.Departments
	|Catalog.MovementOfProductsAndMaterialsAttachedFiles.Update.Warehouses
	|Catalog.MovementOfProductsAndMaterialsAttachedFiles.Update.StatusesOfRegisteredRecordsOfProductsAndMaterials
	|Catalog.MovementOfProductsAndMaterialsAttachedFiles.Update.BusinessTransactions
	|Catalog.LeaseContract.Read.PartnerGroups
	|Catalog.LeaseContract.Read.Companies
	|Catalog.LeaseContract.Update.PartnerGroups
	|Catalog.LeaseContract.Update.Companies
	|Catalog.LeaseContractAttachedFiles.Read.PartnerGroups
	|Catalog.LeaseContractAttachedFiles.Read.Companies
	|Catalog.LeaseContractAttachedFiles.Update.PartnerGroups
	|Catalog.LeaseContractAttachedFiles.Update.Companies
	|Catalog.DocumentsFAAttachedFiles.Read.Companies
	|Catalog.DocumentsFAAttachedFiles.Update.Companies
	|Catalog.OrderOfMaterialsForProductionAttachedFiles.Read.Companies
	|Catalog.OrderOfMaterialsForProductionAttachedFiles.Read.Departments
	|Catalog.OrderOfMaterialsForProductionAttachedFiles.Read.Warehouses
	|Catalog.OrderOfMaterialsForProductionAttachedFiles.Update.Companies
	|Catalog.OrderOfMaterialsForProductionAttachedFiles.Update.Departments
	|Catalog.OrderOfMaterialsForProductionAttachedFiles.Update.Warehouses
	|Catalog.SubcontractOrder2_5AttachedFiles.Read.PartnerGroups
	|Catalog.SubcontractOrder2_5AttachedFiles.Read.Companies
	|Catalog.SubcontractOrder2_5AttachedFiles.Read.Departments
	|Catalog.SubcontractOrder2_5AttachedFiles.Read.Warehouses
	|Catalog.SubcontractOrder2_5AttachedFiles.Update.PartnerGroups
	|Catalog.SubcontractOrder2_5AttachedFiles.Update.Companies
	|Catalog.SubcontractOrder2_5AttachedFiles.Update.Departments
	|Catalog.SubcontractOrder2_5AttachedFiles.Update.Warehouses
	|Catalog.AccrualAndWriteOffOfBadDebtAlowancesAttachedFiles.Read.Companies
	|Catalog.AccrualAndWriteOffOfBadDebtAlowancesAttachedFiles.Update.Companies
	|Catalog.FutureExpenseCommitmentsAccrualWriteOffAttachedFiles.Read.Companies
	|Catalog.FutureExpenseCommitmentsAccrualWriteOffAttachedFiles.Update.Companies
	|Catalog.NonFinancialItemsOfBudgets.Read.GroupsOfBudgetItemsAndIndicators
	|Catalog.NonFinancialItemsOfBudgets.Update.GroupsOfBudgetItemsAndIndicators
	|Catalog.AccountingObjectsOfFutureExpenseCommitments.Read.Companies
	|Catalog.AccountingObjectsOfFutureExpenseCommitments.Update.Companies
	|Catalog.PostingPayrollExpensesInFinancialAccounting2_5AttachedFiles.Read.Companies
	|Catalog.PostingPayrollExpensesInFinancialAccounting2_5AttachedFiles.Update.Companies
	|Catalog.SubcontractorReport2_5AttachedFiles.Read.PartnerGroups
	|Catalog.SubcontractorReport2_5AttachedFiles.Read.Companies
	|Catalog.SubcontractorReport2_5AttachedFiles.Read.Departments
	|Catalog.SubcontractorReport2_5AttachedFiles.Update.PartnerGroups
	|Catalog.SubcontractorReport2_5AttachedFiles.Update.Companies
	|Catalog.SubcontractorReport2_5AttachedFiles.Update.Departments
	|Catalog.ProductionLots.Read.Companies
	|Catalog.ProductionLots.Update.Companies
	|Catalog.ProductionPlanAttachedFiles.Read.PlanProfiles
	|Catalog.ProductionPlanAttachedFiles.Read.Departments
	|Catalog.ProductionPlanAttachedFiles.Read.SalesOperationsPlanningScenarios
	|Catalog.ProductionPlanAttachedFiles.Update.PlanProfiles
	|Catalog.ProductionPlanAttachedFiles.Update.Departments
	|Catalog.ProductionPlanAttachedFiles.Update.SalesOperationsPlanningScenarios
	|Catalog.BudgetBalanceItems.Read.GroupsOfBudgetItemsAndIndicators
	|Catalog.BudgetBalanceItems.Update.GroupsOfBudgetItemsAndIndicators
	|Catalog.BudgetingLimits.Read.GroupsOfBudgetItemsAndIndicators
	|Catalog.BudgetingLimits.Read.BudgetingScenarios
	|Catalog.BudgetingLimits.Update.GroupsOfBudgetItemsAndIndicators
	|Catalog.BudgetingLimits.Update.BudgetingScenarios
	|Catalog.RuleForCalculatingRelatedBudgetBalancesAndTurnovers.Read.GroupsOfBudgetItemsAndIndicators
	|Catalog.RuleForCalculatingRelatedBudgetBalancesAndTurnovers.Update.GroupsOfBudgetItemsAndIndicators
	|Catalog.RulesForCalculationOfInventoryImpairmentProvision.Read.Companies
	|Catalog.RulesForCalculationOfInventoryImpairmentProvision.Update.Companies
	|Catalog.BackflushProductionAttachedFiles.Read.Companies
	|Catalog.BackflushProductionAttachedFiles.Read.Departments
	|Catalog.BackflushProductionAttachedFiles.Update.Companies
	|Catalog.BackflushProductionAttachedFiles.Update.Departments
	|Catalog.RecyclableWasteAllocationAttachedFiles.Read.Companies
	|Catalog.RecyclableWasteAllocationAttachedFiles.Read.Departments
	|Catalog.RecyclableWasteAllocationAttachedFiles.Update.Companies
	|Catalog.RecyclableWasteAllocationAttachedFiles.Update.Departments
	|Catalog.EmployeesHR.Read.GroupsOfIndividuals
	|Catalog.EmployeesHR.Read.Companies
	|Catalog.EmployeesHR.Update.GroupsOfIndividuals
	|Catalog.EmployeesHR.Update.Companies
	|Catalog.BudgetFlowItems.Read.GroupsOfBudgetItemsAndIndicators
	|Catalog.BudgetFlowItems.Update.GroupsOfBudgetItemsAndIndicators
	|Catalog.BudgetingScenarios.Read.BudgetingScenarios
	|Catalog.BudgetingScenarios.Update.BudgetingScenarios
	|Catalog.BudgetEntryFormAttachedFiles.Read.GroupsOfBudgetTypes
	|Catalog.BudgetEntryFormAttachedFiles.Read.GroupsOfBudgetItemsAndIndicators
	|Catalog.BudgetEntryFormAttachedFiles.Read.Companies
	|Catalog.BudgetEntryFormAttachedFiles.Read.Departments
	|Catalog.BudgetEntryFormAttachedFiles.Read.BudgetingScenarios
	|Catalog.BudgetEntryFormAttachedFiles.Update.GroupsOfBudgetTypes
	|Catalog.BudgetEntryFormAttachedFiles.Update.GroupsOfBudgetItemsAndIndicators
	|Catalog.BudgetEntryFormAttachedFiles.Update.Companies
	|Catalog.BudgetEntryFormAttachedFiles.Update.Departments
	|Catalog.BudgetEntryFormAttachedFiles.Update.BudgetingScenarios
	|Document.InternalAcceptanceCertificate.Read.Companies
	|Document.InternalAcceptanceCertificate.Read.Departments
	|Document.InternalAcceptanceCertificate.Read.StatusesOfInternalAcceptanceCertificate
	|Document.InternalAcceptanceCertificate.Update.Companies
	|Document.InternalAcceptanceCertificate.Update.Departments
	|Document.InternalAcceptanceCertificate.Update.StatusesOfInternalAcceptanceCertificate
	|Document.IntangibleAssetsAmortizationCharge2_4.Read.Companies
	|Document.IntangibleAssetsAmortizationCharge2_4.Update.Companies
	|Document.FixedAssetsDepreciationCharge2_4.Read.Companies
	|Document.FixedAssetsDepreciationCharge2_4.Update.Companies
	|Document.OBEntryOfLeaseSettlements.Read.Companies
	|Document.OBEntryOfLeaseSettlements.Update.Companies
	|Document.EntryOfCapitalAssetsBalance2_4.Read.Companies
	|Document.EntryOfCapitalAssetsBalance2_4.Update.Companies
	|Document.EnterRentalInvestmentBalance.Read.Companies
	|Document.EnterRentalInvestmentBalance.Update.Companies
	|Document.OBEntrySubAssetsAndComponentsOfDepreciation.Read.Companies
	|Document.OBEntrySubAssetsAndComponentsOfDepreciation.Update.Companies
	|Document.PayrollStatementHR.Read.GroupsOfIndividuals
	|Document.PayrollStatementHR.Read.Companies
	|Document.PayrollStatementHR.Update.GroupsOfIndividuals
	|Document.PayrollStatementHR.Update.Companies
	|Document.ReturnAssetsFromLeasee2_4.Read.Companies
	|Document.ReturnAssetsFromLeasee2_4.Update.Companies
	|Document.ReturnLeasedAssets.Read.Companies
	|Document.ReturnLeasedAssets.Update.Companies
	|Document.VendorInvoiceLeasedAssets.Read.Companies
	|Document.VendorInvoiceLeasedAssets.Update.Companies
	|Document.IntangibleAssetsOperatingTime.Read.Companies
	|Document.IntangibleAssetsOperatingTime.Update.Companies
	|Document.WorkOutput.Read.Companies
	|Document.WorkOutput.Read.Departments
	|Document.WorkOutput.Update.Companies
	|Document.WorkOutput.Update.Departments
	|Document.MovementOfProductsAndMaterials.Read.Companies
	|Document.MovementOfProductsAndMaterials.Read.Departments
	|Document.MovementOfProductsAndMaterials.Read.Warehouses
	|Document.MovementOfProductsAndMaterials.Read.StatusesOfRegisteredRecordsOfProductsAndMaterials
	|Document.MovementOfProductsAndMaterials.Read.BusinessTransactions
	|Document.MovementOfProductsAndMaterials.Update.Companies
	|Document.MovementOfProductsAndMaterials.Update.Departments
	|Document.MovementOfProductsAndMaterials.Update.Warehouses
	|Document.MovementOfProductsAndMaterials.Update.StatusesOfRegisteredRecordsOfProductsAndMaterials
	|Document.MovementOfProductsAndMaterials.Update.BusinessTransactions
	|Document.OrderOfMaterialsForProduction.Read.Companies
	|Document.OrderOfMaterialsForProduction.Read.Departments
	|Document.OrderOfMaterialsForProduction.Read.Warehouses
	|Document.OrderOfMaterialsForProduction.Update.Companies
	|Document.OrderOfMaterialsForProduction.Update.Departments
	|Document.OrderOfMaterialsForProduction.Update.Warehouses
	|Document.SubcontractOrder2_5.Read.PartnerGroups
	|Document.SubcontractOrder2_5.Read.Companies
	|Document.SubcontractOrder2_5.Read.Departments
	|Document.SubcontractOrder2_5.Read.Warehouses
	|Document.SubcontractOrder2_5.Update.PartnerGroups
	|Document.SubcontractOrder2_5.Update.Companies
	|Document.SubcontractOrder2_5.Update.Departments
	|Document.SubcontractOrder2_5.Update.Warehouses
	|Document.SigningOfLeaseContract.Read.Companies
	|Document.SigningOfLeaseContract.Update.Companies
	|Document.ChangeIntangibleAssetFinancialDetails2_4.Read.Companies
	|Document.ChangeIntangibleAssetFinancialDetails2_4.Update.Companies
	|Document.ChangeFixedAssetFinancialDetails2_4.Read.Companies
	|Document.ChangeFixedAssetFinancialDetails2_4.Update.Companies
	|Document.LeaseTermAdjustment.Read.Companies
	|Document.LeaseTermAdjustment.Update.Companies
	|Document.ChangeRentalTerms.Read.Companies
	|Document.ChangeRentalTerms.Update.Companies
	|Document.IntangibleAssetsPhysicalCount.Read.Companies
	|Document.IntangibleAssetsPhysicalCount.Update.Companies
	|Document.FixedAssetsPhysicalCount.Read.Companies
	|Document.FixedAssetsPhysicalCount.Update.Companies
	|Document.PhysicalCountOfInventoryInOperation.Read.Companies
	|Document.PhysicalCountOfInventoryInOperation.Read.Departments
	|Document.PhysicalCountOfInventoryInOperation.Update.Companies
	|Document.PhysicalCountOfInventoryInOperation.Update.Departments
	|Document.IntangibleAssetsCostAndAmortizationAdjustment.Read.Companies
	|Document.IntangibleAssetsCostAndAmortizationAdjustment.Update.Companies
	|Document.FixedAssetCostAndDepreciationAdjustment.Read.Companies
	|Document.FixedAssetCostAndDepreciationAdjustment.Update.Companies
	|Document.FixedAssetsCostAdditions2_4.Read.Companies
	|Document.FixedAssetsCostAdditions2_4.Update.Companies
	|Document.AccrualOfLeaseInterest.Read.Companies
	|Document.AccrualOfLeaseInterest.Update.Companies
	|Document.AccrualAndWriteOffOfBadDebtAlowances.Read.Companies
	|Document.AccrualAndWriteOffOfBadDebtAlowances.Update.Companies
	|Document.FutureExpenseCommitmentsAccrualWriteOff.Read.Companies
	|Document.FutureExpenseCommitmentsAccrualWriteOff.Update.Companies
	|Document.MergeOfFixedAssets.Read.Companies
	|Document.MergeOfFixedAssets.Update.Companies
	|Document.RecordInventoryInOperation.Read.Companies
	|Document.RecordInventoryInOperation.Read.Departments
	|Document.RecordInventoryInOperation.Update.Companies
	|Document.RecordInventoryInOperation.Update.Departments
	|Document.AllocateVariancesToFixedAssetCost.Read.Companies
	|Document.AllocateVariancesToFixedAssetCost.Update.Companies
	|Document.PostingPayrollExpensesInFinancialAccounting2_5.Read.Companies
	|Document.PostingPayrollExpensesInFinancialAccounting2_5.Update.Companies
	|Document.SubcontractorReport2_5.Read.PartnerGroups
	|Document.SubcontractorReport2_5.Read.Companies
	|Document.SubcontractorReport2_5.Read.Departments
	|Document.SubcontractorReport2_5.Update.PartnerGroups
	|Document.SubcontractorReport2_5.Update.Companies
	|Document.SubcontractorReport2_5.Update.Departments
	|Document.ProvideAssetsToLeasee2_4.Read.Companies
	|Document.ProvideAssetsToLeasee2_4.Update.Companies
	|Document.TransferInOperation.Read.Companies
	|Document.TransferInOperation.Read.Departments
	|Document.TransferInOperation.Update.Companies
	|Document.TransferInOperation.Update.Departments
	|Document.IATransfer2_4.Read.Companies
	|Document.IATransfer2_4.Update.Companies
	|Document.FATransfer2_4.Read.Companies
	|Document.FATransfer2_4.Update.Companies
	|Document.IARevaluation2_4.Read.Companies
	|Document.IARevaluation2_4.Update.Companies
	|Document.FARevaluation2_4.Read.Companies
	|Document.FARevaluation2_4.Update.Companies
	|Document.ProductionPlan.Read.PlanProfiles
	|Document.ProductionPlan.Read.Departments
	|Document.ProductionPlan.Read.SalesOperationsPlanningScenarios
	|Document.ProductionPlan.Update.PlanProfiles
	|Document.ProductionPlan.Update.Departments
	|Document.ProductionPlan.Update.SalesOperationsPlanningScenarios
	|Document.PreparingForIntangibleAssetSale2_4.Read.Companies
	|Document.PreparingForIntangibleAssetSale2_4.Update.Companies
	|Document.PreparingForFixedAssetSale2_4.Read.Companies
	|Document.PreparingForFixedAssetSale2_4.Update.Companies
	|Document.ReceiveLeasedAssets.Read.Companies
	|Document.ReceiveLeasedAssets.Update.Companies
	|Document.LeaseTermination.Read.Companies
	|Document.LeaseTermination.Update.Companies
	|Document.RDExpenseRecognition.Read.Companies
	|Document.RDExpenseRecognition.Update.Companies
	|Document.IntangibleAssetsInitialRecognition2_4.Read.Companies
	|Document.IntangibleAssetsInitialRecognition2_4.Update.Companies
	|Document.FixedAssetsInitialRecognition2_4.Read.Companies
	|Document.FixedAssetsInitialRecognition2_4.Update.Companies
	|Document.RecognizeSubAssetsComponentsOfDepreciation.Read.Companies
	|Document.RecognizeSubAssetsComponentsOfDepreciation.Update.Companies
	|Document.BackflushProduction.Read.Companies
	|Document.BackflushProduction.Read.Departments
	|Document.BackflushProduction.Update.Companies
	|Document.BackflushProduction.Update.Departments
	|Document.SplitFixedAssets.Read.Companies
	|Document.SplitFixedAssets.Update.Companies
	|Document.RecyclableWasteAllocation.Read.Companies
	|Document.RecyclableWasteAllocation.Read.Departments
	|Document.RecyclableWasteAllocation.Update.Companies
	|Document.RecyclableWasteAllocation.Update.Departments
	|Document.CalculationOfInventoryImpairmentProvision.Read.Companies
	|Document.CalculationOfInventoryImpairmentProvision.Update.Companies
	|Document.ShiftScheduleHR.Read.GroupsOfIndividuals
	|Document.ShiftScheduleHR.Read.Companies
	|Document.ShiftScheduleHR.Update.GroupsOfIndividuals
	|Document.ShiftScheduleHR.Update.Companies
	|Document.Decomissioning.Read.Companies
	|Document.Decomissioning.Read.Departments
	|Document.Decomissioning.Update.Companies
	|Document.Decomissioning.Update.Departments
	|Document.DisposeIntangibleAssets2_4.Read.Companies
	|Document.DisposeIntangibleAssets2_4.Update.Companies
	|Document.DisposeFixedAssets2_4.Read.Companies
	|Document.DisposeFixedAssets2_4.Update.Companies
	|Document.TimesheetHR.Read.GroupsOfIndividuals
	|Document.TimesheetHR.Read.Companies
	|Document.TimesheetHR.Update.GroupsOfIndividuals
	|Document.TimesheetHR.Update.Companies
	|Document.IntangibleAssetImprovement.Read.Companies
	|Document.IntangibleAssetImprovement.Update.Companies
	|Document.SetValuesForNonFinancialItems.Read.GroupsOfBudgetItemsAndIndicators
	|Document.SetValuesForNonFinancialItems.Read.Companies
	|Document.SetValuesForNonFinancialItems.Read.Departments
	|Document.SetValuesForNonFinancialItems.Read.BudgetingScenarios
	|Document.SetValuesForNonFinancialItems.Update.GroupsOfBudgetItemsAndIndicators
	|Document.SetValuesForNonFinancialItems.Update.Companies
	|Document.SetValuesForNonFinancialItems.Update.Departments
	|Document.SetValuesForNonFinancialItems.Update.BudgetingScenarios
	|Document.SettingOfEstimatesOpeningBalance.Read.GroupsOfBudgetItemsAndIndicators
	|Document.SettingOfEstimatesOpeningBalance.Read.Companies
	|Document.SettingOfEstimatesOpeningBalance.Read.Departments
	|Document.SettingOfEstimatesOpeningBalance.Read.BudgetingScenarios
	|Document.SettingOfEstimatesOpeningBalance.Update.GroupsOfBudgetItemsAndIndicators
	|Document.SettingOfEstimatesOpeningBalance.Update.Companies
	|Document.SettingOfEstimatesOpeningBalance.Update.Departments
	|Document.SettingOfEstimatesOpeningBalance.Update.BudgetingScenarios
	|Document.BudgetEntryForm.Read.GroupsOfBudgetTypes
	|Document.BudgetEntryForm.Read.GroupsOfBudgetItemsAndIndicators
	|Document.BudgetEntryForm.Read.Companies
	|Document.BudgetEntryForm.Read.Departments
	|Document.BudgetEntryForm.Read.BudgetingScenarios
	|Document.BudgetEntryForm.Update.GroupsOfBudgetTypes
	|Document.BudgetEntryForm.Update.GroupsOfBudgetItemsAndIndicators
	|Document.BudgetEntryForm.Update.Companies
	|Document.BudgetEntryForm.Update.Departments
	|Document.BudgetEntryForm.Update.BudgetingScenarios
	|InformationRegister.IntangibleAssetsDocuments.Read.Companies
	|InformationRegister.FixedAssetsDocuments.Read.Companies
	|InformationRegister.JobsForCalculatingIntangibleAssetAmortization.Read.Companies
	|InformationRegister.JobsForCalculatingFixedAssetDepreciation.Read.Companies
	|InformationRegister.JobsForCalculatingNonCurrentAssetCost.Read.Companies
	|InformationRegister.JobsForGeneratingFixedAssetRecords.Read.Companies
	|InformationRegister.NonFinancialItemValues.Read.GroupsOfBudgetItemsAndIndicators
	|InformationRegister.NonFinancialItemValues.Read.Companies
	|InformationRegister.NonFinancialItemValues.Read.Departments
	|InformationRegister.NonFinancialItemValues.Read.BudgetingScenarios
	|InformationRegister.FALocation.Read.Companies
	|InformationRegister.IntangibleAssetsRegistrationPlace.Read.Companies
	|InformationRegister.OpeningBalanceOfEstimates.Read.GroupsOfBudgetItemsAndIndicators
	|InformationRegister.OpeningBalanceOfEstimates.Read.Companies
	|InformationRegister.OpeningBalanceOfEstimates.Read.Departments
	|InformationRegister.OpeningBalanceOfEstimates.Read.BudgetingScenarios
	|InformationRegister.IADepreciationParametersBookkeepingAndTaxAccounting.Read.Companies
	|InformationRegister.IntangibleAssetAmortizationParametersManagementAccounting.Read.Companies
	|InformationRegister.OSBUDepreciationParameters.Read.Companies
	|InformationRegister.FixedAssetDepreciationParametersManagementAccounting.Read.Companies
	|InformationRegister.InitialIntangibleAssetsInformation.Read.Companies
	|InformationRegister.InitialFixedAssetsInformation.Read.Companies
	|InformationRegister.IntangibleAssetsAccountingProcedure.Read.Companies
	|InformationRegister.IABookkeepingProcedureBookkeepingAndTaxAccounting.Read.Companies
	|InformationRegister.IntangibleAssetsAccountingProcedureManagementAccounting.Read.Companies
	|InformationRegister.AccountingProcedureForOSBU.Read.Companies
	|InformationRegister.FixedAssetsAccountingProcedureManagementAccounting.Read.Companies
	|InformationRegister.CostOfInventoryInOperation.Read.Companies
	|InformationRegister.ProductionSupplySchemes.Read.Departments
	|InformationRegister.ProductionSupplySchemes.Update.Departments
	|AccumulationRegister.IntangibleAssetsAmortizationCharge.Read.Companies
	|AccumulationRegister.FixedAssetsDepreciationCharge.Read.Companies
	|AccumulationRegister.OrdersOfMaterialsForProduction.Read.Companies
	|AccumulationRegister.OrdersOfMaterialsForProduction.Read.Departments
	|AccumulationRegister.OrdersOfMaterialsForProduction.Read.Warehouses
	|AccumulationRegister.InvestmentInRent.Read.Companies
	|AccumulationRegister.LimitsByBudgetingData.Read.Companies
	|AccumulationRegister.LimitsByBudgetingData.Read.Departments
	|AccumulationRegister.BudgetTurnovers.Read.GroupsOfBudgetItemsAndIndicators
	|AccumulationRegister.BudgetTurnovers.Read.Companies
	|AccumulationRegister.BudgetTurnovers.Read.Departments
	|AccumulationRegister.BudgetTurnovers.Read.BudgetingScenarios
	|AccumulationRegister.ReleasePlansProducts_.Read.PlanProfiles
	|AccumulationRegister.ReleasePlansProducts_.Read.Departments
	|AccumulationRegister.ReleasePlansProducts_.Read.SalesOperationsPlanningScenarios
	|AccumulationRegister.PlansOfHumanResourcesOccupancy.Read.Departments
	|AccumulationRegister.PlansOfHumanResourcesOccupancy.Read.SalesOperationsPlanningScenarios
	|AccumulationRegister.MaterialConsumptionPlans.Read.PlanProfiles
	|AccumulationRegister.MaterialConsumptionPlans.Read.Departments
	|AccumulationRegister.MaterialConsumptionPlans.Read.SalesOperationsPlanningScenarios
	|AccumulationRegister.ProductionPlans.Read.PlanProfiles
	|AccumulationRegister.ProductionPlans.Read.Departments
	|AccumulationRegister.ProductionPlans.Read.SalesOperationsPlanningScenarios
	|AccumulationRegister.ProductionPlans.Update.PlanProfiles
	|AccumulationRegister.ProductionPlans.Update.Departments
	|AccumulationRegister.ProductionPlans.Update.SalesOperationsPlanningScenarios
	|AccumulationRegister.OtherWorkInProgressExpenses.Read.Companies
	|AccumulationRegister.OtherWorkInProgressExpenses.Read.Departments
	|AccumulationRegister.LossAllowance.Read.Companies
	|AccumulationRegister.FutureExpenseCommitments.Read.Companies
	|AccumulationRegister.IACost.Read.Companies
	|AccumulationRegister.FACost.Read.Companies
	|AccumulationRegister.InventoryInOperation.Read.Companies
	|AccumulationRegister.InventoryInOperation.Read.Departments
	|AccumulationRegister.LaborCostsToRegister.Read.Companies
	|AccumulationRegister.LaborCostsToRegister.Read.Departments
	|AccumulationRegister.WIPLaborCosts.Read.Companies
	|AccumulationRegister.WIPLaborCosts.Read.Departments
	|AccumulationRegister.ActualBudgetingData.Read.GroupsOfBudgetItemsAndIndicators
	|AccumulationRegister.ActualBudgetingData.Read.Companies
	|AccumulationRegister.ActualBudgetingData.Read.Departments
	|Catalog.MaterialProviderOrder2_5AttachedFiles.Read.PartnerGroups
	|Catalog.MaterialProviderOrder2_5AttachedFiles.Read.Companies
	|Catalog.MaterialProviderOrder2_5AttachedFiles.Read.Departments
	|Catalog.MaterialProviderOrder2_5AttachedFiles.Read.Warehouses
	|Catalog.MaterialProviderOrder2_5AttachedFiles.Update.PartnerGroups
	|Catalog.MaterialProviderOrder2_5AttachedFiles.Update.Companies
	|Catalog.MaterialProviderOrder2_5AttachedFiles.Update.Departments
	|Catalog.MaterialProviderOrder2_5AttachedFiles.Update.Warehouses
	|Catalog.ProductionOrder2_2AttachedFiles.Read.Companies
	|Catalog.ProductionOrder2_2AttachedFiles.Update.Companies
	|Catalog.ReportToMaterialProvider2_5AttachedFiles.Read.PartnerGroups
	|Catalog.ReportToMaterialProvider2_5AttachedFiles.Read.Companies
	|Catalog.ReportToMaterialProvider2_5AttachedFiles.Read.Departments
	|Catalog.ReportToMaterialProvider2_5AttachedFiles.Read.Warehouses
	|Catalog.ReportToMaterialProvider2_5AttachedFiles.Update.PartnerGroups
	|Catalog.ReportToMaterialProvider2_5AttachedFiles.Update.Companies
	|Catalog.ReportToMaterialProvider2_5AttachedFiles.Update.Departments
	|Catalog.ReportToMaterialProvider2_5AttachedFiles.Update.Warehouses
	|Catalog.ConsumptionReportSubcontractingServicesDeliveredIntercompanyAttachedFiles.Read.Companies
	|Catalog.ConsumptionReportSubcontractingServicesDeliveredIntercompanyAttachedFiles.Read.Departments
	|Catalog.ConsumptionReportSubcontractingServicesDeliveredIntercompanyAttachedFiles.Update.Companies
	|Catalog.ConsumptionReportSubcontractingServicesDeliveredIntercompanyAttachedFiles.Update.Departments
	|Catalog.StandardTransactionsOfFinancialAccounting.Read.Companies
	|Document.MaterialProviderOrder2_5.Read.PartnerGroups
	|Document.MaterialProviderOrder2_5.Read.Companies
	|Document.MaterialProviderOrder2_5.Read.Departments
	|Document.MaterialProviderOrder2_5.Read.Warehouses
	|Document.MaterialProviderOrder2_5.Update.PartnerGroups
	|Document.MaterialProviderOrder2_5.Update.Companies
	|Document.MaterialProviderOrder2_5.Update.Departments
	|Document.MaterialProviderOrder2_5.Update.Warehouses
	|Document.ProductionOrder2_2.Read.Companies
	|Document.ProductionOrder2_2.Update.Companies
	|Document.CashRegisterShift.Read.Companies
	|Document.CashRegisterShift.Update.Companies
	|Document.WIPOpeningBalancesByProductionLots.Read.Companies
	|Document.WIPOpeningBalancesByProductionLots.Read.Departments
	|Document.WIPOpeningBalancesByProductionLots.Update.Companies
	|Document.WIPOpeningBalancesByProductionLots.Update.Departments
	|Document.InitialWIPBalancesByBusinessUnits.Read.Companies
	|Document.InitialWIPBalancesByBusinessUnits.Read.Departments
	|Document.InitialWIPBalancesByBusinessUnits.Update.Companies
	|Document.InitialWIPBalancesByBusinessUnits.Update.Departments
	|Document.TransactionFinancialAccounting.Read.Companies
	|Document.TransactionFinancialAccounting.Update.Companies
	|Document.ReportToMaterialProvider2_5.Read.PartnerGroups
	|Document.ReportToMaterialProvider2_5.Read.Companies
	|Document.ReportToMaterialProvider2_5.Read.Departments
	|Document.ReportToMaterialProvider2_5.Read.Warehouses
	|Document.ReportToMaterialProvider2_5.Update.PartnerGroups
	|Document.ReportToMaterialProvider2_5.Update.Companies
	|Document.ReportToMaterialProvider2_5.Update.Departments
	|Document.ReportToMaterialProvider2_5.Update.Warehouses
	|Document.ConsumptionReportSubcontractingServicesDeliveredIntercompany.Read.Companies
	|Document.ConsumptionReportSubcontractingServicesDeliveredIntercompany.Read.Departments
	|Document.ConsumptionReportSubcontractingServicesDeliveredIntercompany.Update.Companies
	|Document.ConsumptionReportSubcontractingServicesDeliveredIntercompany.Update.Departments
	|Document.StandardCosting2_2.Read.Companies
	|Document.StandardCosting2_2.Update.Companies
	|Document.ProductionOperation2_2.Read.Companies
	|Document.ProductionOperation2_2.Read.Departments
	|Document.ProductionOperation2_2.Update.Companies
	|Document.ProductionOperation2_2.Update.Departments
	|Document.RegistrarOfBudgetTurnover.Read.Companies
	|Document.RegistrarOfBudgetTurnover.Read.Departments
	|Document.RegistrarOfBudgetTurnover.Read.BudgetingScenarios
	|Document.RegistrarOfBudgetTurnover.Update.Companies
	|Document.RegistrarOfBudgetTurnover.Update.Departments
	|Document.RegistrarOfBudgetTurnover.Update.BudgetingScenarios
	|Document.PeriodEndTransactionFinancialAccounting.Read.Companies
	|Document.PeriodEndTransactionFinancialAccounting.Update.Companies
	|Document.ShiftTask.Read.Departments
	|Document.ShiftTask.Update.Departments
	|Document.SetProductionExpenseStandards.Read.Companies
	|Document.SetProductionExpenseStandards.Read.Departments
	|Document.SetProductionExpenseStandards.Update.Companies
	|Document.SetProductionExpenseStandards.Update.Departments
	|Document.FinancialStatementCopy.Read.Companies
	|Document.FinancialStatementCopy.Update.Companies
	|Document.ProductionStage2_2.Read.Companies
	|Document.ProductionStage2_2.Read.Departments
	|Document.ProductionStage2_2.Update.Companies
	|Document.ProductionStage2_2.Update.Departments
	|InformationRegister.BusinessProcessesData.Read.Object.BusinessProcess.ApprovalOfEngineeringChangeOrders
	|InformationRegister.DocumentPostingInFinancialAccounting.Read.Companies
	|InformationRegister.DocumentPostingInFinancialAccounting.Update.Companies
	|InformationRegister.QueueOfProductionOperations.Read.Departments
	|InformationRegister.QueueOfProductionOperations.Update.Departments
	|AccumulationRegister.OccupancyPlansForWorkCenterTypes.Read.Departments
	|AccumulationRegister.OccupancyPlansForWorkCenterTypes.Read.SalesOperationsPlanningScenarios
	|AccumulationRegister.ReferencesToTransferFromProduction.Read.Companies
	|AccumulationRegister.ReferencesToTransferFromProduction.Read.Departments
	|AccumulationRegister.ReferencesToTransferFromProduction.Read.Warehouses
	|BusinessProcess.ApprovalOfEngineeringChangeOrders.Read.Users
	|BusinessProcess.ApprovalOfEngineeringChangeOrders.Update.Users
	|Task.BudgetTask.Read.Users
	|Task.BudgetTask.Update.Users
	|Task.PerformerTask.Read.Object.BusinessProcess.ApprovalOfEngineeringChangeOrders
	|AccountingRegister.International.Read.Companies
	|AccountingRegister.International.Update.Companies
	|AccountingRegister.InternationalWithoutCorrespondence.Read.Companies
	|AccountingRegister.InternationalWithoutCorrespondence.Update.Companies
	|";

EndProcedure

// Allows to overwrite dependent access value sets of other objects.
//
// Called from the 
//  AccessManagementInternal.WriteAccessValuesSets,
//  AccessManagementInternal.WriteDependentAccessValuesSets procedures.
//
// Parameters:
//  Ref - AnyRef - a reference to the object the access value sets are written for.
//
//  RefsToDependentObjects - Array - an array of items of the CatalogRef, DocumentRef type and so on.
//                 Contains references to objects with dependent access value sets.
//                 Initial value is a blank array.
//
Procedure OnChangeAccessValuesSets(Ref, RefsToDependentObjects) Export
	TMAccessManagement.OnChangeAccessValuesSets(Ref, RefsToDependentObjects);
EndProcedure

#EndRegion