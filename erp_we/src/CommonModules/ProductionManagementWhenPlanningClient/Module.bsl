
////////////////////////////////////////////////////////////////////////////////
// OUP: Procedures of the subsystem of operational accounting of production
//
////////////////////////////////////////////////////////////////////////////////
//

#Region Public

#Region ManufacturingExecutionSystem

// Processes the decoding of the Gantt chart interval containing data about parallel
//  loading of the work center.
//
// Parameters:
//  Owner			 - ClientApplicationForm	 - the form in which the decryption is performed.
//  FormParameters		 - Structure		 - parameters of the selected interval.
//  StandardProcessing - Boolean			 - flag for standard decryption processing.
//
Procedure ProcessingIntervalDecryptionWithParallelLoading(Val Owner, Val FormParameters, StandardProcessing) Export
	
	StandardProcessing = False;
	
	OpenForm(
		"Report.OperationTimetableChart2_2.Form.DrillDownOfParallelLoadOfWorkCenter",
		FormParameters,
		Owner,,,,,
		FormWindowOpeningMode.LockOwnerWindow);
	
EndProcedure

// Defines the name of the event that is used to notify about changes in the operational schedule.
//
// Returns:
//  String - event name.
//
Function NameOfEventChangingOperationalSchedule() Export
	
	Return "CalculateOperationProductionTimetable";
	
EndFunction

#EndRegion

#EndRegion
