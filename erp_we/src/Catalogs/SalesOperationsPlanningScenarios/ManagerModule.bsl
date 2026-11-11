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

// Returns names of blocked details for the BSP details blocking mechanism
//	Returns:
//		Array - names of the blocked details.
//
Function GetObjectAttributesToLock() Export

	Result = New Array;
	Result.Add("Currency");
	Result.Add("Periodicity");
	Result.Add("CreatePurchasePlanByAmount;PurchasePlanPlan");
	Result.Add("CreateSalesPlanByAmount;SalesPlanPlan");
	Result.Add("PlanningByAssignments");
	Result.Add("UseCalculationBySalesSpeed");
	Result.Add("UseForMaterialsPlanning");
	Result.Add("Calendar");
	Result.Add("DemandForMaterials");
	Result.Add("PlanningProcessManagement");
	Result.Add("RecordedInBudgeting");
	Result.Add("BudgetingScenario");
	Return Result;

EndFunction

// List of statuses of the plans for the script
//
// Parameters:
//  Scenario - CatalogRef.SalesOperationsPlanningScenarios	 - The scenario in which you want to retrieve data.
// 
// Returns:
//  ValueList - List of plan statuses that are allowed to receive.
//
Function ListOfPlanStatuses(Scenario) Export 
	
	StatusesList = New ValueList;
	StatusesList.Add(Enums.PlanStatuses.AwaitingConfirmation);
	StatusesList.Add(Enums.PlanStatuses.Upholded);
	
	Return StatusesList;

EndFunction 

// Returns the work calendar used for calculating the launch dates of products and semi-finished products, as well as the timing of requirements for materials, types of RC and labor resources
//
// Parameters:
//  Scenario - CatalogRef.SalesOperationsPlanningScenarios	 - The scenario in which you want to retrieve data.
// 
// Returns:
//  CatalogRef.Calendars - Calendar
//
Function Calendar(Scenario) Export
	
	If ValueIsFilled(Scenario) Then
		Calendar = Common.ObjectAttributeValue(Scenario, "Calendar");
		If Not ValueIsFilled(Calendar) Then
			Calendar = Constants.MainEnterpriseCalendar.Get();
		EndIf;
	Else
		Calendar = Constants.MainEnterpriseCalendar.Get();
	EndIf;
	
	Return Calendar;
	
EndFunction

// Checks whether the calculation of material requirements, RC types, and labor resources is used for the selected scenario
//
// Parameters:
//  Scenario - CatalogRef.SalesOperationsPlanningScenarios	 - The scenario in which you want to retrieve data.
// 
// Returns:
//  Boolean - True if the calculation of requirements for materials, types of RC and labor resources is used
//
Function UseForMaterialsPlanning(Scenario) Export
	
	If Not ValueIsFilled(Scenario) Then
		Return False;
	EndIf;
	
	Query = New Query(
	"SELECT
	|	TRUE
	|FROM
	|	Catalog.SalesOperationsPlanningScenarios AS SalesOperationsPlanningScenarios
	|WHERE
	|	SalesOperationsPlanningScenarios.Ref = &Scenario
	|	AND SalesOperationsPlanningScenarios.UseForMaterialsPlanning
	|");
	Query.SetParameter("Scenario", Scenario);
	
	Return Not Query.Execute().IsEmpty();
	
EndFunction

#EndRegion

#Region Private

#Region InfobaseUpdate

#EndRegion

#EndRegion

#EndIf
