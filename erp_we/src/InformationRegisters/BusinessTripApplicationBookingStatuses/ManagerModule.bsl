#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region Public

// Sets the status for the request
//
// Parameters:
//    ApplicationForBusinessTrip - DocumentRef.ApplicationForBusinessTrip - Business trip request
//    StateOfApplication - EnumRef.BusinessTripApplicationBookingStatuses - Request status
//    ErrorInfo - String - Additional information
//
Procedure SetState(ApplicationForBusinessTrip, StateOfApplication, ErrorInfo = Undefined) Export
	
	SetPrivilegedMode(True);
	RecordManager = CreateRecordManager();
	RecordManager.Period = CurrentSessionDate();
	RecordManager.ApplicationForBusinessTrip = ApplicationForBusinessTrip;
	RecordManager.State = StateOfApplication;
	
	If ErrorInfo <> Undefined Then
		RecordManager.Comment = BriefErrorDescription(ErrorInfo);
	EndIf;
	
	RecordManager.Write();
	SetPrivilegedMode(False);
	
EndProcedure

// Defines requests for status updates in the booking service
// 
// Returns:
//    Array of DocumentRef.ApplicationForBusinessTrip
//
Function RequestsWithSentStatus() Export
	
	Query = New Query;
	Query.Text ="
	|SELECT
	|	RegisterData.ApplicationForBusinessTrip AS Ref
	|FROM
	|	InformationRegister.BusinessTripApplicationBookingStatuses.SliceLast AS RegisterData
	|WHERE
	|	RegisterData.State = VALUE(Enum.BusinessTripApplicationBookingStatuses.Sent_)
	|";
	
	Return Query.Execute().Unload().UnloadColumn("Ref");
	
EndFunction

#EndRegion

#EndIf
