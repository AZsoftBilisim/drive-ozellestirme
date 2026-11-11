#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region EventHandlers

Procedure OnWrite(Cancel)
	
	If DataExchange.Load Then
		Return;
	EndIf;
	
	SetPrivilegedMode(True);
	
	ConstantValue = ThisObject.Value;
	
	Constants.UsePlanningByProductionResources.Set(
		ConstantValue = Enums.ProductionManagementMethod.SchedulingOfResourcesForProduction);
	
	Constants.UsePlanningByMaterialResources.Set(
		ConstantValue = Enums.ProductionManagementMethod.SchedulingOfResourcesForProduction
		Or ConstantValue = Enums.ProductionManagementMethod.DemandPlanningForMaterials);
	
	ProductionPlanning.CheckDisableRoutineTaskProductionScheduleCalculation();
	
	OrderStructureInternal.SetUseOfLocalTaskRulesClearingLoadingHistoryOfWorkCenterViews();
	
EndProcedure

#EndRegion

#EndIf
