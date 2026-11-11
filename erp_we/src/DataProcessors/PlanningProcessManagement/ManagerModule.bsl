#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region Public

// Fills in deficit plans for multiple periods
//
Procedure FillInDeficitPlansByPeriod(Parameters, StorageAddress) Export
	
	Query = New Query;
	Query.Text = 
	"SELECT DISTINCT
	|	CalculationOfPlanShortagesByStages.Scenario AS Scenario,
	|	CalculationOfPlanShortagesByStages.PlanProfile AS PlanProfile,
	|	CalculationOfPlanShortagesByStages.PlanningPeriod AS PlanningPeriod,
	|	ENDOFPERIOD(CalculationOfPlanShortagesByStages.PlanningPeriod, MONTH) AS EndOfPlanPeriod
	|FROM
	|	InformationRegister.CalculationOfPlanShortagesByStages AS CalculationOfPlanShortagesByStages
	|WHERE
	|	CalculationOfPlanShortagesByStages.Scenario = &Scenario
	|	AND CalculationOfPlanShortagesByStages.PlanProfile IN(&PlanProfiles)
	|	AND CalculationOfPlanShortagesByStages.ShouldRecalculate
	|	AND CalculationOfPlanShortagesByStages.PlanningPeriod BETWEEN &BeginOfPeriod AND &PeriodEnding
	|
	|ORDER BY
	|	PlanningPeriod";
	Query.Text = StrReplace(Query.Text, "MONTH", String(Parameters.Periodicity));
	
	Query.SetParameter("Scenario", Parameters.Scenario);
	Query.SetParameter("PlanProfiles", Parameters.PlanProfiles);
	Query.SetParameter("BeginOfPeriod", Parameters.BeginOfPeriod);
	Query.SetParameter("PeriodEnding", Parameters.PeriodEnding);
	
	ConversionTable = Query.Execute().Unload();
	
	For Each String In ConversionTable Do
		Planning.FillOutDeficitPlans(String.Scenario, String.PlanProfile, String.PlanningPeriod, String.EndOfPlanPeriod); 
	EndDo;
	
EndProcedure

// Fills in deficit plans for multiple periods
//
Procedure RunTheRecalculationOfShortagesInStagesForAllThePeriods(Parameters, StorageAddress) Export
	
	Planning.StartingBackgroundRecalculationOfDeficitInStages(Parameters.Scenario);
	
EndProcedure



// Starts recalculation for the Planning Assistant
// 
// Parameters:
// 	Parameters - Structure - Where:
// 	*Scenario - CatalogRef.SalesOperationsPlanningScenarios
// 	*PlanProfile - CatalogRef.PlanProfiles
// 	*BeginOfPeriod - Date
// 	*PeriodEnding - Date
// 	StorageAddress - String
Procedure RecalculationPlanningAssistant(Parameters, StorageAddress) Export
	
	
	Scenario = Parameters.Scenario;
	PlanProfile = Parameters.PlanProfile;
	BeginOfPeriod = Parameters.BeginOfPeriod;
	PeriodEnding = Parameters.PeriodEnding;
	
	Planning.FillOutDeficitPlans(Scenario, PlanProfile, BeginOfPeriod, PeriodEnding);
	
EndProcedure
#EndRegion

#EndIf
