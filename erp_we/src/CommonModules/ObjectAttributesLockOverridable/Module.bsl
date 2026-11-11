///////////////////////////////////////////////////////////////////////////////////////////////////////
// Copyright (c) 2025, OOO 1C-Soft
// All rights reserved. This software and the related materials 
// are licensed under a Creative Commons Attribution 4.0 International license (CC BY 4.0).
// To view the license terms, follow the link:
// https://creativecommons.org/licenses/by/4.0/legalcode
///////////////////////////////////////////////////////////////////////////////////////////////////////
//

#Region Public

// Defines the metadata objects in whose manager modules attribute edition is disabled using the
// GetObjectAttributesToLock export function.
//
// For the GetObjectAttributesToLock return value,
// See ObjectAttributesLock.DescriptionOfAttributeToLock
//
// By default, the label field related to the attribute is not locked.
// To lock it, specify the label name in the details of the attribute.
//
// Parameters:
//   Objects - Map of KeyAndValue:
//     * Key - String - a full name of the metadata object attached to the subsystem;
//     * Value - String - empty string.
//
// Example:
//   Object.Insert(Metadata.Documents.SalesOrder.FullName(), "");
//
//   Example of the code to be placed in the object manager module:
//   // See ObjectAttributesLockOverridable.OnDefineLockedAttributes.LockedAttributes
//   
//   	Function GetObjectAttributesToLock() Export
//   	AttributesToLock = New Array;
//   	AttributesToLock.Add("Company");
//   	AttributesToLock.Add("Partner;Partner");
//   	Attribute = ObjectAttributesLock.NewAttributeToLock();
//   	Attribute.Name = "Counterparty";
//   	Attribute.Warning = NStr("en = 'It is not recommended that you change this field if there are documents created'; fa = 'It is not recommended that you change this field if there are documents created'");
//   	AttributesToLock.Add(Attribute);
//   	...
//   Return AttributesToLock;
//   EndFunction
//
Procedure OnDefineObjectsWithLockedAttributes(Objects) Export
	ObjectAttributesLockLocalization.OnDefineObjectsWithLockedAttributes(Objects);
	
	Objects.Insert(Metadata.ChartsOfCharacteristicTypes.AdditionalAttributesAndInfo.FullName(), "GetObjectAttributesToLock");
	Objects.Insert(Metadata.ChartsOfCharacteristicTypes.ChannelsOfAdvertisingImpacts.FullName(), "GetObjectAttributesToLock");
	Objects.Insert(Metadata.ChartsOfCharacteristicTypes.AssetLiabilityItems.FullName(), "GetObjectAttributesToLock");
	Objects.Insert(Metadata.ChartsOfCharacteristicTypes.ExpenseItems.FullName(), "GetObjectAttributesToLock");
	Objects.Insert(Metadata.Catalogs.CounterpartyBankAccounts.FullName(), "GetObjectAttributesToLock");
	Objects.Insert(Metadata.Catalogs.CompaniesBankAccounts.FullName(), "GetObjectAttributesToLock");
	Objects.Insert(Metadata.Catalogs.LoyaltyPrograms.FullName(), "GetObjectAttributesToLock");
	Objects.Insert(Metadata.Catalogs.ProductKitConfigurations.FullName(), "GetObjectAttributesToLock");
	Objects.Insert(Metadata.Catalogs.LoyaltyCardKinds.FullName(), "GetObjectAttributesToLock");
	Objects.Insert(Metadata.Catalogs.ContactInformationKinds.FullName(), "GetObjectAttributesToLock");
	Objects.Insert(Metadata.Catalogs.ItemKinds.FullName(), "GetObjectAttributesToLock");
	Objects.Insert(Metadata.Catalogs.PlanProfiles.FullName(), "GetObjectAttributesToLock");
	Objects.Insert(Metadata.Catalogs.GiftCertificateKinds.FullName(), "GetObjectAttributesToLock");
	Objects.Insert(Metadata.Catalogs.CustomerRebatesKinds.FullName(), "GetObjectAttributesToLock");
	Objects.Insert(Metadata.Catalogs.VendorRebateKinds.FullName(), "GetObjectAttributesToLock");
	Objects.Insert(Metadata.Catalogs.CustomerOpportunityKinds.FullName(), "GetObjectAttributesToLock");
	Objects.Insert(Metadata.Catalogs.TypesOfPrices.FullName(), "GetObjectAttributesToLock");
	Objects.Insert(Metadata.Catalogs.VendorPriceTypes.FullName(), "GetObjectAttributesToLock");
	Objects.Insert(Metadata.Catalogs.PaymentSchedules.FullName(), "GetObjectAttributesToLock");
	Objects.Insert(Metadata.Catalogs.GroupsOfMailoutsAndNotifications.FullName(), "GetObjectAttributesToLock");
	Objects.Insert(Metadata.Catalogs.CounterpartyContracts.FullName(), "GetObjectAttributesToLock");
	Objects.Insert(Metadata.Catalogs.LoanAndDepositContracts.FullName(), "GetObjectAttributesToLock");
	Objects.Insert(Metadata.Catalogs.IntercompanyContracts.FullName(), "GetObjectAttributesToLock");
	Objects.Insert(Metadata.Catalogs.LoyaltyCards.FullName(), "GetObjectAttributesToLock");
	Objects.Insert(Metadata.Catalogs.CashAccounts.FullName(), "GetObjectAttributesToLock");
	Objects.Insert(Metadata.Catalogs.CashRegisters.FullName(), "GetObjectAttributesToLock");
	Objects.Insert(Metadata.Catalogs.FEACN.FullName(), "GetObjectAttributesToLock");
	Objects.Insert(Metadata.Catalogs.PackagingGroups.FullName(), "GetObjectAttributesToLock");
	Objects.Insert(Metadata.Catalogs.LinesOfBusiness.FullName(), "GetObjectAttributesToLock");
	Objects.Insert(Metadata.Catalogs.Products.FullName(), "GetObjectAttributesToLock");
	Objects.Insert(Metadata.Catalogs.CCDNumbers.FullName(), "GetObjectAttributesToLock");
	Objects.Insert(Metadata.Catalogs.StorageAreas.FullName(), "GetObjectAttributesToLock");
	Objects.Insert(Metadata.Catalogs.Companies.FullName(), "GetObjectAttributesToLock");
	Objects.Insert(Metadata.Catalogs.BatchAccountingPolicies.FullName(), "GetObjectAttributesToLock");
	Objects.Insert(Metadata.Catalogs.CustomerRewardProgramRules.FullName(), "GetObjectAttributesToLock");
	Objects.Insert(Metadata.Catalogs.WarehouseZones.FullName(), "GetObjectAttributesToLock");
	Objects.Insert(Metadata.Catalogs.ProductSegments.FullName(), "GetObjectAttributesToLock");
	Objects.Insert(Metadata.Catalogs.PartnersSegments.FullName(), "GetObjectAttributesToLock");
	Objects.Insert(Metadata.Catalogs.DiscountsMarkups.FullName(), "GetObjectAttributesToLock");
	Objects.Insert(Metadata.Catalogs.WarehouseGroupsOfItems.FullName(), "GetObjectAttributesToLock");
	Objects.Insert(Metadata.Catalogs.Warerooms.FullName(), "GetObjectAttributesToLock");
	Objects.Insert(Metadata.Catalogs.StorageBins.FullName(), "GetObjectAttributesToLock");
	Objects.Insert(Metadata.Catalogs.Warehouses.FullName(), "GetObjectAttributesToLock");
	Objects.Insert(Metadata.Catalogs.BusinessStructure.FullName(), "GetObjectAttributesToLock");
	Objects.Insert(Metadata.Catalogs.SalesOperationsPlanningScenarios.FullName(), "GetObjectAttributesToLock");
	Objects.Insert(Metadata.Catalogs.DeliveryPoints.FullName(), "GetObjectAttributesToLock");
	Objects.Insert(Metadata.Catalogs.PackagesAndUnitsOfMeasure.FullName(), "GetObjectAttributesToLock");
	Objects.Insert(Metadata.Catalogs.DiscountMarkupTerms.FullName(), "GetObjectAttributesToLock");
	Objects.Insert(Metadata.Catalogs.StoreFormats.FullName(), "GetObjectAttributesToLock");
	Objects.Insert(Metadata.Catalogs.POSTerminals.FullName(), "GetObjectAttributesToLock");
	Objects.Insert(Metadata.Catalogs.GiftCertificates.FullName(), "GetObjectAttributesToLock");
	Objects.Insert(Metadata.Catalogs.RulesOfExchangeWithOfflinePeripherals.FullName(), "GetObjectAttributesToLock");
	Objects.Insert(Metadata.Catalogs.ExcisableGoodsCategories.FullName(), "GetObjectAttributesToLock");
	Objects.Insert(Metadata.Catalogs.WorkCenterTypes.FullName(), "GetObjectAttributesToLock");
	Objects.Insert(Metadata.Catalogs.FinancialAccountingPostingGenerationSetting.FullName(), "GetObjectAttributesToLock");
	Objects.Insert(Metadata.Catalogs.WorkCenters.FullName(), "GetObjectAttributesToLock");
	Objects.Insert(Metadata.Catalogs.FinancialAccountingChartsOfAccounts.FullName(), "GetObjectAttributesToLock");
	Objects.Insert(Metadata.Catalogs.ProductionSites.FullName(), "GetObjectAttributesToLock");
	Objects.Insert(Metadata.Catalogs.GoodsResearchSheets.FullName(), "GetObjectAttributesToLock");
	
	Objects.Insert(Metadata.Documents.ProductionOrder2_2.FullName(), "GetObjectAttributesToLock");
	Objects.Insert(Metadata.Documents.ProductionStage2_2.FullName(), "GetObjectAttributesToLock");
	
	Objects.Insert(Metadata.ChartsOfAccounts.International.FullName(), "GetObjectAttributesToLock");
	Objects.Insert(Metadata.Catalogs.Teams.FullName(), "GetObjectAttributesToLock");
	Objects.Insert(Metadata.Catalogs.LeaseContract.FullName(), "GetObjectAttributesToLock");
	Objects.Insert(Metadata.Catalogs.CostAllocationRules.FullName(), "GetObjectAttributesToLock");
	Objects.Insert(Metadata.Catalogs.BudgetingModels.FullName(), "GetObjectAttributesToLock");
	Objects.Insert(Metadata.Catalogs.BudgetBalanceItems.FullName(), "GetObjectAttributesToLock");
	Objects.Insert(Metadata.Catalogs.RuleForCalculatingRelatedBudgetBalancesAndTurnovers.FullName(), "GetObjectAttributesToLock");
	Objects.Insert(Metadata.Catalogs.ProductCostElements.FullName(), "GetObjectAttributesToLock");
	Objects.Insert(Metadata.Catalogs.BudgetFlowItems.FullName(), "GetObjectAttributesToLock");
	Objects.Insert(Metadata.Catalogs.BudgetProfiles.FullName(), "GetObjectAttributesToLock");
	Objects.Insert(Metadata.ChartsOfCharacteristicTypes.BudgetFlowItemDimensions.FullName(), "GetObjectAttributesToLock");
	Objects.Insert(Metadata.Catalogs.BudgetingScenarios.FullName(), "GetObjectAttributesToLock");
	Objects.Insert(Metadata.Catalogs.NonFinancialItemsOfBudgets.FullName(), "GetObjectAttributesToLock");
	Objects.Insert(Metadata.Catalogs.Assets.FullName(), "GetObjectAttributesToLock");
	Objects.Insert(Metadata.Catalogs.AccountingObjectsOfFutureExpenseCommitments.FullName(), "GetObjectAttributesToLock");
	Objects.Insert(Metadata.Catalogs.AccrualAndDeductionKinds.FullName(), "GetObjectAttributesToLock");
	Objects.Insert(Metadata.Catalogs.TaxContributionKinds.FullName(), "GetObjectAttributesToLock");
	Objects.Insert(Metadata.Catalogs.NonFinancialItemProfiles.FullName(), "GetObjectAttributesToLock");
	Objects.Insert(Metadata.Catalogs.BudgetingLimits.FullName(), "GetObjectAttributesToLock");
	Objects.Insert(Metadata.Catalogs.CostCenters.FullName(), "GetObjectAttributesToLock");
	Objects.Insert(Metadata.Catalogs.RDTopicsStages.FullName(), "GetObjectAttributesToLock");
EndProcedure

// Allows overriding the list of locked attributes specified in the object manager module.
//
// Parameters:
//   MetadataObjectName - String - for example, "Catalog.Files".
//   LockedAttributes - Array of See ObjectAttributesLock.DescriptionOfAttributeToLock
//
Procedure OnDefineLockedAttributes(MetadataObjectName, LockedAttributes) Export
	
EndProcedure

#EndRegion
