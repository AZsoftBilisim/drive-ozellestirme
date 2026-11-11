#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region Private

// The address of the 1C system server used in information security:Analytics
// (Functions for a technician - Analytics system management).
// 
// Returns:
//  String - 1C system server address:Analytics.
//
Function ServerAddress() Export
	Return AnalyticsSystem.GetAnalyticsSystemServerAddress();
EndFunction

// Set the connection address of the 1C system server:Analytics.
// 
// Parameters:
//  ServerAddress - String - New 1C server address:Analytics.
// 
// Returns:
//  Boolean - New 1C server address:Analytics was installed successfully.
//
Function SetServerAddress(ServerAddress) Export
	
	CurCurrentServerAddress = ServerAddress();
	AnalyticsSystem.SetAnalyticsSystemServerAddress(ServerAddress);
	
	ServerIsAvailable = AnalyticsSystemServerIsAvailable();
	If Not AnalyticsSystemServerIsAvailable() Then
		AnalyticsSystem.SetAnalyticsSystemServerAddress(CurCurrentServerAddress);
	EndIf;
	
	Return ServerIsAvailable;
	
EndFunction

// Checks the server address of the 1C system:Analytics.
// 
// Parameters:
//  ServerAddress - String - New 1C server address:Analytics.
// 
// Returns:
//  Boolean - New 1C server address:Analytics was installed successfully.
//
Function CheckAvailabilityOfAnalyticsServerAt(ServerAddress) Export

	CurCurrentServerAddress = ServerAddress();
	AnalyticsSystem.SetAnalyticsSystemServerAddress(ServerAddress);
	
	ServerIsAvailable = AnalyticsSystemServerIsAvailable();
	AnalyticsSystem.SetAnalyticsSystemServerAddress(CurCurrentServerAddress);
	
	Return ServerIsAvailable;
	
EndFunction

// 1C system server availability:Analytics.
// 
// Returns:
//  Boolean - 1C system server:Analytics is available.
//
Function AnalyticsSystemServerIsAvailable() Export
	
	Try
		AnalyticsSystem.GetConnection().GetSchema("objects");
		Return True;
	Except
		Return False;
	EndTry;
	
EndFunction

// Clear the server address.
Procedure ClearServerAddress() Export
	
	AnalyticsSystem.SetAnalyticsSystemServerAddress("");
	
EndProcedure

#EndRegion

#EndIf