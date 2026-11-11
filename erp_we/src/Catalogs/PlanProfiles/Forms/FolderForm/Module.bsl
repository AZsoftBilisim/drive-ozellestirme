#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)

	If Parameters.Property("AutoTest_2") Then // Refund upon receipt of the form for analysis.
		Return;
	EndIf;
	
	UsePlanningOfGoodsStock = GetFunctionalOption("UsePlanningOfGoodsStock");
	
	If Object.DemandPlanning Then
		PlanningType = 1;
	ElsIf Object.PlanningOfGoodsStock Then
		PlanningType = 2;
	EndIf;
	
	If Not UsePlanningOfGoodsStock
		And Not Object.PlanningOfGoodsStock Then
		Items.PlanningType.ChoiceList.Delete(2);
	EndIf;
	
	FormEvents.OnCreateAtServer(ThisForm, Cancel, StandardProcessing);

EndProcedure

&AtClient
Procedure BeforeWrite(Cancel, WriteParameters)
	Object.DemandPlanning =  PlanningType = 1;
	Object.PlanningOfGoodsStock = PlanningType = 2;
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure Attachable_ExecuteOverridableCommand(Command)
	
	FormEventsClient.ExecuteOverridableCommand(ThisForm, Command);
	
EndProcedure

#EndRegion
