#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region EventHandlers

Procedure BeforeWrite(Cancel, WriteMode, PostingMode)
	
	If DataExchange.Load Then
		Return;
	EndIf;

	InfobaseUpdate.CheckObjectProcessed(ThisObject);
	
	If DeletionMark Then
		If Status <> Enums.StatusesOfBudgetingProcess.Completed Then
			Status = Enums.StatusesOfBudgetingProcess.RolledBack_;
		EndIf;
	EndIf;
	
EndProcedure

Procedure OnWrite(Cancel)
	
	If DataExchange.Load Then
		Return;
	EndIf;
	
	If Status = Enums.StatusesOfBudgetingProcess.Running Then
		JobParameters = New Array();
		JobParameters.Add(BudgetingModel);
		JobParameters.Add(Ref);
		BackgroundJobs.Execute("BudgetingServer.BudgetTasksGeneration",JobParameters);
	EndIf;
	
EndProcedure

#EndRegion

#EndIf