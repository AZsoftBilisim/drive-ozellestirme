#Region Public

#Region ProceduresAndFunctionsOfProcessingOnServerOfEventsFromMobileApplication

// Gets the mobile app stored in the IB.
//
// Parameters:
//  UserName - String - name of the user to get the app for.
//  MobileComputerCode - String - code of the computer that you want to get the app for.
//  DataExchangeParameters - String - an xml string containing the parameters for data exchange.
//
// Returns:
//  String - a mobile application in the form of an encoded string.
//
Function GetApplication(UserName, MobileComputerCode, DataExchangeParameters = "") Export
	
	MobileApplicationManager = DataProcessors.MobileApplicationManager.Create();
	Return MobileApplicationManager.GetMobileApp(UserName, MobileComputerCode, DataExchangeParameters);
	
EndFunction

// Returns data selected from the IB in accordance with the exchange scheme set for the user.
//
// Parameters:
//  UserName - String - name of the user of the mobile app that you want to get information about.
//  MobileComputerCode - String - code of the mobile computer for which data is requested.
//  InitialIBInitialization - Boolean - indicates that the mobile information system is being initialized initially.
//  DataExchangeParameters - String - XMl string of parameters defined in the mobile app.
//   
// Returns:
//  String - information security data in the form of a string.
//
Function GetData(UserName, MobileComputerCode, Val InitialIBInitialization = False, DataExchangeParameters = "") Export
	
	MobileApplicationManager = DataProcessors.MobileApplicationManager.Create();
	Return MobileApplicationManager.GetData(UserName, MobileComputerCode, InitialIBInitialization, DataExchangeParameters);
	
EndFunction

// Writes data received from the mobile app to the current is.
//
// Parameters:
//  UserName - String - name of the mobile app user whose data needs to be recorded.
//  MobileComputerCode - String - code of the mobile computer from which the data was received.
//  MobileApplicationData - String - a string containing XML-serialized data received from the mobile app.
//  DataExchangeParameters - String - XMl string of parameters defined in the mobile app.
//
Procedure WriteData(UserName, MobileComputerCode, MobileApplicationData, DataExchangeParameters = "") Export
	
	MobileApplicationManager = DataProcessors.MobileApplicationManager.Create();
	MobileApplicationManager.WriteData(UserName, MobileComputerCode, MobileApplicationData, DataExchangeParameters);
	
EndProcedure

// Reflects the fact that the mobile client received data in the information security system.
//
// Parameters:
//  UserName - String - name of the mobile app user to register for receiving data.
//  MobileComputerCode - String - code of the mobile computer that you want to register receiving data from.
//  DataExchangeParameters - String - XMl string of parameters defined in the mobile app.
//
Procedure RegisterDataReceipt(UserName, MobileComputerCode, DataExchangeParameters = "") Export
	
	MobileApplicationManager = DataProcessors.MobileApplicationManager.Create();
	MobileApplicationManager.RegisterDataReceipt(UserName, MobileComputerCode, DataExchangeParameters);
	
EndProcedure

// Authenticates the mobile user.
//
// Parameters:
//  UserName - String - name of the mobile app user to register for receiving data.
//  MobileComputerCode - String - code of the mobile computer that is being authenticated.
//  UserPassword - String - the password for the mobile user.
//   
// Returns:
//  Boolean - authentication result: True - authentication is performed, False - authentication is not performed.
//
Function AuthenticationCompleted(UserName, MobileComputerCode, UserPassword) Export
	
	MobileApplicationManager = DataProcessors.MobileApplicationManager.Create();
	Return MobileApplicationManager.Authenticate(UserName, MobileComputerCode, UserPassword);
	
EndFunction

#EndRegion

#Region ProceduresAndFunctionsForWorkingWithExchangeSettingsAndParameters

// Gets the user's settings.
//
// Returns:
//  Arbitrary - user settings.
//
Function GetUserSettingsForDataExchangeComponent() Export
	
	Settings = New ValueList();
	
	If AccessRight("SaveUserData", Metadata) Then
		
		SettingsList = CommonSettingsStorage.GetList("UserSettingsForDataExchangeComponent");
		
		For Each Item In SettingsList Do
			SettingsKey = Item.Value;
			SettingValue = CommonSettingsStorage.Load("UserSettingsForDataExchangeComponent", SettingsKey);
			If SettingValue <> Undefined Then
				Settings.Add(SettingValue, SettingsKey);
			EndIf;
		EndDo;
		
	EndIf;
	
	Return Settings;
	
EndFunction

#EndRegion

#EndRegion
