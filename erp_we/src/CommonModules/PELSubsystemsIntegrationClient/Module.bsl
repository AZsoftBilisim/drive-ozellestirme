#Region Public

#Region EventHandlersSSL
// Processing of program events occurring in BSP subsystems.

// Defines events that this library is subscribed to.
//
// Parameters:
//  Subscriptions - Structure - the structure property keys are the names of events that
//           this library subscribes to.
//
Procedure OnDefineEventSubscriptionsSSL(Subscriptions) Export
	
	// Core
	Subscriptions.BeforeStart = True;
	Subscriptions.OnStart = True;
	Subscriptions.BeforeExit = True;
	
EndProcedure

// A function that is called before the system starts working.
//
Procedure BeforeStart() Export
	
	If CommonCELClient.DataSeparationEnabled() 
		And Not CommonCELClient.SeparatedDataUsageAvailable() Then
		Return;
	EndIf;
	
	ClientRunParameters = ClientParametersOnStart();
	PrepareApplicationParameters(ClientRunParameters);
	
EndProcedure

// Function called when the system starts working.
//
Procedure OnStart() Export
	
	If CommonCELClient.DataSeparationEnabled() 
		And Not CommonCELClient.SeparatedDataUsageAvailable() Then
		Return;
	EndIf;
	
	ClientRunParameters = ClientParametersOnStart();
	PrepareApplicationParameters(ClientRunParameters);
	
#If MobileAppClient Or MobileClient Then
	CreateAWorkplace = True;
	EquipmentManagerClient.DefineWorkplace(CreateAWorkplace);
#Else
	// ++ Non-mobile application
	WorkplaceParameters = ClientRunParameters.WorkplaceParameters;
	RDPModeIsUsed = WorkplaceParameters.RDPIsUsed And Not CommonCELClient.IsWebClient();
	If RDPModeIsUsed Then
		EquipmentManagerClient.DefineRDPWorkplace();
	Else
		EquipmentManagerClient.DefineWorkplace();
		Notification = New CallbackDescription("ReceivedMACAddressAtStartup", ThisObject);
		InstallBrowserExtension = False;
		LaunchingApplication = True;
		EquipmentManagerClient.BeginGettingMACAddresses(Notification, InstallBrowserExtension, LaunchingApplication);
	EndIf;
	// -- Non-mobile application
#EndIf
	
	// ++ Non-mobile application
#If Not WebClient Then
	AddInsCELClient.ReinstallComponents(ClientRunParameters.EquipmentForReinstalling);
	If CommonCELClient.DistributedFiscalizationIsUsed() Then
		ModuleDistributedFiscalizationClient = CommonCELClient.CommonModule("Distributed_FiscalizationClient");
		ModuleDistributedFiscalizationClient.ConnectingInteractionSystem(ClientRunParameters.IdOfDistributedFiscalizationDiscussion); 
	EndIf;
#EndIf
	// -- Non-mobile application
	TransferIntervalATServer = 60;
	AttachIdleHandler("ConnectedEquipment_DataExchangeWithServer", TransferIntervalATServer);
	
EndProcedure

// The procedure called at the start of the system performs the preparation of the mechanism data.
// 
// Parameters:
//  Cancel - Boolean
//  Warnings - String 
//                 - Array of Structure
//
Procedure BeforeExit(Cancel = False, Warnings = "") Export
	
EndProcedure

#EndRegion

#Region InterfaceImplementation

// See StandardSubsystemsClient.OnReceiptServerNotification
Procedure OnReceiptServerNotification(NameOfAlert, Result) Export
	
	If NameOfAlert = EquipmentManagerClientServer.KeyForRequestingDriverLogArchive() Then

		EquipmentManagerClient.ProcessRequestForArchiveOfDriverLogs(Result, Undefined);
		
	ElsIf NameOfAlert = EquipmentManagerClientServer.KeyForRespondingToRequestForDriverLogArchive() Then

		EquipmentManagerClient.ProcessResponseToRequestForDriverLogArchive(Result);
		
	EndIf;
	
EndProcedure

// Performs processing of an external event, called from the global module
//
// Parameters:
//  Source - String
//  Event - String
//  Data - String
Procedure ExternEventProcessing(Source, Event, Data) Export

	ErrorDescription  = "";
	// Prepare data
	EventDescription1 = New Structure();
	EventDescription1.Insert("Source", Source);
	EventDescription1.Insert("Event",  Event);
	EventDescription1.Insert("Data",   Data);
	// Submit the data for processing.
	Result = EquipmentManagerClient.ProcessEventFromDevice(EventDescription1, ErrorDescription);
	If Not Result Then
		CommonCELClient.MessageToUser(NStr("vi = 'Đã xảy ra lỗi khi xử lý sự kiện bên ngoài từ thiết bị.';
											|ru = 'При обработке внешнего события от устройства произошла ошибка.';
											|en = 'An error occurred when processing an external event from the device.'; fa = 'An error occurred when processing an external event from the device.';
											|it = 'Errore durante l''elaborazione di un evento esterno al dispositivo.';
											|pl = 'Przy przetwarzaniu zdarzenia zewnętrznego od urządzenia zaistniał błąd.';
											|tr = 'Harici olayın cihazdan işlenmesi sırasında bir hata oluştu.'") + Chars.LF + ErrorDescription);
	EndIf;
	
EndProcedure

#EndRegion

#EndRegion

#Region Internal

// Returns the values of parameters required for the client configuration code
// to work without additional server calls.
// 
// Returns:
//   Structure:
//     * CurrentDateOnClient - Date
Function ClientParametersOnStart() Export
	
	If CommonCELClient.BSPIsUsed() Then
		ClientRunParameters = CommonCELClient.ClientParametersOnStart();
		If ClientRunParameters.Property("EquipmentForReinstalling") Then
			Return ClientRunParameters;
		EndIf;
	EndIf;
	
	Return PELSubsystemsIntegrationClientCached.ClientParametersOnStart();
	
EndFunction

Procedure ReceivedMACAddressAtStartup(MACAddress, Parameters) Export
	
	CreateAWorkplace = True;
	EquipmentManagerClient.DefineWorkplace(CreateAWorkplace);
	
EndProcedure

#EndRegion

#Region Private

Procedure PrepareApplicationParameters(ClientRunParameters)
	
	If ApplicationParameters = Undefined Then
		ApplicationParameters = New Map();
	EndIf;
	Peripherals = EquipmentManagerClient.Peripherals();
	
	If Not CommonCELClient.BSPIsUsed() Then
		ParameterName = "BPO.ConfigurationSubsystems";
		If ApplicationParameters[ParameterName] = Undefined Then
			ApplicationParameters.Insert(ParameterName, ClientRunParameters.SubsystemsNames);
		EndIf;
		
		Peripherals.SessionTimeOffset = ClientRunParameters.SessionTimeOffset;
		
	EndIf;
	
	ParameterName = "BPO.SSLVersion";
	If ApplicationParameters[ParameterName] = Undefined Then
		ApplicationParameters.Insert(ParameterName, ClientRunParameters.SSLVersion);
	EndIf;
	
	ParameterName = "BPO.CompatibilityOfEquipmentTypes";
	If ApplicationParameters[ParameterName] = Undefined Then
		ApplicationParameters.Insert(ParameterName, ClientRunParameters.CompatibilityOfEquipmentTypes);
	EndIf;
	
	ParameterName = "BPO.AvailableTypesOfEquipment";
	If ApplicationParameters[ParameterName] = Undefined Then
		ApplicationParameters.Insert(ParameterName, ClientRunParameters.AvailableTypesOfEquipment);
	EndIf;
	
	Peripherals.WorkplaceParameters = 
		CommonCELClient.CopyRecursive(ClientRunParameters.WorkplaceParameters, False);
		
	Peripherals.LibraryVersion = ClientRunParameters.LibraryVersion;
		
	If CommonCELClient.LoggingSubsystemIsUsed() Then
		If Peripherals.LoggingSystem = Undefined Then
			ModuleLoggingOfOperationsOfBPOClient = CommonCELClient.CommonModule("LoggingOfCELOperationsClient");
			Peripherals.LoggingSystem = ModuleLoggingOfOperationsOfBPOClient.NewLoggingSystem(ClientRunParameters.ParametersForLoggingHardwareOfOperations);
		EndIf;
	EndIf;
	
	Peripherals.LibraryClassifiers = ClientRunParameters.LibraryClassifiers;
	Peripherals.ClientNotificationsAreAvailable = ClientRunParameters.ClientNotificationsAreAvailable;
	
EndProcedure

#EndRegion

