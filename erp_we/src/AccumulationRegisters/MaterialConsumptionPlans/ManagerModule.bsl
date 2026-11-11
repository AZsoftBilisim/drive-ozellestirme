#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region Public

// Returns a list of semi-finished products that consume the specified semi-finished product.
//
// Parameters:
//  SemiFinishedProduct - Structure - parameters of the semi-finished product.
// 
// Returns:
//  ValueTable - data on consumers of semi-finished products.
//
Function ConsumersOfSemiFinishedProducts(SemiFinishedProduct) Export
	
	Query = New Query(
		"SELECT DISTINCT
		|	MaterialConsumptionPlans.Scenario AS Scenario,
		|	MaterialConsumptionPlans.Status AS Status,
		|	MaterialConsumptionPlans.ProductsItems AS Products,
		|	MaterialConsumptionPlans.ItemVariant AS Characteristic,
		|	MaterialConsumptionPlans.ProductionDispatcherBusinessUnit AS Department,
		|	MaterialConsumptionPlans.ProductionPlan AS ProductionPlan,
		|	MaterialConsumptionPlans.ProductBOM AS BillOfMaterials,
		|	MaterialConsumptionPlans.AssignmentOfProducts AS Purpose,
		|	MaterialConsumptionPlans.ProductionDate AS Period
		|FROM
		|	AccumulationRegister.MaterialConsumptionPlans AS MaterialConsumptionPlans
		|WHERE
		|	MaterialConsumptionPlans.Scenario = &Scenario
		|	AND MaterialConsumptionPlans.Status = &Status
		|	AND MaterialConsumptionPlans.Products = &Products
		|	AND MaterialConsumptionPlans.Characteristic = &Characteristic
		|	AND MaterialConsumptionPlans.Purpose = &Purpose
		|	AND MaterialConsumptionPlans.ProductionDispatcherBusinessUnit = &Department
		|	AND MaterialConsumptionPlans.ProductionPlan = &ProductionPlan
		|	AND MaterialConsumptionPlans.Period = &ProductionIssueDateOfIntermediateProducts
		|	AND MaterialConsumptionPlans.ThisIsASemiFinishedProduct = TRUE");
	
	Query.SetParameter("Scenario", SemiFinishedProduct.Scenario);
	Query.SetParameter("Status", SemiFinishedProduct.Status);
	Query.SetParameter("Products", SemiFinishedProduct.Products);
	Query.SetParameter("Characteristic", SemiFinishedProduct.Characteristic);
	Query.SetParameter("Purpose", SemiFinishedProduct.Purpose);
	Query.SetParameter("Department", SemiFinishedProduct.Department);
	Query.SetParameter("ProductionPlan", SemiFinishedProduct.ProductionPlan);
	Query.SetParameter("ProductionIssueDateOfIntermediateProducts", SemiFinishedProduct.ProductionIssueDateOfIntermediateProducts);
	
	Return Query.Execute().Unload();
	
EndFunction

#Region InterfaceImplementation

// StandardSubsystems.AccessManagement

// Parameters:
//   Restriction - See AccessManagementOverridable.OnFillAccessRestriction.Restriction.
//
Procedure OnFillAccessRestriction(Restriction) Export

	Restriction.Text =
	"AllowReadUpdate
	|WHERE
	|	ValueAllowed(ProductionDispatcherBusinessUnit)
	|	AND ValueAllowed(Scenario)
	|	AND ValueAllowed(PlanProfile)";

EndProcedure

// End StandardSubsystems.AccessManagement

#EndRegion

#EndRegion

#Region Private

#EndRegion

#EndIf
