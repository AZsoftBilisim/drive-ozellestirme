#Region Internal

// Information about connecting the local database to the support service
// 
// Returns:
//  Structure - contains fields:
//  	* AddressOfExternalAnonymousInterface - String - the address of the ext_sd http service of the support service
//  	* AddressOfAnonymousIntegrationServiceWithUSPInformationCenter - String - the address of the support service web service
//  	* ConfirmedCodeForIntegrationOfSUSPS - Boolean - if True, then the database is connected to the support service
//  	* SubscriberSEmailAddressForSuspIntegration - String - E-mail of the user 
//			on whose behalf the local database is connected to the support service
//  	* WUSPRegistrationCode - String - The code with which the database is registered in the support service
//
Function DataForSuspIntegrationSettings() Export
	
	Return InformationCenterServer.DataForSuspIntegrationSettings();
	
EndFunction

// Checks the user's code for working with the support service.
//
// Parameters:
//  UserCode	 - String - the code being checked
//  Email			 - String - e-mail of the user whose code is being checked
// 
// Returns:
//  Structure - With Fields:
//  	* CodeIsCorrect - Boolean
//  	* MessageText - String - filled in if the code is incorrect
//
Function CheckUserCode(UserCode, Email) Export
	
	Return InformationCenterServer.CheckUserCode(UserCode, Email);
	
EndFunction


// User's email address for handling requests
// 
// Returns:
//  String - e-mail
//
Function UserEmail() Export
	
	Return UsersInternal.UserDetails(Users.AuthorizedUser()).Email;
	
EndFunction

Procedure SaveUserCode(Val ComputerName = Undefined, 
	Val PartOfIBCode = "", Val TemporaryFileOfPieceOfCode) Export
	
	If ComputerName = Undefined Then // web client
		Return;
	EndIf;
	
	ComputerNameHash = CRC32HashSum(ComputerName);
	
	ComputerCode = New Structure;
	ComputerCode.Insert("PartOfVIBCode", PartOfIBCode);
	ComputerCode.Insert("TemporaryFileOfPieceOfCode", TemporaryFileOfPieceOfCode);
	
	CodesOnComputers = New Map;
	CodesOnComputers.Insert(ComputerNameHash, ComputerCode);
	
	SetSafeModeDisabled(True);
	SetPrivilegedMode(True);
	
	Common.WriteDataToSecureStorage(
		Users.CurrentUser(), CodesOnComputers, "AuthorizationDataInSupportService");
	
EndProcedure

// Read the user code.
// 
// Parameters:
//  ComputerName - String - computer name
// 
// Returns:
//  String - user code.
Function ReadUserCode(Val ComputerName) Export
	
	SetSafeModeDisabled(True);
	SetPrivilegedMode(True);
	
	CodesOnComputers = Common.ReadDataFromSecureStorage(
		Users.CurrentUser(), "AuthorizationDataInSupportService");
		
	If CodesOnComputers = Undefined Then
		Return "";
	EndIf;
		
	ComputerNameHash = CRC32HashSum(ComputerName);
	
	ComputerCode = CodesOnComputers.Get(ComputerNameHash);
	
	If ComputerCode = Undefined Then
		Return "";
	EndIf;
	
	If Type(ComputerCode) <> Type("Structure") Then
		Return "";
	EndIf;
	
	If Not ComputerCode.Property("PartOfVIBCode") 
		Or Not ValueIsFilled(ComputerCode.PartOfVIBCode) Then
		Return "";
	EndIf;
	
	If Not ComputerCode.Property("TemporaryFileOfPieceOfCode") 
		Or Not ValueIsFilled(ComputerCode.TemporaryFileOfPieceOfCode) Then
		Return "";
	EndIf;
	
	Return ComputerCode;
	
EndFunction

// Records the warning in the LR.
//
Procedure WriteWarning(WarningText) Export
	
	WriteLogEvent(
		InformationCenterServer.GetEventNameForLog(), 
		EventLogLevel.Warning,,,
		WarningText);
		
EndProcedure

#EndRegion

#Region Private

// Returns the hash sum of the data according to the CRC32 algorithm.
//
// Parameters:
//   Data - String, BinaryData - data for calculation.
//
// Returns:
//   Number - the hash amount calculated using the CRC32 algorithm.
//
Function CRC32HashSum(Data)

	DataHashing = New DataHashing(HashFunction.CRC32);
	DataHashing.Append(Data);
	
	Return DataHashing.HashSum;

EndFunction

#EndRegion