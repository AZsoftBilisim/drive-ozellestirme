
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
Procedure CompleteTheJob(Command)
	
	CurrentData = Items.List.CurrentData;
	If CurrentData = Undefined Then
		Return;
	EndIf;
	
	RunTaskOnServer(CurrentData.ProductionPlan);
	
EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

&AtClient
Procedure ListBeforeRowChange(Item, Cancel)
	
	Cancel = True;
	
EndProcedure

#EndRegion

#Region Private

&AtServer
Procedure SetConditionalAppearance()
	
	// no additional actions are provided
	Return;
	
EndProcedure

&AtServerNoContext
Procedure RunTaskOnServer(ProductionPlan)

	ProductionServer.StartQueueProcessingJob("QueueOfProductionPlanCalculation", New Structure("ProductionPlan", ProductionPlan));
	
EndProcedure

#EndRegion
