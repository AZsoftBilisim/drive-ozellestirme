#Region Internal

// Creates a structure and fills in the parameters of the client's work on the server
// The standard Minimizes the number of server calls and traffic.
//
// Returns:
//   Structure:
//     * CurrentDateOnClient - Date
Function ClientParametersOnStart() Export
	
	Parameters = New Structure();
	Parameters.Insert("CurrentDateOnClient", CurrentDate()); // APK:143 The current date() is required to calculate the correction of the session time
	PELSubsystemsIntegrationInternalServerCall.OnAddClientParametersOnStart(Parameters);
	Return Parameters;
	
EndFunction

#EndRegion

