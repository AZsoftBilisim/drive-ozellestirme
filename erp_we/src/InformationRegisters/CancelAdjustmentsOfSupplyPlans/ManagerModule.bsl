#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region Public

// Checks for canceled manual adjustments to the production plan.
//
// Parameters:
//  Plan - DocumentRef.PurchasePlan, DocumentRef.AssemblyDisassemblyPlan, DocumentRef.ProductionPlan - document to check.
// 
// Returns:
//  Boolean - True if there are canceled adjustments according to the production plan.
//
Function ThereAreUndoneAdjustments(Plan) Export
	
	SetPrivilegedMode(True);
	
	Query = New Query(
		"SELECT TOP 1
		|	CancelAdjustmentsOfSupplyPlans.Plan AS Plan
		|FROM
		|	InformationRegister.CancelAdjustmentsOfSupplyPlans AS CancelAdjustmentsOfSupplyPlans
		|WHERE
		|	CancelAdjustmentsOfSupplyPlans.Plan = &Plan");
	
	Query.SetParameter("Plan", Plan);
	
	QueryResult = Query.Execute();
	
	SetPrivilegedMode(False);
	
	Return Not QueryResult.IsEmpty();
	
EndFunction

#EndRegion

#EndIf