#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region Public

// Adds tasks to the convolution of the reverse entries in the registers of the production schedule
// 
// Parameters:
// 	RegisterRecords - ValueTable - tasks for calculation.
// 	FieldName - String - the name of the field in which the set ID is written.
//
Procedure AddTasks(RegisterRecords, FieldName) Export

	SetPrivilegedMode(True);

	RecordSet = InformationRegisters.TasksOfRecordStornoRollupInProductionSchedule.CreateRecordSet();
	
	Jobs = RecordSet.UnloadColumns("SetID");
	
	PreKey = Undefined;
	
	For Each String In RegisterRecords Do
		
		If Not String.AdditionalRecord Then
			Continue;
		EndIf;
		
		If String[FieldName] = PreKey Then
			Continue;
		EndIf;
		
		Jobs.Add().SetID = String[FieldName];
		
		PreKey = String[FieldName];
		
	EndDo;
	
	If Jobs.Count() > 0 Then
		
		Jobs.GroupBy("SetID");
		
		OrderStructure.FillInAndRecordSetOfRecords(
			RecordSet,
			Jobs,
			False,
			True);
			
	EndIf;
	
EndProcedure

// Deletes the completed tasks for the convolution of the reverse entries in the registers of the production schedule by separator
// 
// Parameters:
// 	Separator - UUID - the record separator.
//
Procedure DeleteTasks(Separator) Export

	SetPrivilegedMode(True);

	RecordSet = InformationRegisters.TasksOfRecordStornoRollupInProductionSchedule.CreateRecordSet();
	
	RecordSet.Filter.Separator.Set(Separator);
	
	RecordSet.Write(True);
	
EndProcedure

#EndRegion

#EndIf