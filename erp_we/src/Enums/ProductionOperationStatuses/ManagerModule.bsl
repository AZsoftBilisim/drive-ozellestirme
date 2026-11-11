#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region Public

// List of working Statuses of operation
// 
// Returns:
//  Array of EnumRef.ProductionOperationStatuses
Function Workers() Export
	
	Result = New Array;
	
	Result.Add(Enums.ProductionOperationStatuses.CreatedOn_);
	Result.Add(Enums.ProductionOperationStatuses.Running);
	Result.Add(Enums.ProductionOperationStatuses.Executed);
	Result.Add(Enums.ProductionOperationStatuses.NotExecuted);
	Result.Add(Enums.ProductionOperationStatuses.IsSkipped);
	
	Return Result;
	
EndFunction

#EndRegion

#EndIf
