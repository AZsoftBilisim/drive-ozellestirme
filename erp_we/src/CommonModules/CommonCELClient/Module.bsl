
#Region Public

// Returns the Cur date, the server is contacted to get the exact date.
//
// Returns:
//  Date - the current date of the session.
//
Function SessionDate() Export
	
	SessionDate = EquipmentManagerClientOverridable.SessionDate();
	If ValueIsFilled(SessionDate) Then
		Return SessionDate;
	EndIf;
	
	If BSPIsUsed() Then
		
		// Calling BSP
		ModuleCommonClient = CommonModule("CommonClient");
		Return ModuleCommonClient.SessionDate();
		// The end of the BSP Challenge
		
	EndIf;

	Adjustment = EquipmentManagerClient.Peripherals().SessionTimeOffset;
	SessionDate = CurrentDate() + Adjustment; // APK:143 Current date() for calculating session time
	Return SessionDate;
	
EndFunction

#Region WorkingWithXML

// The function reads the XML root element.
//
// Parameters:
//  XMLLine - String - XML string.
//
// Returns:
//  Structure
//
Function ReadRootXMLElement(XMLLine) Export
	
#If WebClient Then
	Return CommonCELInternalServerCall.ReadRootXMLElement(XMLLine);
#Else
	Return CommonCELClientServer.ReadRootXMLElement(XMLLine);
#EndIf
	
EndFunction          

#EndRegion

#Region Data

// Creates a complete copy of a structure, match, array, list, or table of values, recursively,
// with consideration for the types of child elements. However, the contents of object type values are
// (Reference object, document Object, etc.) are not copied, but references to the source object are returned.
//
// Parameters:
//  Source - Structure
//           - FixedStructure
//           - Map
//           - FixedMap
//           - Array
//           - FixedArray
//           - ValueList - the object to be copied.
//  FixData - Boolean       - if True, fix it, if False, remove the fixation.
//                    - Undefined - do not change.
//
// Returns:
//  Structure, 
//  Fixed Structure,
//  Accordance
//  Fixed Compliance
//  Array
//  Fixed Array
//  The list of values is a copy of the object passed in the Source parameter.
//
Function CopyRecursive(Source, FixData = Undefined) Export
	
	Var Receiver;
	
	SourceType = TypeOf(Source);
	
	If SourceType = Type("Structure")
		Or SourceType = Type("FixedStructure") Then
		Receiver = CopyStructure(Source, FixData);
	ElsIf SourceType = Type("Map")
		Or SourceType = Type("FixedMap") Then
		Receiver = CopyMap(Source, FixData);
	ElsIf SourceType = Type("Array")
		Or SourceType = Type("FixedArray") Then
		Receiver = CopyArray(Source, FixData);
	ElsIf SourceType = Type("ValueList") Then
		Receiver = CopyValueList(Source, FixData);
	Else
		Receiver = Source;
	EndIf;
	
	Return Receiver;
	
EndFunction

#EndRegion

#EndRegion

#Region Internal

// The function returns True if a library of standard subsystems is implemented
//
// Returns:
//  Boolean
Function BSPIsUsed() Export
	
	// Calling BSP
	Return ParameterOfApplication("StandardSubsystems.ClientParameters") <> Undefined;
	// The end of the BSP Challenge
	
EndFunction

// Returns the installed version of BSP, if BSP is not installed then
// returns "0.0.0.0"
//
// Returns:
//  String
Function SSLVersion() Export
	Return ParameterOfApplication("BPO.SSLVersion");
EndFunction

Function ParameterOfApplication(Val ParameterName) Export
	
	// Calling BSP
	If TypeOf(ApplicationParameters) = Type("Map") Then
		Return ApplicationParameters[ParameterName]; // A variable in the application module
	Else
		Return Undefined;
	EndIf;
	// The end of the BSP Challenge
	
EndFunction

Procedure Set_ApplicationParameter(Val ParameterName, Value) Export
	
	// Calling BSP
	If TypeOf(ApplicationParameters) = Type("Map") Then
		ApplicationParameters[ParameterName] = Value; // A variable in the application module
	EndIf;
	// The end of the BSP Challenge
	
EndProcedure

Procedure DeleteApplicationParameter(Val ParameterName) Export
	
	// Calling BSP
	If TypeOf(ApplicationParameters) = Type("Map") Then
		ApplicationParameters.Delete(ParameterName); // A variable in the application module
	EndIf;
	// The end of the BSP Challenge
	
EndProcedure

Function ClientParametersOnStart() Export
	
	// Calling BSP
	ModuleStandardClientSubsystems = CommonModule("StandardSubsystemsClient");
	Return ModuleStandardClientSubsystems.ClientParametersOnStart();
	// The end of the BSP Challenge
	
EndFunction

Function LoggingSystem() Export
	Return EquipmentManagerClient.Peripherals().LoggingSystem;
EndFunction

Function ThereIsDataForRecordingOfOperationsOfEquipment() Export
	
	LoggingSystem = LoggingSystem();
	If LoggingSystem = Undefined Then
		Return False;
	EndIf;
	
	If LoggingSystem.Records.Count() = 0 Then
		Return False;
	EndIf;

	Return True;
	
EndFunction

// Generates and outputs a message that can be associated with a form control.
//
// Parameters:
//   EventName - String
//   Comment - String, Undefined -
//   Var_Metadata - MetadataObject - 
//
Procedure WriteErrorToEventLog(EventName, Comment = Undefined, LevelPresentation = "Error", Var_Metadata = Undefined) Export
	
	If BSPIsUsed() Then
		
		// Calling BSP
		ClientRegistrationLogModule = CommonCELClient.CommonModule("EventLogClient");
		ClientRegistrationLogModule.AddMessageForEventLog(EventName, LevelPresentation, Comment);
		// The end of the BSP Challenge
		
	Else
		
		CommonCELInternalServerCall.WriteErrorToEventLog(EventName, Comment, LevelPresentation, Var_Metadata);
		
	EndIf;
	
EndProcedure

Procedure OpenURL(Ref) Export
	
	// Calling BSP
	ModuleFileSystemClient = CommonCELClient.CommonModule("FileSystemClient");
	ModuleFileSystemClient.OpenURL(Ref);
	// The end of the BSP Challenge
	
EndProcedure 

#Region UserNotification

// Generates and outputs a message that can be associated with a form control.
//
// Parameters:
//  MessageToUserText - String - message text.
//  DataKey - AnyRef - the object or key of the database record that this message refers to.
//  Field - String - name of the form's details.
//  DataPath - String - data path (the path to the requisite shape).
//  Cancel - Boolean - the output parameter is always set to True.
//@skip-check method-too-many-params
Procedure MessageToUser(Val MessageToUserText, Val DataKey = Undefined, Val Field = "",
	Val DataPath = "", Cancel = False) Export
	
	If BSPIsUsed() Then
		
		// Calling BSP
		ModuleCommonClient = CommonModule("CommonClient");
		ModuleCommonClient.MessageToUser(MessageToUserText, DataKey, Field, DataPath, Cancel);
		// The end of the BSP Challenge
		
	Else
		InformBPOUser(MessageToUserText, DataKey, Field, DataPath, Cancel);
	EndIf;
	
EndProcedure      

// Show a warning that the driver is not certified.
//
// Parameters:
//  ErrorDescription - String - Message text
//
Procedure ShowDriverNotCertifiedWarning(ErrorDescription = Undefined) Export
	
	EquipmentCertificateLink = "https://v8.1c.ru/tekhnologii/standartnye-biblioteki/1s-biblioteka-podklyuchaemogo-oborudovaniya/sertifitsirovannye-modeli-oborudovaniya/"; 
	
	MessageText = ?(IsBlankString(ErrorDescription), "", ErrorDescription + Chars.LF);
	MessageText = MessageText + NStr("vi = 'Chưa chứng nhận hoặc bỏ hỗ trợ driver thiết bị được sử dụng.';
									|ru = 'Используемый драйвер оборудования не сертифицирован или снят с поддержки.';
									|en = 'The used hardware driver is not certified or is no longer supported.'; fa = 'The used hardware driver is not certified or is no longer supported.';
									|it = 'The used hardware driver is not certified or is no longer supported.';
									|pl = 'The used hardware driver is not certified or is no longer supported.';
									|tr = 'Kullanılan donanım sürücüsü sertifikalı değildir veya desteği kaldırılmıştır.'") + Chars.LF +  
			NStr("vi = 'Vui lòng liên hệ với nhà cung cấp driver.';
				|ru = 'Пожалуйста, обратитесь к поставщику драйвера.';
				|en = 'Please contact the driver vendor.'; fa = 'Please contact the driver vendor.';
				|it = 'Please contact the driver vendor.';
				|pl = 'Please contact the driver vendor.';
				|tr = 'Lütfen sürücü sağlayıcısına başvurun.'") + Chars.LF +  
			NStr("vi = 'Có thể tham khảo danh sách các driver hiện hành và đã được chứng nhận ';
				|ru = 'Со списком актуальных, сертифицированных драйверов можно ознакомиться';
				|en = 'You can find the list of up-to-date certified drivers'; fa = 'You can find the list of up-to-date certified drivers';
				|it = 'You can find the list of up-to-date certified drivers';
				|pl = 'You can find the list of up-to-date certified drivers';
				|tr = 'Güncel, sertifikalı sürücülerin listesine şuradan ulaşabilirsiniz;'") + " ";
	RowsArray = New Array;
	RowsArray.Add(New FormattedString(MessageText));
	RowsArray.Add(New FormattedString(New FormattedString(NStr("vi = 'trên cổng 1C.';
																|ru = 'на портале 1С.';
																|en = 'on the 1C portal.'; fa = 'on the 1C portal.';
																|it = 'on the 1C portal.';
																|pl = 'on the 1C portal.';
																|tr = '1C portalı.'"),,,, EquipmentCertificateLink)));
	FormString_ = New FormattedString(RowsArray);
	ShowMessageBox(, FormString_);   
	
EndProcedure

#EndRegion
                                                               
#Region ConditionCalls

////////////////////////////////////////////////////////////////////////////////
// Procedures and functions for calling optional subsystems.

// Returns True if the functional subsystem exists in the configuration.
// It is intended for the implementation of an optional subsystem call (conditional call).
// 
// Parameters:
//   FullSubsystemName - String
//
// Returns:
//  Boolean - The truth, if it exists.
//
Function SubsystemExists(Val FullSubsystemName) Export
	
	If BSPIsUsed() Then
		
		// Calling BSP
		ModuleCommonClient = CommonModule("CommonClient");
		Return ModuleCommonClient.SubsystemExists(FullSubsystemName);
		// The end of the BSP Challenge
		
	Else
		ParameterName = "BPO.ConfigurationSubsystems";
		SubsystemsNames = ApplicationParameters[ParameterName];
		Return SubsystemsNames.Get(FullSubsystemName) <> Undefined;
	EndIf;
	
EndFunction

// Returns a reference to the shared module or Manager module by name.
//
// Parameters:
//  Name - String - name of the shared module.
//
// Returns:
//  CommonModule - the general module.
//
Function CommonModule(Val Name) Export
	
	Module = Eval(Name);
	
#If Not WebClient Then
	
	// It is not checked in the web client
	// because when accessing modules with a server call, the type of such module does not exist in the web client.
	
	If TypeOf(Module) <> Type("CommonModule") Then
		Raise StrTemplate(
			NStr("vi = 'Mô-đun chung ""%1"" không tồn tại.';
				|ru = 'Общий модуль ""%1"" не существует.';
				|en = 'Common module ""%1"" does not exist.'; fa = 'Common module ""%1"" does not exist.';
				|it = 'Modulo generale ""%1"" non esiste.';
				|pl = 'Moduł ogólny ""%1"" nie istnieje.';
				|tr = '""%1"" ortak modülü mevcut değil.'"), 
			Name);
	EndIf;
	
#EndIf
	
	Return Module;
	
EndFunction

Function ClientNotifications() Export
	
	Return Eval("ClientNotifications");
	
EndFunction

#EndRegion

#Region CurrentEnvironment

////////////////////////////////////////////////////////////////////////////////
// Functions describing the current environment of the client application and operating system.

// Returns True if the client application is running on Windows.
//
// Returns:
//  Boolean - if there is no client application, False is returned.
//
Function IsWindowsClient() Export
	
	ClientPlatformType = ClientPlatformType();
	Return ClientPlatformType = PlatformType.Windows_x86
		Or ClientPlatformType = PlatformType.Windows_x86_64;
	
EndFunction

// Returns True if the client application is running under Linux.
//
// Returns:
//  Boolean - if there is no client application, False is returned.
//
Function IsLinuxClient() Export
	
	ClientPlatformType = ClientPlatformType();
	Return ClientPlatformType = PlatformType.Linux_x86
		Or ClientPlatformType = PlatformType.Linux_x86_64;
	
EndFunction

// Returns True if the client application is running on macOS.
//
// Returns:
//  Boolean - if there is no client application, False is returned.
//
Function IsMacOSClient() Export
	
	ClientPlatformType = ClientPlatformType();
	Return ClientPlatformType = PlatformType.MacOS_x86
		Or ClientPlatformType = PlatformType.MacOS_x86_64;
	
EndFunction

// Returns True if the application is running via a web client
//
// Returns:
//  Boolean - web client attribute.
//
Function IsWebClient() Export
	
#If WebClient Then
	Return True;
#Else
	Return False;
#EndIf

EndFunction

// Returns True if the client application is connected to the database via a web server.
//
// Returns:
//  Boolean - True if connected.
//
Function ClientConnectedOverWebServer() Export
	
	Return StrFind(Upper(InfoBaseConnectionString()), "WS=") = 1;
	
EndFunction

// Returns True if debugging mode is enabled.
//
// Returns:
//  Boolean - True if debugging mode is enabled.
//
Function DebugMode() Export
	
	Return StrFind(LaunchParameter, "DebugMode") > 0;
	
EndFunction

// Returns the amount of RAM available to the client application.
//
// Returns:
//  Number - the number of gigabytes of RAM with an accuracy of tenths.
//  Undefined - there is no client application, that is, the current startup mode() = Undefined.
//
Function RAMAvailableForClientApplication() Export
	
	SystemInfo = New SystemInfo;
	Return Round(SystemInfo.RAM / 1024, 1);
	
EndFunction

// Returns the platform type of the client.
//
// Returns:
//  PlatformType, Undefined - the type of platform on which the client is running. In the web client mode, if 
//                               the platform type is different than described in the Platform type, then it is returned Indefinitely.
//
Function ClientPlatformType() Export
	
	SystemData = New SystemInfo;
	Return SystemData.PlatformType;
	
EndFunction

// Returns a flag for working in the data division mode by area
// (technically, this is a sign of conditional division).
// 
// Returns False if the configuration can't work in data separation mode
// (it doesn't contain General details intended for data separation).
//
// Returns:
//  Boolean - True if separation is enabled,
//           False if separation is disabled or not supported.
//
Function DataSeparationEnabled() Export
	
	If BSPIsUsed() Then
		// Calling BSP
		ModuleCommonClient = CommonModule("CommonClient");
		Return ModuleCommonClient.DataSeparationEnabled();
		// The end of the BSP Challenge
	EndIf;
	
	Return False;
	
EndFunction

// Returns whether split data (which is part of separators) can be accessed.
// This attribute is specific to the session, but may change during the session if partitioning was enabled
// in the session itself, so you should check it immediately before accessing the split data.
// 
// Returns True if the configuration can't work in data separation mode
// (it doesn't contain any General details intended for data separation).
//
// Returns:
//   Boolean - True, if the separation is not supported, either the separation is off,
//                    or the separation is on and the separators are set.
//            False if separation is enabled and no separators are set.
//
Function SeparatedDataUsageAvailable() Export
	
	If BSPIsUsed() Then
		
		// Calling BSP
		ModuleCommonClient = CommonModule("CommonClient");
		Return ModuleCommonClient.SeparatedDataUsageAvailable();
		// The end of the BSP Challenge
		
	EndIf;
	
	Return True;
	
EndFunction

Function ClientSComputerName() Export
	
#If Not WebClient Then
	Return ComputerName();
#Else
	Return "";
#EndIf
	
EndFunction

#EndRegion

#Region AvailableSubsystems

// Returns True if input devices are used and these subsystems exist in the configuration.
// It is designed to implement an optional subsystem call (conditional call).
//
// Returns:
//  Boolean
//
Function InputDevicesAreUsed() Export
	
	Return SubsystemExists("EquipmentSupport.Peripherals.InputDevices");
	
EndFunction

// Returns True if "Magnetic Card Templates" devices are used and these subsystems exist in the configuration.
// It is intended for the implementation of an optional subsystem call (conditional call).
//
// Returns:
//  Boolean
//
Function MagneticCardTemplatesAreUsed() Export
	
	Return SubsystemExists("EquipmentSupport.Peripherals.InputDevices.MagneticStripeCardTemplates");
	
EndFunction

// Returns True if fiscal device subsystems are used and these subsystems exist in the configuration.
// It is intended for the implementation of an optional subsystem call (conditional call).
//
// Returns:
//  Boolean
//
Function CheckPrintingDevicesAreUsed() Export
	
	Return SubsystemExists("EquipmentSupport.Peripherals.ReceiptPrinters");
	
EndFunction

// Returns True if the "Cash Shift" is used and these subsystems exist in the configuration.
// It is intended for the implementation of an optional subsystem call (conditional call).
//
// Returns:
//  Boolean
//
Function CashShiftIsUsed() Export
	
	Return SubsystemExists("EquipmentSupport.Peripherals.ReceiptPrinters.CashRegisterShift");
	
EndFunction               

// Returns True if "Electronic Check Distribution" is used and these subsystems exist in the configuration.
// It is intended for the implementation of an optional subsystem call (conditional call).
//
// Returns:
//  Boolean
//
Function ElectronicCashReceiptMailoutIsUsed() Export
	
	Return SubsystemExists("EquipmentSupport.Peripherals.ReceiptPrinters.ElectronicCashReceiptMailout");
	
EndFunction               

// Returns True if "Formatnological Control" is used and these subsystems exist in the configuration.
// It is intended for the implementation of an optional subsystem call (conditional call).
//
// Returns:
//  Boolean
//
Function FormatLogicalControlIsUsed() Export
	
	Return SubsystemExists("EquipmentSupport.Peripherals.ReceiptPrinters.FormatLogicalControl");
	
EndFunction  

// Returns True if "Marking" is used and these subsystems exist in the configuration.
// It is intended for the implementation of an optional subsystem call (conditional call).
//
// Returns:
//  Boolean
//
Function MarkingIsUsed() Export
	
	Return SubsystemExists("EquipmentSupport.Peripherals.ReceiptPrinters.Marking");
	
EndFunction  

// Returns True if the "Payment Systems" subsystem is used and this subsystem exists in the configuration.
// It is intended for the implementation of an optional subsystem call (conditional call).
//
// Returns:
//  Boolean
//
Function UsedPaymentSystems() Export
	
	Return SubsystemExists("EquipmentSupport.Peripherals.PaymentSystems");
	
EndFunction

// Returns True if the "Customer Displays" subsystem is used and this subsystem exists in the configuration.
// It is designed to implement an optional subsystem call (conditional call).
//
// Returns:
//  Boolean
//
Function UsedBuyerSDisplays() Export
	
	Return SubsystemExists("EquipmentSupport.Peripherals.CustomerDisplays");
	
EndFunction

// Returns True if the "Weighing Equipment" subsystem is used and this subsystem exists in the configuration.
// It is intended for the implementation of an optional subsystem call (conditional call).
//
// Returns:
//  Boolean
//
Function WeightEquipmentIsUsed() Export
	
	Return SubsystemExists("EquipmentSupport.Peripherals.WeighingEquipment");
	
EndFunction

// Returns True if the subsystem "Data Collection Terminals" is used and this subsystem exists in the configuration.
// It is intended for the implementation of an optional subsystem call (conditional call).
//
// Returns:
//  Boolean
//
Function DataCollectionTerminalsAreUsed() Export
	
	Return SubsystemExists("EquipmentSupport.Peripherals.PortableDataCollectionTerminals");
	
EndFunction

// Returns True if the Label Printers subsystem is used and this subsystem exists in the configuration.
// It is intended for the implementation of an optional subsystem call (conditional call).
//
// Returns:
//  Boolean
//
Function LabelPrintersAreUsed() Export
	
	Return SubsystemExists("EquipmentSupport.Peripherals.LabelPrinter");
	
EndFunction

// Returns True if the "RFID Reader" subsystem is used and this subsystem exists in the configuration.
// It is intended for the implementation of an optional subsystem call (conditional call).
//
// Returns:
//  Boolean
//
Function RFIDReaderIsUsed() Export
	
	Return SubsystemExists("EquipmentSupport.Peripherals.RFIDReaders");
	
EndFunction

// Returns True if the "Offline Equipment" subsystem is used and this subsystem exists in the configuration.
// It is intended for the implementation of an optional subsystem call (conditional call).
//
// Returns:
//  Boolean
//
Function OfflineEquipmentIsUsed() Export
	
	Return SubsystemExists("EquipmentSupport.OfflineEquipment_");
	
EndFunction

// Returns True if the "Label and Price Tag Printing" subsystem is used and this subsystem exists in the configuration.
// It is designed to implement an optional subsystem call (conditional call).
//
// Returns:
//  Boolean
//
Function PrintingOfLabelsAndPriceTagsIsUsed() Export
	
	Return SubsystemExists("EquipmentSupport.PrintPriceTagsAndLabels");
	
EndFunction

// Returns True if the subsystem "NSPK Electronic Certificates" is used and this subsystem exists in the configuration.
// It is intended for the implementation of an optional subsystem call (conditional call).
//
// Returns:
//  Boolean
//
Function ElectronicCertificatesOfNSPKAreUsed() Export
	
	Return SubsystemExists("EquipmentSupport.DigitalCertificates");
	
EndFunction

// Returns True if there is a subsystem of the standard subsystem.performance
// evaluation and performance valuation can be performed
// 
// Returns:
//   Boolean
Function PerformanceValuationISUSED() Export
	
	// Calling BSP
	Return SubsystemExists("StandardSubsystems.PerformanceMonitor");
	// The end of the BSP Challenge
	
EndFunction    

// Returns True if there is a subsystem of the standard subsystem.Basic Functionality
// 
// Returns:
//   Boolean
Function BasicFunctionalityIsUsed() Export
	
	// Calling BSP
	Return SubsystemExists("StandardSubsystems.Core");
	// The end of the BSP Challenge
	
EndFunction    

// Returns True if the hardware support subsystem exists.Technical Support Servicesreferences
//
// Returns:
//   Boolean
Function UsedMessagesToTechnicalSupportService() Export
	
	// BEEP call
	Return SubsystemExists("OnlineUserSupport.MessagesToTechSupportService") 
		And SubsystemExists("EquipmentSupport.MessagesToTechSupportService");
	// The end of the BSP Challenge
	
EndFunction

// Returns True if the subsystem "certificatynutsminciphers" is used and this subsystem exists in the configuration.
// It is intended for the implementation of an optional subsystem call (conditional call).
//
// Returns:
//  Boolean
//
Function UsingCertificatesOfNCAMDD() Export
	
	Return SubsystemExists("EquipmentSupport.DigitalCertificates.CertificatesOfNCAMDD");
	
EndFunction

// Returns True if the "Distributed Virtualization" subsystem is used and this subsystem exists in the configuration.
// It is intended for the implementation of an optional subsystem call (conditional call).
//
// Returns:
//  Boolean
//
Function DistributedFiscalizationIsUsed() Export
	
	Return SubsystemExists("EquipmentSupport.Peripherals.ReceiptPrinters.Distributed_Fiscalization");
	
EndFunction

// Returns True if "Stand-alone" is used and these subsystems exist in the configuration.
// It is intended for the implementation of an optional subsystem call (conditional call).
//
// Returns:
//  Boolean
//
Function AutonomousCCTIsUsed() Export
	
	Return SubsystemExists("EquipmentSupport.Peripherals.ReceiptPrinters.AutonomousCCT");
	
EndFunction  

// Returns True if the "Program Settings" subsystem is used and this subsystem exists in the configuration.
// It is intended for the implementation of an optional subsystem call (conditional call).
//
// Returns:
//  Boolean
//
Function SettingsOfBPOProgramAreUsed() Export
	
	Return SubsystemExists("EquipmentSupport.ApplicationSettings");
	
EndFunction

// Returns True if the "Recognition devices" subsystem is used and this subsystem exists in the configuration.
// It is intended for the implementation of an optional subsystem call (conditional call).
//
// Returns:
//  Boolean
//
Function RecognitionDeviceIsUsed() Export
	
	Return SubsystemExists("EquipmentSupport.Peripherals.RecognitionDevice");
	
EndFunction

// Returns True if the "Cloud" subsystem is used and this subsystem exists in the configuration.
// It is intended for the implementation of an optional subsystem call (conditional call).
//
// Returns:
//  Boolean
//
Function CloudCCTSAreUsed() Export
	
	Return SubsystemExists("EquipmentSupport.Peripherals.CloudCRE");
	
EndFunction

// Returns True if the "Logging equipment" subsystem is used and this subsystem exists in the configuration.
// It is intended for the implementation of an optional subsystem call (conditional call).
//
// Returns:
//  Boolean
//
Function LoggingSubsystemIsUsed() Export
	
	Return SubsystemExists("EquipmentSupport.PeripheralLogging");
	
EndFunction      


// Returns True if the "Non-certified equipment" subsystem is used and this subsystem exists in the configuration.
// It is intended for the implementation of an optional subsystem call (conditional call).
//
// Returns:
//  Boolean
//
Function NonCertifiedEquipmentIsUsed() Export
	
	Return SubsystemExists("EquipmentSupport.Peripherals.PeripheralsUncertified");
	
EndFunction

#EndRegion

#Region PerformanceMonitor

// starts time measurement if the performance valuation subsystem is used, if the value custom announcement is passed,
// then it will be replaced by the notification of the End of the measurement, and then the custom announcement will be called.
// 
// Parameters:
//  KeyOperation - String - name of the key operation
//  User_Notification - CallbackDescription - the notification that will be replaced
//  RecordWithError - Boolean - indicates that an error has been automatically fixed. 
//  AutoCompletion - Boolean - The truth is a sign of the automatic End of the measurement.
//
// Returns:
//  UUID - a unique measurement identifier that allows you to identify the measurement.
//
Function BPOTimeMeasurement(KeyOperation, User_Notification = Undefined, RecordWithError = False, AutoCompletion = False) Export
	
	MeasurementUUID = Undefined;
#If Not MobileAppClient Then 
	If PerformanceValuationISUSED() Then
		
		// Calling BSP
		ModulePerformanceMonitorClient = CommonModule("PerformanceMonitorClient");
		MeasurementUUID = ModulePerformanceMonitorClient.TimeMeasurement(KeyOperation, RecordWithError, AutoCompletion);
		// The end of the BSP Challenge
		
		MeasurementContext = New Structure();
		MeasurementContext.Insert("MeasurementUUID", MeasurementUUID);
		MeasurementContext.Insert("User_Notification", User_Notification);
		MeasurementContext.Insert("ModulePerformanceMonitorClient", ModulePerformanceMonitorClient);
		// Replace a custom notification
		User_Notification = New CallbackDescription("TimeMeasurementBpo_EndOfMeasurement", ThisObject, MeasurementContext);
	EndIf;
#EndIf
	
	Return MeasurementUUID;
	
EndFunction

// Starts time measurement if the Performance Valuation subsystem is used.
// 
// Parameters:
//  KeyOperation - String - name of the key operation
//  RecordWithError - Boolean - indicates that an error has been automatically fixed. 
//  AutoCompletion - Boolean - The truth is a sign of the automatic End of the measurement.
//
// Returns:
//  UUID - a unique measurement identifier that allows you to identify the measurement.
//
Function StartMeasuringBPOTime(KeyOperation, RecordWithError = False, AutoCompletion = False) Export
	
	MeasurementUUID = Undefined;
#If Not MobileAppClient Then 
	If PerformanceValuationISUSED() Then
		// Calling BSP
		ModulePerformanceMonitorClient = CommonModule("PerformanceMonitorClient");
		MeasurementUUID = ModulePerformanceMonitorClient.TimeMeasurement(KeyOperation, RecordWithError, AutoCompletion);
		// The end of the BSP Challenge
	EndIf;
#EndIf
	
	Return MeasurementUUID;
	
EndFunction

// completes the time measurement if the performance valuation subsystem is used
// 
// Parameters:
//  MeasurementUUID -UUID - a unique measurement identifier that allows you to identify the measurement.
//  CompletedWithError - Boolean - a sign that the measurement was not completed to the end.
//
Procedure CompleteBPOTimeMeasurement(MeasurementUUID, CompletedWithError = False) Export
	
#If Not MobileAppClient Then 
	If PerformanceValuationISUSED() Then
		// Calling BSP
		ModulePerformanceMonitorClient = CommonModule("PerformanceMonitorClient");
		ModulePerformanceMonitorClient.StopTimeMeasurement(MeasurementUUID, CompletedWithError);
		// The end of the BSP Challenge
	EndIf;
#EndIf
	
EndProcedure

// A procedure that can be replaced as a user notification
//
// Parameters:
//  Result - See EquipmentManagerClientServer.ParametersForPerformingOperationOnHardware
//  MeasurementContext - Structure - the context of the measurement notification:
//   * MeasurementUUID - UUID
//   * User_Notification - CallbackDescription
//   * ModulePerformanceMonitorClient - CommonModule
//
Procedure TimeMeasurementBpo_EndOfMeasurement(Result, MeasurementContext) Export
	
#If Not MobileAppClient Then 
	If TypeOf(Result) = Type("Structure") And Result.Property("Result") Then
		CompletedWithError = Not Result.Result;
	Else
		CompletedWithError = False;
	EndIf;
	
	ModulePerformanceMonitorClient = MeasurementContext.ModulePerformanceMonitorClient;
	ModulePerformanceMonitorClient.StopTimeMeasurement(MeasurementContext.MeasurementUUID, CompletedWithError);
	
	// Perform a spoofed notification
	If MeasurementContext.User_Notification<>Undefined Then
		RunCallback(MeasurementContext.User_Notification, Result);
	EndIf;
#EndIf
	
EndProcedure

#EndRegion

#EndRegion

#Region Private

#Region UserNotification

// Generates and outputs a message that can be associated with a form control.
//
// Parameters:
//  MessageToUserText - String - message text.
//  DataKey - AnyRef - the object or key of the database record that this message refers to.
//  Field - String - name of the form's details.
//  DataPath - String - data path (the path to the requisite shape).
//  Cancel - Boolean - the output parameter is always set to True.
// @skip-check method-too-many-params
Procedure InformBPOUser(
	Val MessageToUserText,
	Val DataKey = Undefined,
	Val Field = "",
	Val DataPath = "",
	Cancel = False) Export
	
	Message = New UserMessage;
	Message.Text = MessageToUserText;
	Message.Field = Field;
	
	//@skip-check empty-except-statement
	Try
		If Not IsBlankString(DataPath) Then
			Message.DataPath = DataPath;
		EndIf;
	Except
	
	EndTry;
	
	Message.Message();
	
	Cancel = True;
	
EndProcedure

#EndRegion

#Region CopyRecursive

Function CopyStructure(SourceStructure, FixData)
	
	ResultingStructure = New Structure;
	
	For Each KeyAndValue In SourceStructure Do
		ResultingStructure.Insert(KeyAndValue.Key, CopyRecursive(KeyAndValue.Value, FixData));
	EndDo;
	
	If FixData = True 
		Or FixData = Undefined
		And TypeOf(SourceStructure) = Type("FixedStructure") Then 
		
		Return New FixedStructure(ResultingStructure);
	EndIf;
	
	Return ResultingStructure;
	
EndFunction

Function CopyMap(SourceMap, FixData)
	
	ResultingMap = New Map;
	
	For Each KeyAndValue In SourceMap Do
		ResultingMap.Insert(KeyAndValue.Key, CopyRecursive(KeyAndValue.Value, FixData));
	EndDo;
	
	If FixData = True 
		Or FixData = Undefined
		And TypeOf(SourceMap) = Type("FixedMap") Then 
		Return New FixedMap(ResultingMap);
	EndIf;
	
	Return ResultingMap;
	
EndFunction

Function CopyArray(SourceArray1, FixData)
	
	ResultingArray = New Array;
	
	For Each Item In SourceArray1 Do
		ResultingArray.Add(CopyRecursive(Item, FixData));
	EndDo;
	
	If FixData = True 
		Or FixData = Undefined
		And TypeOf(SourceArray1) = Type("FixedArray") Then 
		Return New FixedArray(ResultingArray);
	EndIf;
	
	Return ResultingArray;
	
EndFunction

Function CopyValueList(SourceList, FixData)
	
	ResultingList = New ValueList;
	
	For Each ListItem In SourceList Do
		ResultingList.Add(
			CopyRecursive(ListItem.Value, FixData), 
			ListItem.Presentation, 
			ListItem.Check, 
			ListItem.Picture);
	EndDo;
	
	Return ResultingList;
	
EndFunction

#EndRegion


#EndRegion
