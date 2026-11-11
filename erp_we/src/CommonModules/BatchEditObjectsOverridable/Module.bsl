///////////////////////////////////////////////////////////////////////////////////////////////////////
// Copyright (c) 2025, OOO 1C-Soft
// All rights reserved. This software and the related materials 
// are licensed under a Creative Commons Attribution 4.0 International license (CC BY 4.0).
// To view the license terms, follow the link:
// https://creativecommons.org/licenses/by/4.0/legalcode
///////////////////////////////////////////////////////////////////////////////////////////////////////
//

#Region Public

// Define metadata objects in whose list forms
// the bulk edit command will be displayed.
// See BatchEditObjectsClient.ChangeSelectedItems
// 
// Parameters:
//  Objects - Array of MetadataObject
//
// Example:
//	Objects.Add(Metadata.Catalogs.Products);
//	Objects.Add(Metadata.Catalogs.Partners);
//
Procedure OnDefineObjectsWithBatchObjectsModificationCommand(Objects) Export

	

EndProcedure

// Defining metadata objects, in whose manager modules group 
// attribute editing is prohibited.
//
// Parameters:
//   Objects - Map of KeyAndValue - set the key to the full name of the metadata object
//                            attached to the "Bulk edit" subsystem. 
//                            In addition, the value can include export function names:
//                            "AttributesToSkipInBatchProcessing",
//                            "AttributesToEditInBatchProcessing".
//                            Every name must start with a new line.
//                            In case there is a "*", the manager module has both functions specified.
//
// Example: 
//   Objects.Insert(Metadata.Documents.PurchaserOrders.FullName(), "*"); // both functions are defined.
//   Objects.Insert(Metadata.BusinessProcesses.JobWithRoleBasedAddressing.FullName(), "AttributesToEditInBatchProcessing");
//   Objects.Insert(Metadata.Catalogs.Partners.FullName(), "AttributesToEditInBatchProcessing
//		|AttributesToSkipInBatchProcessing");
//
Procedure OnDefineObjectsWithEditableAttributes(Objects) Export
	Objects.Insert(Metadata.BusinessProcesses.Job.FullName(), "AttributesToEditInBatchProcessing");
	Objects.Insert(Metadata.Documents.Meeting.FullName(), "AttributesToEditInBatchProcessing");
	Objects.Insert(Metadata.Documents.PlannedInteraction.FullName(), "AttributesToEditInBatchProcessing");
	Objects.Insert(Metadata.Documents.SMSMessage.FullName(), "AttributesToEditInBatchProcessing");
	Objects.Insert(Metadata.Documents.PhoneCall.FullName(), "AttributesToEditInBatchProcessing");
	Objects.Insert(Metadata.Documents.IncomingEmail.FullName(), "AttributesToEditInBatchProcessing");
	Objects.Insert(Metadata.Documents.OutgoingEmail.FullName(), "AttributesToEditInBatchProcessing");
	Objects.Insert(Metadata.Documents.ConditionsOfCustomerRebates.FullName(), "AttributesToSkipInBatchProcessing");
	Objects.Insert(Metadata.Documents.ConditionsOfVendorRebates.FullName(), "AttributesToSkipInBatchProcessing");
	Objects.Insert(Metadata.Documents.DebitCustomerRebates.FullName(), "AttributesToSkipInBatchProcessing");
	Objects.Insert(Metadata.Documents.WriteOffVendorRebates.FullName(), "AttributesToSkipInBatchProcessing");
	Objects.Insert(Metadata.Documents.AccrualOfCustomerRebates.FullName(), "AttributesToSkipInBatchProcessing");
	Objects.Insert(Metadata.Documents.AccrualOfVendorRebates.FullName(), "AttributesToSkipInBatchProcessing");
	Objects.Insert(Metadata.Documents.CustomerBonusCertificate.FullName(), "AttributesToSkipInBatchProcessing");
	Objects.Insert(Metadata.Documents.VendorBonusCertificate.FullName(), "AttributesToSkipInBatchProcessing");
	Objects.Insert(Metadata.Tasks.PerformerTask.FullName(), "AttributesToEditInBatchProcessing");
	Objects.Insert(Metadata.ChartsOfCharacteristicTypes.AdditionalAttributesAndInfo.FullName(), "AttributesToEditInBatchProcessing");
	Objects.Insert(Metadata.ChartsOfCharacteristicTypes.TaskAddressingObjects.FullName(), "AttributesToSkipInBatchProcessing");
	Objects.Insert(Metadata.Catalogs.ExpenseReportAttachedFiles.FullName(), "AttributesToEditInBatchProcessing");
	Objects.Insert(Metadata.Catalogs.GoodsQualityControlCertificateAttachedFiles.FullName(), "AttributesToEditInBatchProcessing");
	Objects.Insert(Metadata.Catalogs.CustomerInvoiceServicesAttachedFiles.FullName(), "AttributesToEditInBatchProcessing");
	Objects.Insert(Metadata.Catalogs.DiscrepancyReportFollowingShipmentAttachedFiles.FullName(), "AttributesToEditInBatchProcessing");
	Objects.Insert(Metadata.Catalogs.Currencies.FullName(), "AttributesToEditInBatchProcessing");
	Objects.Insert(Metadata.Catalogs.ReportsOptions.FullName(), "AttributesToEditInBatchProcessing");
	Objects.Insert(Metadata.Catalogs.FilesVersions.FullName(), "AttributesToEditInBatchProcessing");
	Objects.Insert(Metadata.Catalogs.ARAPSettlementAttachedFiles.FullName(), "AttributesToEditInBatchProcessing");
	Objects.Insert(Metadata.Catalogs.LoyaltyCardKinds.FullName(), "AttributesToSkipInBatchProcessing");
	Objects.Insert(Metadata.Catalogs.ContactInformationKinds.FullName(), "AttributesToSkipInBatchProcessing");
	Objects.Insert(Metadata.Catalogs.CustomerRebatesKinds.FullName(), "AttributesToSkipInBatchProcessing");
	Objects.Insert(Metadata.Catalogs.VendorRebateKinds.FullName(), "AttributesToSkipInBatchProcessing");
	Objects.Insert(Metadata.Catalogs.CustomerOpportunityKindsAttachedFiles.FullName(), "AttributesToEditInBatchProcessing");
	Objects.Insert(Metadata.Catalogs.ExternalUsers.FullName(), "AttributesToSkipInBatchProcessing");
	Objects.Insert(Metadata.Catalogs.InventoryConsumptionAttachedFiles.FullName(), "AttributesToEditInBatchProcessing");
	Objects.Insert(Metadata.Catalogs.ReturnOfGoodsFromCustomerAttachedFiles.FullName(), "AttributesToEditInBatchProcessing");
	Objects.Insert(Metadata.Catalogs.ReturnOfGoodsToVendorAttachedFiles.FullName(), "AttributesToEditInBatchProcessing");
	Objects.Insert(Metadata.Catalogs.MeetingAttachedFiles.FullName(), "AttributesToEditInBatchProcessing");
	Objects.Insert(Metadata.Catalogs.ReturnablePackagingRedemptionByCustomerAttachedFiles.FullName(), "AttributesToEditInBatchProcessing");
	Objects.Insert(Metadata.Catalogs.RedemptionOfReturnablePackagingFromVendorAttachedFiles.FullName(), "AttributesToEditInBatchProcessing");
	Objects.Insert(Metadata.Catalogs.ExternalUsersGroups.FullName(), "AttributesToSkipInBatchProcessing");
	Objects.Insert(Metadata.Catalogs.AccessGroups.FullName(), "AttributesToSkipInBatchProcessing");
	Objects.Insert(Metadata.Catalogs.TaskPerformersGroups.FullName(), "AttributesToSkipInBatchProcessing");
	Objects.Insert(Metadata.Catalogs.CounterpartyContractsAttachedFiles.FullName(), "AttributesToEditInBatchProcessing");
	Objects.Insert(Metadata.Catalogs.LoanAndDepositContractsAttachedFiles.FullName(), "AttributesToEditInBatchProcessing");
	Objects.Insert(Metadata.Catalogs.AdditionalReportsAndDataProcessors.FullName(), "AttributesToEditInBatchProcessing");
	Objects.Insert(Metadata.Catalogs.TransportationJobAttachedFiles.FullName(), "AttributesToEditInBatchProcessing");
	Objects.Insert(Metadata.Catalogs.JobForSalesRepresentativeAttachedFiles.FullName(), "AttributesToEditInBatchProcessing");
	Objects.Insert(Metadata.Catalogs.SalesOrderAttachedFiles.FullName(), "AttributesToEditInBatchProcessing");
	Objects.Insert(Metadata.Catalogs.InventoryConsumptionOrderAttachedFiles.FullName(), "AttributesToEditInBatchProcessing");
	Objects.Insert(Metadata.Catalogs.PurchaseOrderAttachedFiles.FullName(), "AttributesToEditInBatchProcessing");
	Objects.Insert(Metadata.Catalogs.InteractionsTabs.FullName(), "AttributesToSkipInBatchProcessing");
	Objects.Insert(Metadata.Catalogs.Notes.FullName(), "AttributesToEditInBatchProcessing");
	Objects.Insert(Metadata.Catalogs.PlannedInteractionAttachedFiles.FullName(), "AttributesToEditInBatchProcessing");
	Objects.Insert(Metadata.Catalogs.RequestForReturnOfGoodsFromCustomerAttachedFiles.FullName(), "AttributesToEditInBatchProcessing");
	Objects.Insert(Metadata.Catalogs.RequestForGoodsQualityControlAttachedFiles.FullName(), "AttributesToEditInBatchProcessing");
	Objects.Insert(Metadata.Catalogs.PaymentRequestAttachedFiles.FullName(), "AttributesToEditInBatchProcessing");
	Objects.Insert(Metadata.Catalogs.ObjectsPropertiesValues.FullName(), "AttributesToEditInBatchProcessing");
	Objects.Insert(Metadata.Catalogs.ObjectPropertyValueHierarchy.FullName(), "AttributesToEditInBatchProcessing");
	Objects.Insert(Metadata.Catalogs.MetadataObjectIDs.FullName(), "AttributesToEditInBatchProcessing");
	Objects.Insert(Metadata.Catalogs.CashAccounts.FullName(), "AttributesToSkipInBatchProcessing");
	Objects.Insert(Metadata.Catalogs.CashRegisters.FullName(), "AttributesToSkipInBatchProcessing");
	Objects.Insert(Metadata.Catalogs.BankClassifier.FullName(), "AttributesToSkipInBatchProcessing");
	Objects.Insert(Metadata.Catalogs.Counterparties.FullName(), "AttributesToSkipInBatchProcessing");
	Objects.Insert(Metadata.Catalogs.PurchaseAdjustmentAttachedFiles.FullName(), "AttributesToEditInBatchProcessing");
	Objects.Insert(Metadata.Catalogs.SaleAdjustmentAttachedFiles.FullName(), "AttributesToEditInBatchProcessing");
	Objects.Insert(Metadata.Catalogs.MarketingActivitiesAttachedFiles.FullName(), "AttributesToEditInBatchProcessing");
	Objects.Insert(Metadata.Catalogs.AdditionalAttributesAndInfoSets.FullName(), "AttributesToEditInBatchProcessing");
	Objects.Insert(Metadata.Catalogs.Products.FullName(), "AttributesToSkipInBatchProcessing");
	Objects.Insert(Metadata.Catalogs.ProductCrossReferencesAttachedFiles.FullName(), "AttributesToEditInBatchProcessing");
	Objects.Insert(Metadata.Catalogs.ProductsAttachedFiles.FullName(), "AttributesToEditInBatchProcessing");
	Objects.Insert(Metadata.Catalogs.StorageAreas.FullName(), "AttributesToSkipInBatchProcessing");
	Objects.Insert(Metadata.Catalogs.PlannedCashReceiptAttachedFiles.FullName(), "AttributesToEditInBatchProcessing");
	Objects.Insert(Metadata.Catalogs.Companies.FullName(), "AttributesToSkipInBatchProcessing");
	Objects.Insert(Metadata.Catalogs.CompaniesAttachedFiles.FullName(), "AttributesToEditInBatchProcessing");
	Objects.Insert(Metadata.Catalogs.CashDepositWithdrawalDiscrepanciesAttachedFiles.FullName(), "AttributesToEditInBatchProcessing");
	Objects.Insert(Metadata.Catalogs.WriteOffReportFromCommissionAgentAttachedFiles.FullName(), "AttributesToEditInBatchProcessing");
	Objects.Insert(Metadata.Catalogs.ConsignmentReportFromCustomerAttachedFiles.FullName(), "AttributesToEditInBatchProcessing");
	Objects.Insert(Metadata.Catalogs.PurchaseInvoiceConsignmentStockLostAttachedFiles.FullName(), "AttributesToEditInBatchProcessing");
	Objects.Insert(Metadata.Catalogs.ConsignmentReportToVendorAttachedFiles.FullName(), "AttributesToEditInBatchProcessing");
	Objects.Insert(Metadata.Catalogs.PurchasingReportToConsignorPrincipalAttachedFiles.FullName(), "AttributesToEditInBatchProcessing");
	Objects.Insert(Metadata.Catalogs.FilesFolders.FullName(), "AttributesToEditInBatchProcessing");
	Objects.Insert(Metadata.Catalogs.EmailMessageFolders.FullName(), "AttributesToSkipInBatchProcessing");
	Objects.Insert(Metadata.Catalogs.PartnersAttachedFiles.FullName(), "AttributesToEditInBatchProcessing");
	Objects.Insert(Metadata.Catalogs.InventoryTransferAttachedFiles.FullName(), "AttributesToEditInBatchProcessing");
	Objects.Insert(Metadata.Catalogs.PurchasePlanAttachedFiles.FullName(), "AttributesToEditInBatchProcessing");
	Objects.Insert(Metadata.Catalogs.PlanOfGoodsStockAttachedFiles.FullName(), "AttributesToEditInBatchProcessing");
	Objects.Insert(Metadata.Catalogs.SalesPlanByCategoriesAttachedFiles.FullName(), "AttributesToEditInBatchProcessing");
	Objects.Insert(Metadata.Catalogs.SalesPlanAttachedFiles.FullName(), "AttributesToEditInBatchProcessing");
	Objects.Insert(Metadata.Catalogs.AssemblyDisassemblyPlanAttachedFiles.FullName(), "AttributesToEditInBatchProcessing");
	Objects.Insert(Metadata.Catalogs.InventoryConsumptionPlanAttachedFiles.FullName(), "AttributesToEditInBatchProcessing");
	Objects.Insert(Metadata.Catalogs.Users.FullName(), "AttributesToSkipInBatchProcessing");
	Objects.Insert(Metadata.Catalogs.UserReportSettings.FullName(), "AttributesToEditInBatchProcessing");
	Objects.Insert(Metadata.Catalogs.VendorInvoiceAttachedFiles.FullName(), "AttributesToEditInBatchProcessing");
	Objects.Insert(Metadata.Catalogs.VendorInvoiceServicesAndAssetsAttachedFiles.FullName(), "AttributesToEditInBatchProcessing");
	Objects.Insert(Metadata.Catalogs.EmailProcessingRules.FullName(), "AttributesToSkipInBatchProcessing");
	Objects.Insert(Metadata.Catalogs.PredefinedReportsOptions.FullName(), "AttributesToEditInBatchProcessing");
	Objects.Insert(Metadata.Catalogs.ComplaintsAttachedFiles.FullName(), "AttributesToEditInBatchProcessing");
	Objects.Insert(Metadata.Catalogs.DigitalSignatureAndEncryptionApplications.FullName(), "AttributesToEditInBatchProcessing");
	Objects.Insert(Metadata.Catalogs.ProjectsAttachedFiles.FullName(), "AttributesToEditInBatchProcessing");
	Objects.Insert(Metadata.Catalogs.AccessGroupProfiles.FullName(), "AttributesToSkipInBatchProcessing");
	Objects.Insert(Metadata.Catalogs.WarehouseZones.FullName(), "AttributesToSkipInBatchProcessing");
	Objects.Insert(Metadata.Catalogs.ReportMailings.FullName(), "AttributesToSkipInBatchProcessing");
	Objects.Insert(Metadata.Catalogs.CustomerInvoiceAttachedFiles.FullName(), "AttributesToEditInBatchProcessing");
	Objects.Insert(Metadata.Catalogs.CustomerInvoiceServicesAndAssetsAttachedFiles.FullName(), "AttributesToEditInBatchProcessing");
	Objects.Insert(Metadata.Catalogs.VendorPriceListAttachedFiles.FullName(), "AttributesToEditInBatchProcessing");
	Objects.Insert(Metadata.Catalogs.PerformerRoles.FullName(), "AttributesToSkipInBatchProcessing");
	Objects.Insert(Metadata.Catalogs.ARAPReconciliation2_4AttachedFiles.FullName(), "AttributesToEditInBatchProcessing");
	Objects.Insert(Metadata.Catalogs.ARAPReconciliation2_5_11AttachedFiles.FullName(), "AttributesToEditInBatchProcessing");
	Objects.Insert(Metadata.Catalogs.SalesOpportunitiesToCustomer.FullName(), "AttributesToEditInBatchProcessing");
	Objects.Insert(Metadata.Catalogs.SalesOpportunitiesToCustomerAttachedFiles.FullName(), "AttributesToEditInBatchProcessing");
	Objects.Insert(Metadata.Catalogs.ProductSegments.FullName(), "AttributesToSkipInBatchProcessing");
	Objects.Insert(Metadata.Catalogs.PartnersSegments.FullName(), "AttributesToSkipInBatchProcessing");
	Objects.Insert(Metadata.Catalogs.ItemsBatches.FullName(), "AttributesToSkipInBatchProcessing");
	Objects.Insert(Metadata.Catalogs.DigitalSignatureAndEncryptionKeysCertificates.FullName(), "AttributesToSkipInBatchProcessing");
	Objects.Insert(Metadata.Catalogs.QualityCertificatesAttachedFiles.FullName(), "AttributesToEditInBatchProcessing");
	Objects.Insert(Metadata.Catalogs.TermsOfSaleAttachedFiles.FullName(), "AttributesToEditInBatchProcessing");
	Objects.Insert(Metadata.Catalogs.TermsOfPurchaseFromVendorsAttachedFiles.FullName(), "AttributesToEditInBatchProcessing");
	Objects.Insert(Metadata.Catalogs.SMSMessageAttachedFiles.FullName(), "AttributesToEditInBatchProcessing");
	Objects.Insert(Metadata.Catalogs.SystemMessages.FullName(), "AttributesToSkipInBatchProcessing");
	Objects.Insert(Metadata.Catalogs.BankAccountIssueAttachedFiles.FullName(), "AttributesToEditInBatchProcessing");
	Objects.Insert(Metadata.Catalogs.ARAPAdjustmentAttachedFiles.FullName(), "AttributesToEditInBatchProcessing");
	Objects.Insert(Metadata.Catalogs.WorldCountries.FullName(), "AttributesToSkipInBatchProcessing");
	Objects.Insert(Metadata.Catalogs.StringContactInteractions.FullName(), "AttributesToEditInBatchProcessing");
	Objects.Insert(Metadata.Catalogs.BusinessStructure.FullName(), "AttributesToSkipInBatchProcessing");
	Objects.Insert(Metadata.Catalogs.CustomerCommercialInvoiceAttachedFiles.FullName(), "AttributesToEditInBatchProcessing");
	Objects.Insert(Metadata.Catalogs.CCDImportAttachedFiles.FullName(), "AttributesToEditInBatchProcessing");
	Objects.Insert(Metadata.Catalogs.PhoneCallAttachedFiles.FullName(), "AttributesToEditInBatchProcessing");
	Objects.Insert(Metadata.Catalogs.VehicleTypes.FullName(), "AttributesToSkipInBatchProcessing");
	Objects.Insert(Metadata.Catalogs.FileStorageVolumes.FullName(), "AttributesToEditInBatchProcessing");
	Objects.Insert(Metadata.Catalogs.Vehicles.FullName(), "AttributesToSkipInBatchProcessing");
	Objects.Insert(Metadata.Catalogs.PriceSetupAttachedFiles.FullName(), "AttributesToEditInBatchProcessing");
	Objects.Insert(Metadata.Catalogs.EmailAccounts.FullName(), "AttributesToEditInBatchProcessing");
	Objects.Insert(Metadata.Catalogs.Files.FullName(), "AttributesToEditInBatchProcessing");
	Objects.Insert(Metadata.Catalogs.PersonsAttachedFiles.FullName(), "AttributesToEditInBatchProcessing");
	Objects.Insert(Metadata.Catalogs.ItemsCharacteristics.FullName(), "AttributesToSkipInBatchProcessing");
	Objects.Insert(Metadata.Catalogs.MessageTemplatesAttachedFiles.FullName(), "AttributesToEditInBatchProcessing");
	Objects.Insert(Metadata.Catalogs.IncomingEmailAttachedFiles.FullName(), "AttributesToEditInBatchProcessing");
	Objects.Insert(Metadata.Catalogs.OutgoingEmailAttachedFiles.FullName(), "AttributesToEditInBatchProcessing");
	Objects.Insert(Metadata.Catalogs.SubcontractorReport2_5AttachedFiles.FullName(), "AttributesToEditInBatchProcessing");
	Objects.Insert(Metadata.Catalogs.ProductionPlanAttachedFiles.FullName(), "AttributesToEditInBatchProcessing");
	Objects.Insert(Metadata.Catalogs.SubcontractOrder2_5AttachedFiles.FullName(), "AttributesToEditInBatchProcessing");
	Objects.Insert(Metadata.Catalogs.BudgetEntryFormAttachedFiles.FullName(), "AttributesToEditInBatchProcessing");
	Objects.Insert(Metadata.Catalogs.BillsOfMaterials.FullName(), "AttributesToSkipInBatchProcessing");
	Objects.Insert(Metadata.Catalogs.BillsOfMaterialsAttachedFiles.FullName(), "AttributesToEditInBatchProcessing");
	Objects.Insert(Metadata.Catalogs.OrderOfMaterialsForProductionAttachedFiles.FullName(), "AttributesToEditInBatchProcessing");
	Objects.Insert(Metadata.Catalogs.ConstructionObjectsAttachedFiles.FullName(), "AttributesToEditInBatchProcessing");
	Objects.Insert(Metadata.Catalogs.AssetsAttachedFiles.FullName(), "AttributesToEditInBatchProcessing");
	Objects.Insert(Metadata.Catalogs.DocumentsFAAttachedFiles.FullName(), "AttributesToEditInBatchProcessing");
	Objects.Insert(Metadata.Catalogs.AccrualAndWriteOffOfBadDebtAlowancesAttachedFiles.FullName(), "AttributesToEditInBatchProcessing");
	Objects.Insert(Metadata.Catalogs.FutureExpenseCommitmentsAccrualWriteOffAttachedFiles.FullName(), "AttributesToEditInBatchProcessing");
	Objects.Insert(Metadata.Catalogs.RDTopicsStagesAttachedFiles.FullName(), "AttributesToEditInBatchProcessing");
	Objects.Insert(Metadata.Catalogs.ReportToMaterialProvider2_5AttachedFiles.FullName(), "AttributesToEditInBatchProcessing");
	Objects.Insert(Metadata.Catalogs.ConsumptionReportSubcontractingServicesDeliveredIntercompanyAttachedFiles.FullName(), "AttributesToEditInBatchProcessing");
	Objects.Insert(Metadata.Catalogs.ManufacturingOperationsAttachedFiles.FullName(), "AttributesToEditInBatchProcessing");
	Objects.Insert(Metadata.Catalogs.WorkCenterTypes.FullName(), "AttributesToSkipInBatchProcessing");
	Objects.Insert(Metadata.Catalogs.RouteSheets.FullName(), "AttributesToSkipInBatchProcessing");
	Objects.Insert(Metadata.Catalogs.RouteSheetsAttachedFiles.FullName(), "AttributesToEditInBatchProcessing");
	Objects.Insert(Metadata.Catalogs.TechnologicalProcesses.FullName(), "AttributesToSkipInBatchProcessing");
	Objects.Insert(Metadata.Catalogs.MaterialProviderOrder2_5AttachedFiles.FullName(), "AttributesToEditInBatchProcessing");
	Objects.Insert(Metadata.Catalogs.ProductionOperation2_2AttachedFiles.FullName(), "AttributesToEditInBatchProcessing");
	Objects.Insert(Metadata.Catalogs.ShiftTaskAttachedFiles.FullName(), "AttributesToEditInBatchProcessing");
	Objects.Insert(Metadata.Catalogs.ProductionStage2_2AttachedFiles.FullName(), "AttributesToEditInBatchProcessing");
	Objects.Insert(Metadata.Catalogs.WorkCenters.FullName(), "AttributesToSkipInBatchProcessing");
	Objects.Insert(Metadata.Catalogs.ManufacturingOperationClassifier.FullName(), "AttributesToSkipInBatchProcessing");
	Objects.Insert(Metadata.Documents.ShiftTask.FullName(), "AttributesToSkipInBatchProcessing");
	Objects.Insert(Metadata.Catalogs.Assets.FullName(), "AttributesToEditInBatchProcessing");
	Objects.Insert(Metadata.Catalogs.GoodsQualityResearchAttachedFiles.FullName(), "AttributesToEditInBatchProcessing");
	Objects.Insert(Metadata.Catalogs.GoodsResearchSheetsAttachedFiles.FullName(), "AttributesToEditInBatchProcessing");
	
	FinancialAccountingOfGeneralPurpose.OnDefineObjectsWithEditableAttributes(Objects);
	BatchEditObjectsLocalization.OnDefineObjectsWithEditableAttributes(Objects);
EndProcedure

// Determines object attributes that can be edited using the bulk edit data processor.
// By default, all the object attributes can be edited. To limit the attribute list, fill one of the collections: AttributesToEdit or NonEditAttributes.
// If the both collections contain values, the attributes that don't belong to these collections are considered to be members of the NonEditAttributes collection.
// 
// 
// Parameters:
//  Object - MetadataObject - Object for which the list of editable attributes is specified.
//  AttributesToEdit - Undefined, Array of String - Names of the attributes that can be edited using the bulk edit data processor.
//                                                            This value is ignored if the NonEditAttributes parameter is passed.
//  AttributesToSkip - Undefined, Array of String - Names of the attributes that cannot be edited using the bulk edit data processor.
// 
Procedure OnDefineEditableObjectAttributes(Object, AttributesToEdit, AttributesToSkip) Export

EndProcedure

#EndRegion
