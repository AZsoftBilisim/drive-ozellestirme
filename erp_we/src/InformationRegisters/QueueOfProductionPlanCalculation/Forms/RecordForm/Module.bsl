
#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)

	SetConditionalAppearance();
	
	If Parameters.Property("AutoTest_2") Then // Refund upon receipt of the form for analysis.
		Return;
	EndIf;
	
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure AddJob(Command)
	
	If Not CheckFilling() Then
		Return;
	EndIf;
	
	AddTaskOnServer(ProductionPlan, CompleteRecalculation, AutoStart);
	
	Close();
	
EndProcedure

#EndRegion

#Region Private

&AtServer
Procedure SetConditionalAppearance()
	
	// no additional actions are provided
	Return;
	
EndProcedure

&AtServerNoContext
Procedure AddTaskOnServer(ObjectOfARAP, CompleteRecalculation, AutoStart)
	
	Scenario = Common.ObjectAttributeValue(ObjectOfARAP, "Scenario");
	InformationRegisters.QueueOfProductionPlanCalculation.AddJob(Scenario, ObjectOfARAP, AutoStart)
	
EndProcedure

#EndRegion

