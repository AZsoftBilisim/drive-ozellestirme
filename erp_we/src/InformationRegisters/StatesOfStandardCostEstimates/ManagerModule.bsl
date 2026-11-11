
#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region Public	

// Records the state of the calculation.
// Parameters:
//	StandardCostEstimate - DocumentRef.StandardCosting2_2 - calculation for which you need to set the status.
//	State - EnumRef.StatesOfStandardCostEstimateCalculation - new state.
//
Procedure SetState(StandardCostEstimate, State) Export
	
	RecordSet = InformationRegisters.StatesOfStandardCostEstimates.CreateRecordSet();
	RecordSet.Filter.StandardCostEstimate.Set(StandardCostEstimate);
	
	If ValueIsFilled(State) Then
		
		NewRecord = RecordSet.Add();
		NewRecord.StandardCostEstimate = StandardCostEstimate;
		NewRecord.State = State;
		
	EndIf;
	
	SetPrivilegedMode(True);
	RecordSet.Write();
	SetPrivilegedMode(False);
	
EndProcedure

#EndRegion

#EndIf
