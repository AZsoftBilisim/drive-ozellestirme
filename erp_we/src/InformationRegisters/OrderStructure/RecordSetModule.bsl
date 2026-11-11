#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region EventHandlers

Procedure BeforeWrite(Cancel, Replacing)
	
	If DataExchange.Load Then
		Return;
	EndIf;
	
	EmptyStage = Catalogs.ProductionStages.EmptyRef();
	
	For Each String In ThisObject Do
		String.Stage = ?(ValueIsFilled(String.Stage), String.Stage, EmptyStage);
	EndDo;
	
EndProcedure

Procedure OnWrite(Cancel, Replacing)
	
	If DataExchange.Load Then
		Return;
	EndIf;
	
	If Replacing = False Then
		InformationRegisters.TasksOfRecordStornoRollupInProductionSchedule.AddTasks(ThisObject, "KeySet");
	EndIf;
	
EndProcedure

#EndRegion

#EndIf
