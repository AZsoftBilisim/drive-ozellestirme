
#Region Private

// Checks the status of the background task by the passed ID.
// 
// Parameters:
//  JobID - UUID - ID of the background task. 
//
// Returns:
//  Boolean              - returns True if the task is completed successfully,
//                        False - if executed. In other cases, an exception is raised.
// 
Function JobCompleted(JobID) Export
	
	Return TimeConsumingOperations.JobCompleted(JobID);
	
EndFunction

// Retrieves the calculated number of excisable items from the temporary storage and returns
// the header text for the excisable field.
//
// Parameters:
//  Address - String - The address of data on the number of excisable items in the temporary storage.
//
// Returns:
//  String
//
Function FieldHeaderIsSubjectToExciseDuty(Address) Export
	
	NumberOfExcisableItems = 0;
	
	If IsTempStorageURL(Address) Then
		NumberOfExcisableItems = GetFromTempStorage(Address);
		DeleteFromTempStorage(Address);
	EndIf;
	
	FieldTitle = ExcisableGoodsAccountingClientServer.FieldHeaderIsSubjectToExciseDuty(
		NumberOfExcisableItems);
	
	Return FieldTitle;
	
EndFunction

#EndRegion
