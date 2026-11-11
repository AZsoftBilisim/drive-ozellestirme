
#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region Internal

// Saves the place of batches in the order structure.
// 
// Parameters:
//  Table - ValueTable - Batch Data
//  
Procedure RecordNewLotReferences(Table) Export
	
	If Table.Count() = 0 Then
		Return;
	EndIf;
	
	SetPrivilegedMode(True);
	
	RecordSet = InformationRegisters.LocationOfLaunchedLotAndStagesInOrderStructure.CreateRecordSet();
	RecordSet.Load(Table);
	RecordSet.Write(False);
	
EndProcedure

#EndRegion

#EndIf
