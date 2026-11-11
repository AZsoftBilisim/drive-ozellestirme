#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region Public

// StandardSubsystems.ObjectsVersioning

// Defines object settings for the object Versioning subsystem.
//
// Parameters:
//  Settings - Structure - subsystem settings.
Procedure OnDefineObjectVersioningSettings(Settings) Export

EndProcedure

// End StandardSubsystems.ObjectsVersioning

// Gets the object's details that need to be blocked from being changed
//
// Returns:
//	Array - the blocked details of the object.
//
Function GetObjectAttributesToLock() Export

	Result = New Array;
	Result.Add("Owner");
	Result.Add("PlanType");
	Result.Add("ItemVariants");
	Result.Add("FillInBusinessUnit");
	Result.Add("FillInCompany");
	Result.Add("FillInPartnerInTabularForm");
	Result.Add("FillInAgreementInTabularForm");
	Result.Add("FillInAssignmentInTabularForm");
	Result.Add("FillInWarehouseInTabularForm; FillOptionWarehouseStoreFormat");
	Result.Add("FillInPartner; FillInPartner,FillInTheSalesPartner,FillInThePurchasePartner");
	Result.Add("FillInWarehouse; FillOptionWarehouseStoreFormat, FillInWarehouse,FillInWarehouseInTabularForm");
	Result.Add("FillInTermsOfSales;FillInTermsOfSales,FillOutTheVTSalesAgreement,FillOutTheWCHPurchaseAgreement");
	Result.Add("FillInPaymentPlan");
	Result.Add("FillInUsingFormula; FillInUsingFormula");
	Result.Add("Substitutional; Substitutional");
	Result.Add("FillInManager");
	Result.Add("FillInStoreFormat; FillOptionWarehouseStoreFormat");
	Result.Add("BusinessOperation");
	Result.Add("Parent");
	Result.Add("FillInByShortage; FillInByShortage");
	Result.Add("ContentFillingVariant; ContentFillingVariant, OptionForFillingInTheSelectionList, OptionToFillInTheCompositionWithoutSelection, DecorationOptionForFillingInTheCompositionSelection");
	Result.Add("EmployeeResponsible");
	Result.Add("PlanSemiFinishedProductsAutomatically; PlanSemiFinishedProductsAutomatically");
	Result.Add("ProductionProcessType");
	Result.Add("TransferDemandOfBusinesUnitsThroughTransfers; StopCalculationOfNeedsOnMovements");
	Return Result;

EndFunction

#EndRegion

#EndIf
