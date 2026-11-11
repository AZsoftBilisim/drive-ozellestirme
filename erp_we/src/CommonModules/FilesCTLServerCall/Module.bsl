//@strict-types

#Region Internal

// Send the next batch of data to the server.
// 
// Parameters:
//  FileNameAtServer - String - The name of the file on the server
//  FileData - BinaryData - Binary file data
//  Begin - Number - Start recording file data
Procedure SendAnotherPortion(FileNameAtServer, FileData, Begin) Export
	
	FilesCTL.SendAnotherPortion(FileNameAtServer, FileData, Begin);
	
EndProcedure

Function ImportToServiceAvailable() Export
	
	Return ServiceProgrammingInterface.InterfaceVersionProperties().Version >= 27
		And SaaSOperations.AccessTokenAuthenticationOfInternalAPIRequests();
	
EndFunction

#EndRegion
