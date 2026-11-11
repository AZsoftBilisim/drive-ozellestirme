#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region Internal

Function Current() Export

	SetPrivilegedMode(True);
	Return Constants.CurrentBorderOfOrderStructureCalculationTasks.Get();
	
EndFunction

Function GetAndMove() Export
	
	SetPrivilegedMode(True);

	CalculationBoundary = -1;
	
	BeginTransaction();
	Try
		
		Block = New DataLock;
		LockItem = Block.Add("Constant.CurrentBorderOfOrderStructureCalculationTasks");
		LockItem.Mode = DataLockMode.Exclusive;
		Block.Lock();
		
		CalculationBoundary = Constants.CurrentBorderOfOrderStructureCalculationTasks.Get();
		NewCalculationBoundary = CalculationBoundary + 1;
		Constants.CurrentBorderOfOrderStructureCalculationTasks.Set(NewCalculationBoundary);
		
		
		CommitTransaction();
		
	Except
		RollbackTransaction();
		CalculationBoundary = -1;
		WriteLogEvent(OrderStructure.EventLogEventName(), EventLogLevel.Error,,,
			DetailErrorDescription(ErrorInfo()));
		Raise;
	EndTry;
	
	SetPrivilegedMode(False);
	
	Return CalculationBoundary;
	
EndFunction

#EndRegion

#EndIf
