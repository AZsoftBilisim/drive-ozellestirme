
#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region EventHandlers

Procedure OnWrite(Cancel)
	
	If DataExchange.Load Then
		Return;
	EndIf;
	
	SetPrivilegedMode(True);
	
	OrderStructure.InitializeOrderStructureCalculationSettings();
	
	OrderStructureInternal.SetUseOfLocalTaskRulesCalculationOfOrderStructure();
	OrderStructureInternal.SetUseOfLocalTaskRulesRegisterConvolutionOrderStructure();
	OrderStructureInternal.SetUseOfLocalTaskRulesClearingLoadingHistoryOfWorkCenterViews();
	
EndProcedure

#EndRegion

#EndIf
