////////////////////////////////////////////////////////////////////////////////
// Production Management: Contains procedures for production management.
// The module is part of the "Enterprise Management" subsystem.
// 
////////////////////////////////////////////////////////////////////////////////
//

#Region Public

#Region SchedulePlanning

// Initiates planning of the order production schedule.
//
// Parameters:
//  PlanningSettings - Structure - schedule planning settings.
//  StorageAddress - UUID, String - the address in the temporary storage
//		where you want to place the planning results.
//
Procedure PlanPreliminarySchedule(PlanningSettings, StorageAddress) Export

	DataProcessors.ProductionSchedulePlanning2_2.PlanPreliminarySchedule(
		PlanningSettings,
		StorageAddress);
	
EndProcedure

// Called after filling in the planning parameters before calculating the production schedule.
//
// Parameters:
//  PlanningParameters - Structure - schedule planning parameters.
//
Procedure AfterFillingInPlanningParameters(PlanningParameters) Export
	
	Return; // Redefined procedure
	
EndProcedure

// Called after calculating the production schedule before recording it.
//
// Parameters:
//  PlanningParameters - Structure - schedule planning parameters.
//
Procedure BeforeRecordingPlanningResults(PlanningParameters) Export
	
	Return; // Redefined procedure
	
EndProcedure

#EndRegion

#EndRegion
