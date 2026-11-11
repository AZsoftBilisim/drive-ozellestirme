///////////////////////////////////////////////////////////////////////////////////////////////////////
// Copyright (c) 2025, OOO 1C-Soft
// All rights reserved. This software and the related materials 
// are licensed under a Creative Commons Attribution 4.0 International license (CC BY 4.0).
// To view the license terms, follow the link:
// https://creativecommons.org/licenses/by/4.0/legalcode
///////////////////////////////////////////////////////////////////////////////////////////////////////
//

#Region Public

// This procedure defines standard settings applied to subsystem objects.
//
// Parameters:
//   Settings - Structure - Collection of subsystem settings. Has the following attributes::
//       * OutputReportsInsteadOfOptions - Boolean - Default mode of displaying hyperlinks in the report panel::
//           If True, report options are hidden, and reports are enabled and visible.
//           If False, report options are visible by default, reports are disabled.
//           By default, False.
//       * OutputDetails1 - Boolean - Default mode of displaying details in the report panel::
//           If True, display details as captions under options hyperlinks.
//           If False, display details as tooltips.
//           By default, True.
//       * Search - Structure - Report option search settings::
//           ** InputHint - String - Hint text is displayed in the search field when the search is not specified.
//               It is recommended to use frequently used terms of the applied configuration as a hint.
//       * OtherReports - Structure - "Other reports" form settings::
//           ** CloseAfterChoice - Boolean - Flag indicating whether the form is closed after selecting a report hyperlink.
//               True - close "Other reports" after selection.
//               False - do not close.
//               The default value is True.
//           ** ShowCheckBox - Boolean - Flag indicating whether the CloseAfterChoice check box is visible.
//               True - whether to show "Close this window after moving to another report" check box.
//               False - hide the check box.
//               The default value is False.
//       * EditOptionsAllowed - Boolean - Show advanced report settings and commands of report option change.
//               
//
// Example:
//	Settings.Search.InputHint = NStr("en = 'For example, cost'; fa = 'For example, cost'");
//	Settings.OtherReports.CloseAfterChoice = False;
//	Settings.OtherReports.ShowCheckBox = True;
//	Settings.OptionChangesAllowed = False;
//
Procedure OnDefineSettings(Settings) Export
	Settings.OutputReportsInsteadOfOptions = True;
	ReportsOptionsLocalization.OnDefineSettings(Settings);
EndProcedure

#Region ReportsLocationSettings

// Determines command interface sections where report panels are provided.
// In Sections, it is necessary to add metadata of those subsystems of the first level
// in which commands of report panels call are placed.
//
// Parameters:
//  Sections - ValueList - Sections containing the report panel opening commands::
//      * Value - MetadataObjectSubsystem
//                 - String - Either a subsystem of the global command interface
//                   or ReportsOptionsClientServer.HomePageID for the home page.
//      * Presentation - String - Report panel header in this section.
//
// Example:
//	Sections.Add(Metadata.Subsystems.Surveys, NStr("en = 'Survey reports'; fa = 'Survey reports'"));
//	Sections.Add(ReportsOptionsClientServer.HomePageID(), NStr("en = 'Main reports'; fa = 'Main reports'"));
//
Procedure DefineSectionsWithReportOptions(Sections) Export
	TMReportOptionsOverridable.DefineSectionsWithReportOptions(Sections);
	ReportsOptionsLocalization.DefineSectionsWithReportOptions(Sections);
EndProcedure

// This procedure configures extended settings of configuration reports such as:
// - Report details.
// - Search fields: descriptions of fields, parameters, and filters (for reports that are not based on DCS).
// - Placement in the sections of command interface
//   (initial setup of report placement in subsystems is automatically determined from metadata,
//    its duplication is not required).
// - The Enabled flag (for context reports).
// - Output mode in report panels (with or without grouping by a report).
// - And so on.
// 
// Only settings of configuration reports (and report options) are configured in the procedure.
// To set up reports from configuration extensions, add them to the AttachableReportsAndDataProcessors subsystem.
//
// To configure the settings, use the following auxiliary procedures and functions:
//   ReportsOptions.ReportDetails, 
//   ReportsOptions.OptionDetails, 
//   ReportsOptions.SetOutputModeInReportPanels, 
//   ReportsOptions.SetUpReportInManagerModule.
//
// You can change the settings of all report options by modifying the report settings.
// If report option settings are retrieved explicitly, they become independent
// (they no longer inherit settings changes from the report).
//   
// Functional options of the predefined report option are merged to functional options of this report according to the following rules:
// (FO1_Report OR FO2_Report) And (FO3_Option OR FO4_Option).
// Only the functional options of the report are available for user report options,
// - they are disabled only with disabling the entire report.
//
// Parameters:
//   Settings - ValueTable - Collection of predefined report options, where::
//       * Report - CatalogRef.ExtensionObjectIDs
//               - CatalogRef.AdditionalReportsAndDataProcessors
//               - CatalogRef.MetadataObjectIDs
//               - String - Full name or reference to the report ID.
//       * Metadata - MetadataObjectReport - Report metadata.
//       * UsesDCS - Boolean - Flag indicating whether the main DCS is used in the report.
//       * VariantKey - String - Report option ID.
//       * DetailsReceived - Boolean - Flag indicating that the string description is already received.
//       * Enabled              - Boolean - If False, the report option is hidden from the report panel.
//       * DefaultVisibility - Boolean - If False, the report option is hidden from the report panel by default.
//       * ShouldShowInOptionsSubmenu - Boolean - If False, the report is hidden from the report choice submenu  
//                                                in the report form. It's used if Enabled is False.
//       * Description - String - Report option name.
//       * LongDesc - String - Clarifies the report purpose.
//       * Location - Map of KeyAndValue - Location settings for placing the report option in sections or subsystems, where::
//             ** Key - MetadataObject - Subsystem that contains the report or report option.
//             ** Value - String - Location settings for placing reports (report options) in the subsystem (group): "", "Important", "SeeAlso".
//       * SearchSettings - Structure - Additional settings for searching this report option, where::
//             ** FieldDescriptions - String - Names of report option fields.
//             ** FilterParameterDescriptions - String - Names of report option settings.
//             ** Keywords - String - Additional terminology (including specialized and obsolete).
//             ** TemplatesNames - String - This parameter is used instead of FieldDescriptions.
//       * SystemInfo - Structure - Other internal information.
//       * Type - String - List of type IDs.
//       * IsOption - Boolean - Flag indicating whether report details are related to a report option.
//       * FunctionalOptions - Array of String - Collection of functional option IDs, where::
//       * GroupByReport - Boolean - Flag indicating whether it is necessary to group options by a base report.
//       * MeasurementsKey - String - ID of report performance measurement.
//       * MainOption - String - ID of the main report option.
//       * DCSSettingsFormat - Boolean - Flag indicating whether the settings in the DCS format are stored.
//       * DefineFormSettings - Boolean - The report has an API for integration with the report form
//           including overriding some form settings and subscribing to its events.
//           If True and the report is attached to the general ReportForm form,
//           then the procedure must be defined in the report object module according to the following template::
//               
//               Set report form settings.
//               //
//               
//               Parameters:
//               Form - ClientApplicationForm, Undefined
//               OptionKey - String, Undefined See ReportsClientServer.DefaultReportSettings
//               //
//               Settings - 
//               	
//               Procedure DefineFormSettings(Form, OptionKey, Settings) Export
//                                             Procedure code.
//                                             EndProcedure
//
// Example:
//
//  // Adding report option to the subsystem.
//	OptionSettings = ReportsOptions.OptionDetails(Settings, Metadata.Reports.NameOfReport, "<OptionName>");
//	OptionSettings.Placement.Insert(Subsystems.SectionName.Subsystems.SubsystemName);
//
//  // Disabling report options.
//	OptionSettings = ReportsOptions.OptionDetails(Settings, Metadata.Reports.NameOfReport, "<OptionName>");
//	OptionSettings.Enabled = False;
//
//  // Disabling all report options except one.
//	ReportSettings = ReportsOptions.ReportDetails(Settings, Metadata.Reports.NameOfReport);
//	ReportSettings.Enabled = False;
//	OptionSettings = ReportsOptions.OptionDetails(Settings, ReportSettings, "<OptionName>");
//	OptionSettings.Enabled = True;
//
//  // Filling in the search settings - field descriptions, parameters and filters:
//	OptionSettings = ReportsOptions.OptionDetails(Settings, Metadata.Reports.NameOfReportWithoutSchema, "");
//	OptionSettings.SearchSettings.FieldDescriptions =
//		NStr("en = 'Counterparty
//		|Contract
//		|Responsible person
//		|Discount
//		|Date'");
//	OptionSettings.SearchSettings.FilterParameterDescriptions =
//		NStr("en = 'Period
//		|Responsible person
//		|Counterparty
//		|Contract'");
//
//  // Switching the output mode in report panels:
//  // Grouping report options by this report:
//	ReportsOptions.SetOutputModeInReportPanels(Settings, Metadata.Reports.NameOfReport, True);
//  // Without grouping by the report:
//	Report = ReportsOptions.ReportDetails(Settings, Metadata.Reports.NameOfReport);
//	ReportsOptions.SetOutputModeInReportPanels(Settings, Report, False);
//
Procedure CustomizeReportsOptions(Settings) Export
	
	TMReportOptionsOverridable.CustomizeReportsOptions(Settings);
	ReportsOptionsLocalization.CustomizeReportsOptions(Settings);
	
EndProcedure

// Registers changes in report option names.
// It is used when updating to keep reference integrity,
// in particular for saving user settings and mailing report settings.
// Old option name is reserved and cannot be used later.
// If there are several changes, each change must be registered
// by specifying the last (current) report option name in the relevant option name.
// Since the names of report options are not displayed in the user interface,
// it is recommended to set them in such a way that they would not be changed.
// Add to Changes the details of changes in names
// of the report options connected to the subsystem.
//
// Parameters:
//   Changes - ValueTable - Table of changed report option names. Columns::
//       * Report - MetadataObject - Metadata of the report whose schema contains the new option name.
//       * OldOptionName - String - Old name of the report option.
//       * RelevantOptionName - String - Current (last relevant) option name.
//
// Example:
//	Change = Changes.Add();
//	Change.Report = Metadata.Reports.<NameOfReport>;
//	Change.OldOptionName = "<OldOptionName>";
//	Change.RelevantOptionName = "<RelevantOptionName>";
//
Procedure RegisterChangesOfReportOptionsKeys(Changes) Export
	TMReportOptionsOverridable.RegisterChangesOfReportOptionsKeys(Changes);
	ReportsOptionsLocalization.RegisterChangesOfReportOptionsKeys(Changes);
EndProcedure

#EndRegion

#Region ReportsCommandsSettings

// Determines configuration objects whose manager modules support the AddReportsCommands procedure
// describing context report opening commands.
// See the help for the AddReportsCommands procedure syntax.
//
// Parameters:
//  Objects - Array of MetadataObject - metadata objects (MetadataObject) with report commands.
//
Procedure DefineObjectsWithReportCommands(Objects) Export
	NonCurrentAssets.DefineObjectsWithReportCommands(Objects);
	LeasedAssetAccounting.DefineObjectsWithReportCommands(Objects);
	//
	RMManagement.DefineObjectsWithReportCommands(Objects);
	Objects.Add(Metadata.BusinessProcesses.ApprovalOfEngineeringChangeOrders);
	InventoryInOperationServer.DefineObjectsWithReportCommands(Objects);
	RebatesServer.DefineObjectsWithReportCommands(Objects);
	GoodsDelivery.DefineObjectsWithReportCommands(Objects);
	
	Objects.Add(Metadata.BusinessProcesses.ApprovalOfInventoryConsumptionOrder);
	Objects.Add(Metadata.BusinessProcesses.PurchaseApproval);
	Objects.Add(Metadata.BusinessProcesses.ApprovalOfRequestForReturnOfGoodsFromCustomer);
	Objects.Add(Metadata.BusinessProcesses.SaleApproval);
	Objects.Add(Metadata.BusinessProcesses.PriceApproval);
	Objects.Add(Metadata.Documents.ExpenseReport);
	Objects.Add(Metadata.Documents.CustomerInvoiceServices);
	Objects.Add(Metadata.Documents.GoodsQualityControlCertificate);
	Objects.Add(Metadata.Documents.DiscrepancyReportFollowingShipment);
	Objects.Add(Metadata.Documents.DiscrepancyReportFollowingTransfer);
	Objects.Add(Metadata.Documents.DiscrepancyReportFollowingReceipt);
	Objects.Add(Metadata.Documents.GiftCertificateCancellation);
	Objects.Add(Metadata.Documents.OBEntry);
	Objects.Add(Metadata.Documents.OBEntryARAP);
	Objects.Add(Metadata.Documents.OBEntryCash);
	Objects.Add(Metadata.Documents.OBEntrySalesForPastPeriods);
	Objects.Add(Metadata.Documents.OBEntryFinancialInstruments);
	Objects.Add(Metadata.Documents.OBEntryOtherExpenses);
	Objects.Add(Metadata.Documents.OBEntryOtherAssetsAndLiabilities);
	Objects.Add(Metadata.Documents.OBEntryAcquiringContractARAP);
	Objects.Add(Metadata.Documents.OBEntryARAPAdvanceHolders);
	Objects.Add(Metadata.Documents.OBEntryGoods);
	Objects.Add(Metadata.Documents.ARAPSettlement);
	Objects.Add(Metadata.Documents.DepositCashIntoCashRegister);
	Objects.Add(Metadata.Documents.InventoryConsumption);
	Objects.Add(Metadata.Documents.IntercompanyGoodsReturn);
	Objects.Add(Metadata.Documents.ReturnOfGoodsFromCustomer);
	Objects.Add(Metadata.Documents.ReturnOfGoodsToVendor);
	Objects.Add(Metadata.Documents.ReturnOfGiftCards);
	Objects.Add(Metadata.Documents.CashWithdrawalFromCashRegister);
	Objects.Add(Metadata.Documents.ReturnablePackagingRedemptionByCustomer);
	Objects.Add(Metadata.Documents.RedemptionOfReturnablePackagingFromVendor);
	Objects.Add(Metadata.Documents.RedemptionOfGoodsFromStorage);
	Objects.Add(Metadata.Documents.RedemptionOfGoodsByCustodian);
	Objects.Add(Metadata.Documents.ContractSchedule);
	Objects.Add(Metadata.Documents.MovementOfOtherAssetsAndLiabilities);
	Objects.Add(Metadata.Documents.IssuedLetterOfAuthority);
	Objects.Add(Metadata.Documents.TransportationJob);
	Objects.Add(Metadata.Documents.JobForSalesRepresentative);
	Objects.Add(Metadata.Documents.SalesOrder);
	Objects.Add(Metadata.Documents.InventoryConsumptionOrder);
	Objects.Add(Metadata.Documents.TransferOrder);
	Objects.Add(Metadata.Documents.ByAssemblyDisassemblyOrder);
	Objects.Add(Metadata.Documents.PurchaseOrder);
	Objects.Add(Metadata.Documents.PurchaseRequest);
	Objects.Add(Metadata.Documents.RequestForReturnOfGoodsFromCustomer);
	Objects.Add(Metadata.Documents.ApplicationForBusinessTrip);
	Objects.Add(Metadata.Documents.RequestForGoodsQualityControl);
	Objects.Add(Metadata.Documents.ApplicationForCollateral);
	Objects.Add(Metadata.Documents.PaymentRequest);
	Objects.Add(Metadata.Documents.ProductRangeChange);
	Objects.Add(Metadata.Documents.PhysicalCountReport);
	Objects.Add(Metadata.Documents.PhysicalCountOfCashAccounts);
	Objects.Add(Metadata.Documents.ARAPAccountingScheduleAdjustment);
	Objects.Add(Metadata.Documents.InventoryAdjustmentSurplusesAndShortages);
	Objects.Add(Metadata.Documents.ARAPAdjustmentFinancialInstruments);
	Objects.Add(Metadata.Documents.InventoryAssignmentAdjustment);
	Objects.Add(Metadata.Documents.InventoryAdjustmentGoodsShipmentOrder);
	Objects.Add(Metadata.Documents.PurchaseAdjustment);
	Objects.Add(Metadata.Documents.SaleAdjustment);
	Objects.Add(Metadata.Documents.RegisterAdjustment);
	Objects.Add(Metadata.Documents.CashFlowLimits);
	Objects.Add(Metadata.Documents.AccrueAndDeductionOfBonusPoints);
	Objects.Add(Metadata.Documents.LoanAndDepositInterestCharge);
	Objects.Add(Metadata.Documents.SalesPlansAllocationBaseByCategories);
	Objects.Add(Metadata.Documents.PlannedCashReceipt);
	Objects.Add(Metadata.Documents.PaymentCardTransaction);
	Objects.Add(Metadata.Documents.InventorySurplusRecognition);
	Objects.Add(Metadata.Documents.RecognitionOfStockSurplusShippedToCustomer);
	Objects.Add(Metadata.Documents.GoodsSurplusesNote);
	Objects.Add(Metadata.Documents.GoodsShortageNote);
	Objects.Add(Metadata.Documents.GoodsMisgradingNote);
	Objects.Add(Metadata.Documents.DamageNote);
	Objects.Add(Metadata.Documents.GoodsTransferNote);
	Objects.Add(Metadata.Documents.ElectronicTicketTransaction);
	Objects.Add(Metadata.Documents.GoodsPickingPlacement);
	Objects.Add(Metadata.Documents.GoodsShipmentToCustomer);
	Objects.Add(Metadata.Documents.GoodsShipmentFromStorage);
	Objects.Add(Metadata.Documents.CashDepositWithdrawalDiscrepancies);
	Objects.Add(Metadata.Documents.BankReportOnAcquiringTransactions);
	Objects.Add(Metadata.Documents.ConsignmentReportFromCustomer);
	Objects.Add(Metadata.Documents.WriteOffReportFromCommissionAgent);
	Objects.Add(Metadata.Documents.ConsignmentReportToVendor);
	Objects.Add(Metadata.Documents.PurchasingReportToConsignorPrincipal);
	Objects.Add(Metadata.Documents.PurchaseInvoiceConsignmentStockLost);
	Objects.Add(Metadata.Documents.RetailReturnsReport);
	Objects.Add(Metadata.Documents.RetailSalesReport);
	Objects.Add(Metadata.Documents.CommissionReportIntercompany);
	Objects.Add(Metadata.Documents.CommissionWriteOffReportIntercompany);
	Objects.Add(Metadata.Documents.CustomerInvoiceIntercompany);
	Objects.Add(Metadata.Documents.TransferOfGoodsToBailee);
	Objects.Add(Metadata.Documents.InventoryTransfer);
	Objects.Add(Metadata.Documents.GoodsMisgrading);
	Objects.Add(Metadata.Documents.MisgradingOfGoodsAtCustodian);
	Objects.Add(Metadata.Documents.InventoryRecount);
	Objects.Add(Metadata.Documents.PurchasePlan);
	Objects.Add(Metadata.Documents.PlanOfGoodsStock);
	Objects.Add(Metadata.Documents.SalesPlan);
	Objects.Add(Metadata.Documents.SalesPlanByCategories);
	Objects.Add(Metadata.Documents.AssemblyDisassemblyPlan);
	Objects.Add(Metadata.Documents.InventoryConsumptionPlan);
	Objects.Add(Metadata.Documents.AdjustmentOfPlannedDemand);
	Objects.Add(Metadata.Documents.InstructionForShippingAgent);
	Objects.Add(Metadata.Documents.GoodsDamage);
	Objects.Add(Metadata.Documents.DamageAtCustodian);
	Objects.Add(Metadata.Documents.BankAccountReceiptNote);
	Objects.Add(Metadata.Documents.ReceiptOfGoodsToWarehouse);
	Objects.Add(Metadata.Documents.GoodsReceiptFromCustomer);
	Objects.Add(Metadata.Documents.ReceiptOfGoodsFromCustodian);
	Objects.Add(Metadata.Documents.ReceiptOfServicesToBusinessUnit);
	Objects.Add(Metadata.Documents.GoodsReceiptForStorage);
	Objects.Add(Metadata.Documents.VendorInvoice);
	Objects.Add(Metadata.Documents.VendorInvoiceServicesAndAssets);
	Objects.Add(Metadata.Documents.CashAccountReceiptNote);
	Objects.Add(Metadata.Documents.GoodsReceiptNote);
	Objects.Add(Metadata.Documents.OtherGoodsRecordingAsReceived);
	Objects.Add(Metadata.Documents.OtherIncomeExpenses);
	Objects.Add(Metadata.Documents.CashTransferReferenceOrder);
	Objects.Add(Metadata.Documents.AllocationOfIncomeByLinesOfBusiness);
	Objects.Add(Metadata.Documents.AllocationOfOtherCosts);
	Objects.Add(Metadata.Documents.DeferredExpensesAllocation);
	Objects.Add(Metadata.Documents.MailoutToCustomers);
	Objects.Add(Metadata.Documents.CashVoucher);
	Objects.Add(Metadata.Documents.GoodsIssueNote);
	Objects.Add(Metadata.Documents.ExchangeDifferenceCalculation);
	Objects.Add(Metadata.Documents.CalculationOfDiscountInterestExpenses);
	Objects.Add(Metadata.Documents.InventoryCostCalculation);
	Objects.Add(Metadata.Documents.GiftCertificateSale);
	Objects.Add(Metadata.Documents.CustomerInvoice);
	Objects.Add(Metadata.Documents.CustomerInvoiceServicesAndAssets);
	Objects.Add(Metadata.Documents.VendorPriceList);
	Objects.Add(Metadata.Documents.AssemblyFromComponents);
	Objects.Add(Metadata.Documents.ARAPReconciliation2_4);
	Objects.Add(Metadata.Documents.ARAPReconciliation2_5_11);
	Objects.Add(Metadata.Documents.ReconcileOpeningBalancesByWarehouses);
	Objects.Add(Metadata.Documents.BankAccountIssue);
	Objects.Add(Metadata.Documents.ARAPAdjustment);
	Objects.Add(Metadata.Documents.WriteOffOfGoodsShortages);
	Objects.Add(Metadata.Documents.ReportOnVMIAdjustment);
	Objects.Add(Metadata.Documents.WriteOffOfShippedGoods);
	Objects.Add(Metadata.Documents.ReversingEntry);
	Objects.Add(Metadata.Documents.CustomerCommercialInvoice);
	Objects.Add(Metadata.Documents.CCDImport);
	Objects.Add(Metadata.Documents.PackingList);
	Objects.Add(Metadata.Documents.SetStorageBinLocks);
	Objects.Add(Metadata.Documents.SetProductRangeQuotas);
	Objects.Add(Metadata.Documents.PriceSetup);
	Objects.Add(Metadata.Documents.CashRegisterReceipt);
	Objects.Add(Metadata.Documents.CashRegisterReceiptReturn);
	Objects.Add(Metadata.Documents.ReceiptOfCashRegisterAdjustment);
	Objects.Add(Metadata.DocumentJournals.ARAPReconciliations);
	Objects.Add(Metadata.DocumentJournals.CashRegisterReceipts);
	Objects.Add(Metadata.DataProcessors.LogOfInternalDocuments);
	Objects.Add(Metadata.DataProcessors.LogOfPurchaseDocuments);
	Objects.Add(Metadata.DataProcessors.LogOfIntercompanyDocuments);
	Objects.Add(Metadata.DataProcessors.LogOfSalesDocuments);
	Objects.Add(Metadata.DataProcessors.ConsignmentReportsFromCustomers);
	Objects.Add(Metadata.DataProcessors.AccountSalesToConsignors);
	Objects.Add(Metadata.ChartsOfCharacteristicTypes.AssetLiabilityItems);
	Objects.Add(Metadata.Catalogs.BusinessRegions);
	Objects.Add(Metadata.Catalogs.AnalysisOptionsOfTargetValues);
	Objects.Add(Metadata.Catalogs.OptionsOfLoansAndDepositsSchedules);
	Objects.Add(Metadata.Catalogs.CounterpartyContracts);
	Objects.Add(Metadata.Catalogs.LoanAndDepositContracts);
	Objects.Add(Metadata.Catalogs.IntercompanyContracts);
	Objects.Add(Metadata.Catalogs.AcquiringContracts);
	Objects.Add(Metadata.Catalogs.Counterparties);
	Objects.Add(Metadata.Catalogs.Products);
	Objects.Add(Metadata.Catalogs.StorageAreas);
	Objects.Add(Metadata.Catalogs.Companies);
	Objects.Add(Metadata.Catalogs.Partners);
	Objects.Add(Metadata.Catalogs.GiftCertificates);	
	Objects.Add(Metadata.Catalogs.SalesOpportunitiesToCustomer);
	Objects.Add(Metadata.Catalogs.ProductSegments);
	Objects.Add(Metadata.Catalogs.PartnersSegments);
	Objects.Add(Metadata.Catalogs.WarehouseGroupsOfItems);
	Objects.Add(Metadata.Catalogs.Warerooms);
	Objects.Add(Metadata.Catalogs.StorageBins);
	Objects.Add(Metadata.Catalogs.TermsOfSale);
	Objects.Add(Metadata.Catalogs.TermsOfPurchaseFromVendors);
	Objects.Add(Metadata.Catalogs.BusinessStructure);
	Objects.Add(Metadata.Catalogs.SupplySchemes);
	Objects.Add(Metadata.Documents.AvailabilityOfWorkCenters);
	Objects.Add(Metadata.Documents.AvailabilityOfWorkCenterType);
	Objects.Add(Metadata.Documents.MaterialProviderOrder2_5);
	Objects.Add(Metadata.Documents.ProductionOrder2_2);
	Objects.Add(Metadata.Documents.GoodsQualityResearch);
	Objects.Add(Metadata.Documents.WIPOpeningBalancesByProductionLots);
	Objects.Add(Metadata.Documents.InitialWIPBalancesByBusinessUnits);
	Objects.Add(Metadata.Documents.ReportToMaterialProvider2_5);
	Objects.Add(Metadata.Documents.ConsumptionReportSubcontractingServicesDeliveredIntercompany);
	Objects.Add(Metadata.Documents.StandardCosting2_2);
	Objects.Add(Metadata.Documents.ProductionOperation2_2);
	Objects.Add(Metadata.Documents.BudgetingProcess);
	Objects.Add(Metadata.Documents.EngineeringChangeOrder);
	Objects.Add(Metadata.Documents.RegistrarOfBudgetTurnover);
	Objects.Add(Metadata.Documents.SetProductionExpenseStandards);
	Objects.Add(Metadata.Documents.ProductionStage2_2);
	Objects.Add(Metadata.DataProcessors.ExecutionOfOperations2_2);
	Objects.Add(Metadata.DataProcessors.DocumentsOfReceiptForTollingAll2_5);
	Objects.Add(Metadata.DataProcessors.PerformOperationsMES);
	Objects.Add(Metadata.Documents.InternalAcceptanceCertificate);
	Objects.Add(Metadata.Documents.DepositsWithdrawalsByLineOfBusiness);
	Objects.Add(Metadata.Documents.WorkOutput);
	Objects.Add(Metadata.Documents.MovementOfProductsAndMaterials);
	Objects.Add(Metadata.Documents.OrderOfMaterialsForProduction);
	Objects.Add(Metadata.Documents.SubcontractOrder2_5);
	Objects.Add(Metadata.Documents.AssetActivityRecord);
	Objects.Add(Metadata.Documents.AccrualAndWriteOffOfBadDebtAlowances);
	Objects.Add(Metadata.Documents.FutureExpenseCommitmentsAccrualWriteOff);
	Objects.Add(Metadata.Documents.PostingPayrollExpensesInFinancialAccounting2_5);
	Objects.Add(Metadata.Documents.SubcontractorReport2_5);
	Objects.Add(Metadata.Documents.ProductionPlan);
	Objects.Add(Metadata.Documents.BackflushProduction);
	Objects.Add(Metadata.Documents.CalculationOfInventoryImpairmentProvision);
	Objects.Add(Metadata.Documents.RecyclableWasteAllocation);
	Objects.Add(Metadata.Documents.ProductionCostAllocation);
	Objects.Add(Metadata.Documents.RegisterProductionPlan);
	Objects.Add(Metadata.Documents.SetValuesForNonFinancialItems);
	Objects.Add(Metadata.Documents.SettingOfEstimatesOpeningBalance);
	Objects.Add(Metadata.Documents.BudgetEntryForm);
	Objects.Add(Metadata.Documents.RDExpenseRecognition);
	Objects.Add(Metadata.Catalogs.NonFinancialItemsOfBudgets);
	Objects.Add(Metadata.Catalogs.Assets);
	Objects.Add(Metadata.Catalogs.ProductionLots);
	Objects.Add(Metadata.Catalogs.BudgetBalanceItems);
	Objects.Add(Metadata.Catalogs.ActualDataQueryRulesByBudgetBalanceItems);
	Objects.Add(Metadata.Catalogs.ActualDataQueryRulesByBudgetFlowItems);
	Objects.Add(Metadata.Catalogs.RulesForCalculationOfInventoryImpairmentProvision);
	Objects.Add(Metadata.Catalogs.BillsOfMaterials);
	Objects.Add(Metadata.Catalogs.BudgetFlowItems);
	Objects.Add(Metadata.Catalogs.RDTopicsStages);
	Objects.Add(Metadata.Catalogs.ConstructionObjects);
	
	Objects.Add(Metadata.DataProcessors.DocumentsOfTransferToTollingAll2_5);
	Objects.Add(Metadata.DataProcessors.LogOfProductionDocuments);
	
	Objects.Add(Metadata.Reports.FixedAssetsWithImpairment);
	
	VATAccountingERP.DefineObjectsWithReportCommands(Objects);
	
	ReportsOptionsLocalization.DefineObjectsWithReportCommands(Objects);
	FinancialAccountingOfGeneralPurpose.DefineObjectsWithReportCommands(Objects);
EndProcedure

// Determine a list of global report commands.
// The event occurs when calling a re-use module.
//
// Parameters:
//  ReportsCommands - ValueTable - Table of commands for adding report to the submenu::
//   * Id - String   - Command ID.
//   * Presentation - String   - Command presentation in a form.
//   * Importance      - String   - Suffix of a submenu group in which the command is to be output.
//                                The following values are acceptable: "Important", "Ordinary", and "SeeAlso".
//   * Order       - Number    - Command position in the group. Can be customized workspace-wise.
//                                
//   * Picture      - Picture - Command icon.
//   * Shortcut - Shortcut - Shortcut for fast command call.
//   * ParameterType - TypeDescription - Types of objects that the command is intended for.
//   * VisibilityInForms    - String - Comma-delimited names of the forms to add a command to.
//                                    Use to add different set of commands to different forms.
//   * FunctionalOptions - String - Comma-delimited names of functional options that affect the command visibility.
//   * VisibilityConditions    - Array - Defines the command conditional visibility.
//                                    To add conditions, use procedure AttachableCommands.AddCommandVisibilityCondition().
//                                    Use "And" to specify multiple conditions.
//                                    
//   * ChangesSelectedObjects - Boolean - Optional. Flag defining command availability for users
//                                         who have no right to edit the object can run the command.
//                                         If True, the button will be inactive. By default, False.
//                                         
//   * MultipleChoice - Boolean
//                        - Undefined - Optional. If True, the command supports multiple option choices.
//                                         In this case, the parameter passes a list of references.
//                                         By default, True.
//   * IsNonContextual - Boolean - If set to "True", users can do the following:
//                              access the report's options, add it to favorites, and get the report's reference.
//   * WriteMode - String - Object-writing-associated actions that run before the command handler::
//                 DoNotWrite - Do not write the object and pass the full form in the handler parameters instead of references.
//                                  In this mode, we recommend that you operate directly with a form that is passed in the structure of parameter 2
//                                  of the command handler.
//                 WriteNewOnly - Write only new objects.
//                 Write - Write only new and modified objects.
//                 Post - Post documents.
//                 Before writing or posting the object, users are asked for confirmation.
//                 Optional. By default, Write.
//   * FilesOperationsRequired - Boolean - If True, in the web client, users are prompted
//                                        to install 1C:Enterprise Extension.
//                                        Optional. The default value is False.
//   * Manager - String - Full name of the metadata object where the command was indicated.
//                         For example, "Report.PurchaseLedger".
//   * FormName - String - Name of the form the command will open or receive.
//                         If Handler is not specified, the "Open" method is called.
//   * VariantKey - String - Name of the report option the command will open.
//   * FormParameterName - String - Name of the form parameter to pass a reference or a reference array to.
//   * FormParameters - Undefined
//                    - Structure - Parameters of the form specified in FormName.
//   * Handler - String - Details of the procedure that handles the command's main action.
//                  If the procedure belongs to a common module, the following format is used <CommonModuleName>.<ProcedureName>.
//                  The format <ProcedureName> is used in the following cases::
//                  1. If FormName is filled (then a client procedure is expected in the specified form module).
//                  2. If FormName is not filled (a server procedure is expected in the manager module).
//   * AdditionalParameters - Structure - Handler parameters specified in Handler.
//
//  Parameters - Structure - Runtime context details::
//   * FormName - String - Form full name.
//   
//  StandardProcessing - Boolean - If False, the AddReportsCommands event of the object manager
//                                  is not called.
//
Procedure BeforeAddReportCommands(ReportsCommands, Parameters, StandardProcessing) Export
	ExceptionsArray = New Array;
	ExceptionsArray.Add("Document.PhysicalCountReport.Form.FormGenerate");
	ExceptionsArray.Add("Document.MailoutToCustomers.Form.ListForm");
	ExceptionsArray.Add("Document.MailoutToCustomers.Form.DocumentForm");
	
	If ExceptionsArray.Find(Parameters.FormName) = Undefined Then
		Reports.SearchForReferences.AddUsageInstanceCommand(ReportsCommands);
	EndIf; 
	
	ExceptionsArray = New Array;
	ExceptionsArray.Add(Type("CatalogRef.CounterpartyContractsAttachedFiles"));
	
	For Each SourceType In Parameters.SourcesTypes Do
	
		If ExceptionsArray.Find(SourceType) = Undefined Then
			Reports.ObjectDemoScenarios.BeforeAddReportCommands(ReportsCommands, Parameters, StandardProcessing);
			Break;
		EndIf; 
	
	EndDo;
	
EndProcedure

#EndRegion

#EndRegion