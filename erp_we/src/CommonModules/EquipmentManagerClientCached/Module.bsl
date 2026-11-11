
#Region Internal

// Returns the name of the client computer.
// Gets the computer name from the session variable for the first time.
//
// Returns:
//  CatalogRef.Workplaces
//
Function CustomerWorkplace() Export
	
	Return EquipmentManagerServerCall.CustomerWorkplace();
	
EndFunction

// Returns the name of the client computer.
// Gets the computer name from the session variable for the first time.
//
// Parameters:
//  ClientID - String - Client ID for the workplace     
//  ComputerName - String - Computer name       
//  Web Client - Boolean Attribute of a WEB client
//
// Returns:
//  Array
Function FindWorkplacesById(ClientID, ComputerName, MACAddress) Export
	
	Return EquipmentManagerServerCall.FindWorkplacesById(ClientID, ComputerName, MACAddress);
	
EndFunction

// The function returns a structure with driver data.
//
// Parameters:
//  DriverID - CatalogRef.HardwareDrivers - ID of the driver.
//
// Returns:
//  Structure
Function HardwareDriverData(DriverID) Export
	
	Return EquipmentManagerServerCall.HardwareDriverData(DriverID);
	
EndFunction

// Isolated Connection Of External Components On The Client 
// Returns:
//  Boolean - Isolated
//
Function IsolatedConnectionOfExternalComponentsOnClient() Export
	
	Return EquipmentManagerServerCall.IsolatedConnectionOfExternalComponentsOnClient();
	
EndFunction

// Get Matching Equipment Types
//
// Returns:
//   Map -
//
Function CompatibilityOfEquipmentTypes() Export
	
	Return EquipmentManagerServerCall.CompatibilityOfEquipmentTypes();
	
EndFunction

// returns a dictionary of Attributes and possible names of driver manufacturer parameters
//
// Returns:
//  Structure - possible options for certain values of equipment parameters:
//   * LogEnabled - Structure - flag whether the log file is enabled
//   * LogPath  - Structure - Path To The Log File
//   * PrintDoc - Structure - Print documents on cash register tape
//   * PrintSlip - Structure - print a slip receipt at the acquiring terminal
//   * OfdServer - Structure - address of the server of the fiscal data operator 
//   * OfdPort - Structure - port of the fiscal data operator's server
Function DictionaryOfKeyProperties() Export
	
	DictionaryOfKeyProperties = New Structure();
	
	Dictionary = New Structure();
	DictionaryOfKeyProperties.Insert("LogEnabled", Dictionary);
	Dictionary.Insert("DebugLog");
	Dictionary.Insert("LogEnabled");
	Dictionary.Insert("DebugLogEnabled");
	Dictionary.Insert("SaveLog");
	Dictionary.Insert("Debug");
	Dictionary.Insert("DebugLogEnabled");
	Dictionary.Insert("EnableLog");
	Dictionary.Insert("log_use");
	Dictionary.Insert("EventLogging");
	Dictionary.Insert("EnableDebugLog");
	
	Dictionary = New Structure();
	DictionaryOfKeyProperties.Insert("LogPath", Dictionary);
	Dictionary.Insert("LogFilePath");
	Dictionary.Insert("LogErrorPath");
	Dictionary.Insert("LogPath");
	Dictionary.Insert("LogFilePath");
	Dictionary.Insert("LogFileName");
	
	Dictionary = New Structure();
	DictionaryOfKeyProperties.Insert("PrintDoc", Dictionary);
	Dictionary.Insert("PrintDoc");
	Dictionary.Insert("PrintDocOnReceiptPaper");
	Dictionary.Insert("NoRecPrint", "Invert");
	
	Dictionary = New Structure();
	DictionaryOfKeyProperties.Insert("PrintSlip", Dictionary);
	Dictionary.Insert("PrintSlip");
	Dictionary.Insert("PrintSlipOnTerminal");
	Dictionary.Insert("pos_slip");
	Dictionary.Insert("TerminalPrintSlip");
	
	Dictionary = New Structure();
	DictionaryOfKeyProperties.Insert("OfdServer", Dictionary);
	Dictionary.Insert("OfdHostPort");
	Dictionary.Insert("OfdServer");
	Dictionary.Insert("DeviceOfdHost");
	Dictionary.Insert("OFDURL");
	Dictionary.Insert("ofdAddress");
	Dictionary.Insert("OFDAddr");
	
	Dictionary = New Structure();
	DictionaryOfKeyProperties.Insert("OfdPort", Dictionary);
	Dictionary.Insert("OfdServerPort");
	Dictionary.Insert("DeviceOfdPort");
	Dictionary.Insert("OFDPort");
	Dictionary.Insert("PortFDO");
	
	Return DictionaryOfKeyProperties;
	
EndFunction

// Refunds without a card are available.       
//
Function AvailableReturnsWithoutCard() Export
	
	Return EquipmentManagerServerCall.AvailableReturnsWithoutCard();
	
EndFunction  

Function ParametersTypesOfEquipment() Export
	
	Return EquipmentManagerServerCall.ParametersTypesOfEquipment();
	
EndFunction

#EndRegion