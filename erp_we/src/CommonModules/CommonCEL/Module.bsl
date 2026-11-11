#Region Public

// Retrieves the current server date, which is set to the session time zone.
// It is intended to be used instead of the current session function.
//
// Returns:
//  Date - the current date of the session.
//
Function SessionDate() Export
#If MobileAppServer Then
	// BSLLS:DeprecatedCurrentDate-off
	//@skip-check use-non-recommended-method
	Return CurrentDate(); // APK: 143 feature of the mobile app	
	// BSLLS:DeprecatedCurrentDate-on
#Else
	Return CurrentSessionDate();
#EndIf
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
	
	Return CommonCELClientServer.ReadRootXMLElement(XMLLine);
	
EndFunction       

// The function reads parameters from XML.
//
// Parameters:
//  XMLLine - String - XML string.
//
// Returns:
//  Structure
//
Function ReadParametersFromXML(XMLLine) Export
	
	Return CommonCELClientServer.ReadParametersFromXML(XMLLine);
	
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
	StandardSubsystems = Metadata.Subsystems.Find("StandardSubsystems");
	If StandardSubsystems = Undefined Then
		Return False;
	EndIf;
	Return StandardSubsystems.Subsystems.Find("Core") <> Undefined;
	// The end of the BSP Challenge
	
EndFunction   

// The function returns True if the state is implemented
//
// Returns:
//  Boolean
Function UsedByStateIS() Export
	
	Return CommonCEL.SubsystemExists("GosIs.ISMP");
	
EndFunction   

// Returns an indication that the execution is taking place on the training platform.
// It is used when you need to support the work of code that depends
// on the limitations of the training version of the platform.
//
// Returns:
//   Boolean - True if the execution takes place on a training platform.
//
Function IsTrainingPlatform() Export
	
	SetPrivilegedMode(True);
	CurrentUser = InfoBaseUsers.CurrentUser();

	Try
		OSUser = CurrentUser.OSUser;
	Except
		// In the educational version of the platform, getting the USEROS property is not available.
		Return True;
	EndTry;
	Return False;
	
EndFunction

// Returns the installed version of BSP, if BSP is not installed then
// returns "0.0.0.0"
//
// Returns:
//  String
Function SSLVersion() Export
	
	Version = "0.0.0.0";
	
	// Calling BSP
	If BSPIsUsed() Then
		ModuleStandardSubsystemsServer = CommonModule("StandardSubsystemsServer");
		If ModuleStandardSubsystemsServer <> Undefined Then
			Version = ModuleStandardSubsystemsServer.LibraryVersion();
		EndIf;
	EndIf;
	// The end of the BSP Challenge
	
	Return Version;
	
EndFunction

// Returns the proxy settings on the client.
//             
// Returns:
//  Structure
//
Function ProxySettingsAtClient() Export
	
	ProxyParameters = New Structure();
	ProxyParameters.Insert("Use", False);
	ProxyParameters.Insert("Server");
	ProxyParameters.Insert("Port");
	ProxyParameters.Insert("User");
	ProxyParameters.Insert("Password");
	
	If CommonCEL.BSPIsUsed() Then
		
		ModuleNetworkDownload = CommonCEL.CommonModule("GetFilesFromInternet");
		ProxySettingAtClient         = ModuleNetworkDownload.ProxySettingsAtClient();
		UseProxy             = True;
		UseSystemSettings = True;
		
		If TypeOf(ProxySettingAtClient) = Type("Map") Then
			UseProxy             = ProxySettingAtClient.Get("UseProxy");
			UseSystemSettings = ProxySettingAtClient.Get("UseSystemSettings");
			If UseProxy And Not UseSystemSettings Then    
				ProxyParameters.Use = True;
				ProxyParameters.Server       = ProxySettingAtClient.Get("Server");
				ProxyParameters.Port         = ProxySettingAtClient.Get("Port");
				ProxyParameters.User = ProxySettingAtClient.Get("User");
				ProxyParameters.Password       = ProxySettingAtClient.Get("Password");
			EndIf;
		EndIf;    
		
	EndIf;  
	
	Return  ProxyParameters;
	
EndFunction

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
Procedure MessageToUser(Val MessageToUserText, Val DataKey = Undefined,	Val Field = "",
	Val DataPath = "", Cancel = False) Export
	
	If BSPIsUsed() Then
		
		// Calling BSP
		GeneralPurposeModule = CommonModule("Common");
		GeneralPurposeModule.MessageToUser(MessageToUserText, DataKey, Field, DataPath, Cancel);
		// The end of the BSP Challenge
		
	Else
		InformBPOUser(MessageToUserText, DataKey, Field, DataPath, Cancel);
	EndIf;
	
EndProcedure

#EndRegion

// Generates an error entry in the registration Log.
//
// Parameters:
//   EventName - String
//   Comment - String, Undefined -
//   Var_Metadata - MetadataObject - 
//
Procedure WriteErrorToEventLog(EventName, Comment = Undefined, LevelPresentation = "Error", Var_Metadata = Undefined) Export
	
	#If MobileAppServer Then
		CommonCELOverridable.RecordErrorInMobileApp(EventName, LevelPresentation, Var_Metadata, Comment);
	#Else
		If Comment = Undefined Then
			Comment = ErrorProcessing.DetailErrorDescription(ErrorInfo()); 
		EndIf;
		Level = EventLevelByPresentation(LevelPresentation);
		WriteLogEvent(EventName, Level, Var_Metadata, ,Comment);
	#EndIf
	
EndProcedure

// Returns a structure containing the Attribute values read from the information database
// by reference to the object.
// 
//  If there is no access to one of the Attributes, an exception of access rights will occur.
//  If it is necessary to read out the Attributes regardless of the Cur user's rights,
//  then a preliminary transition to privileged mode should be used.
// 
// The function is not intended for retrieving the Attribute values of empty links.
//
// Parameters:
//  Ref    - AnyRef - the object whose details are to be retrieved.
//
//  Attributes - String - names of details, separated by commas, in the format
//              of requirements for structure properties.
//              For Example, "Code, Name, Parent".
//            - Structure, FixedStructure - the
//              alias of the field for the returned structure with the result is passed as the key
//              , and the actual name of the field in the table is passed as the value (optional).
//              If the value is not defined, then the field name is taken from the key.
//            - Array of String 
//            - FixedArray of String - the names of the details in the format of the requirements
//              for the properties of the structure.
//
// Returns:
//  Structure - contains the names (keys) and values of the requested Attributes.
//              If the string of requested Attributes is empty, an empty structure is returned.
//              If an empty reference is passed as an object, all Attributes will be returned with the value Undefined.
//
Function ObjectAttributesValues(Ref, Val Attributes) Export
	
	If BSPIsUsed() Then
		
		// Calling BSP
		GeneralPurposeModule = CommonModule("Common");
		Return GeneralPurposeModule.ObjectAttributesValues(Ref, Attributes);
		// The end of the BSP Challenge
		
	Else
		Return ValuesOfAttributesOfBPOObject(Ref, Attributes);
	EndIf;
	
EndFunction

// Returns the value of the Attribute read from the information database by reference to the object.
// 
//  If there is no access to the Attributes, an exception of access rights will occur.
//  If it is necessary to read out the Attributes regardless of the Cur user's rights,
//  then a preliminary transition to privileged mode should be used.
//
// The function is not intended for retrieving the Attribute values of empty links.
// 
// Parameters:
//  Ref       - AnyRef - the element of the dictionary, document ...
//  AttributeName - String -for example, "Code".
// 
// Returns:
//  Arbitrary    - depends on the type of value of the read props.
// 
Function ObjectAttributeValue(Ref, AttributeName) Export
	
	Result = ObjectAttributesValues(Ref, AttributeName);
	Return Result[StrReplace(AttributeName, ".", "")];
	
EndFunction 

// Returns the code of the main configuration language, for example "ru".
//
// Returns:
//  String - the language code.
//
Function DefaultLanguageCode() Export
	
	If BSPIsUsed() Then
		
		// Calling BSP
		GeneralPurposeModule = CommonModule("Common");
		Return GeneralPurposeModule.DefaultLanguageCode();
		// The end of the BSP Challenge
		
	EndIf;
	
	Return Metadata.DefaultLanguage.LanguageCode;
	
EndFunction

// Defines the operation mode of the information database: file (True) or server (False).
// When checking, the information database connection String is used, which can be specified explicitly.
//
// Parameters:
//  InfoBaseConnectionString - String - this parameter is used if
//                 you need to check the connection string of a non-current database.
//
// Returns:
//  Boolean
//
Function FileInfobase(Val InfoBaseConnectionString = "") Export
	
	If IsBlankString(InfoBaseConnectionString) Then
		InfoBaseConnectionString =  InfoBaseConnectionString();
	EndIf;
	Return StrFind(Upper(InfoBaseConnectionString), "FILE=") = 1;
	
EndFunction

// Returns True if this information base is connected to 1C: Fresh.
//
// Returns:
//  Boolean - a sign of an autonomous workplace.
//
Function IsStandaloneWorkplace() Export
	
	// Calling BSP
	If SubsystemExists("StandardSubsystems.DataExchange") Then
		ModuleDataExchangeServer = CommonModule("DataExchangeServer");
		Return ModuleDataExchangeServer.IsStandaloneWorkplace();
	EndIf;
	// The end of the BSP Challenge
	
	Return False;
	
EndFunction

// Returns True if the application is running via a web client
//
// Returns:
//  Boolean - web client attribute.
//
Function IsWebClient() Export
	
	If BSPIsUsed() Then
		
		// Calling BSP
		GeneralPurposeModule = CommonModule("Common");
		Return GeneralPurposeModule.IsWebClient();
		// The end of the BSP Challenge
		
	Else
		Return False;
	EndIf;
	
EndFunction

// Returns True if the mobile app or mobile client
//
// Returns:
//  Boolean - mobile platform flag.
//
Function ThisIsMobilePlatform() Export
	
	ApplicationType = ClientApplication.ApplicationType();
	MobilePlatform = ApplicationType = ClientApplicationType.MobileAppClient Or ApplicationType = ClientApplicationType.MobileClient;
	
	Return MobilePlatform;
	
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
		GeneralPurposeModule = CommonModule("Common");
		Return GeneralPurposeModule.DataSeparationEnabled();
		// The end of the BSP Challenge
		
	EndIf;
	
	Return False;
	
EndFunction

Function ClientSComputerName() Export
#If Not MobileAppServer Then   
	Return GetCurrentInfoBaseSession().ComputerName;
#Else
	Return "";
#EndIf
EndFunction

Function ClientNotificationsAreAvailable() Export
	
	If BSPIsUsed() Then
		
		// Calling BSP
		ServerAlertsServiceClientServerModule = CommonModule("ServerNotificationsInternalClientServer");
		Return ServerAlertsServiceClientServerModule.AreClientNotificationsAvailable();
		// The end of the BSP Challenge
		
	EndIf;

	Return CommonCELCached.ClientNotificationsAreAvailable();

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
		GeneralPurposeModule = CommonModule("Common");
		Return GeneralPurposeModule.SeparatedDataUsageAvailable();
		// The end of the BSP Challenge
		
	EndIf;
	
	Return True;
	
EndFunction

// Returns True if the "functional" subsystem exists in the configuration.
// It is intended for implementing an optional subsystem call (conditional call).
//
// The" functional "subsystem has the" Include in command interface " checkbox unchecked.
//
// Parameters:
//  FullSubsystemName - String - the full name of the subsystem metadata object
//                        without the words " Subsystem."and case-sensitive.
//                        For example: "Standard subsystems.Variants of reports".
//
// Example:
//
//  If the general purpose is PO.The subsystem exists("Standard subsystems.Report variationsreferences") Then
//  	Modulevariantsreferences = General purpose.General Module("Report Options");
//  	The Report Variants module.<Method name>();
//  The end if;
//
// Returns:
//  Boolean
//
Function SubsystemExists(FullSubsystemName) Export
	
	If BSPIsUsed() Then
		
		// Calling BSP
		GeneralPurposeModule = CommonModule("Common");
		Return GeneralPurposeModule.SubsystemExists(FullSubsystemName);
		// The end of the BSP Challenge
		
	Else
		SubsystemsNames = CommonCELCached.SubsystemsNames();
		Return SubsystemsNames.Get(FullSubsystemName) <> Undefined;
	EndIf;
	
EndFunction

// Returns a reference to the shared module by name.
//
// Parameters:
//  Name          - String - the name of the shared module, for example:
//                 , "General purpose",
//                 "General purpose client".
//
// Returns:
//  CommonModule
//
Function CommonModule(Name) Export
	
	If BSPIsUsed() Then
		
		// Calling BSP
		GeneralPurposeModule = GeneralBPOModule("Common");
		Return GeneralPurposeModule.CommonModule(Name);
		// The end of the BSP Challenge
		
	Else
		Return GeneralBPOModule(Name);
	EndIf;
	
EndFunction

// Performs actions before continuing execution of the routine task handler.
//
// For example, it checks whether a scheduled task handler can be executed.
// If the administrator has not blocked the execution of routine tasks until
// the end of the is update, then you need to stop executing the handler.
//
// Parameters:
//  ScheduledJob - ScheduledJob - the routine task
//    from which this method was called. It must be passed to check availability
//    by functional options.
//
Procedure OnStartExecuteScheduledJob(ScheduledJob = Undefined) Export
	
	If BSPIsUsed() Then

		// Calling BSP
		GeneralPurposeModule = CommonModule("Common");
		GeneralPurposeModule.OnStartExecuteScheduledJob(ScheduledJob);
		// The end of the BSP Challenge
		
	EndIf;
	
EndProcedure

// Calculates a checksum for arbitrary data using the specified algorithm.
//
// Parameters:
//  Data   - Arbitrary - any serializable value.
//  Algorithm - HashFunction   - algorithm for calculating the checksum. By default, MD5.
// 
// Returns:
//  String - the checksum is a string without spaces (for example, 32 characters).
//
Function CheckSumString(Val Data, Val Algorithm = Undefined) Export
	
	If BSPIsUsed() Then
		
		// Calling BSP
		GeneralPurposeModule = CommonModule("Common");
		Return GeneralPurposeModule.CheckSumString(Data, Algorithm);
		// The end of the BSP Challenge
		
	Else
		Return ChecksumByBPOString(Data, Algorithm);
	EndIf;
	
EndFunction

// Converts a table of values to an array of structures.
// It can be used for transmitting data to the client if the table
// it contains only values that can
// be passed from the server to the client.
//
// The resulting array contains structures, each of which repeats
// the structure of columns in the table of values.
//
// It is not recommended to use it for converting tables of values
// with a large number of rows.
//
// Parameters:
//  ValueTable - ValueTable - the original table of values.
//
// Returns:
//  Array - a collection of table rows in the form of structures.
//
Function ValueTableToArray(ValueTable) Export
	
	If BSPIsUsed() Then
		
		// Calling BSP
		GeneralPurposeModule = CommonModule("Common");
		Return GeneralPurposeModule.ValueTableToArray(ValueTable);
		// The end of the BSP Challenge
		
	Else
		Array = New Array();
		StructureString = "";
		CommaRequired = False;
		For Each Column In ValueTable.Columns Do
			If CommaRequired Then
				StructureString = StructureString + ",";
			EndIf;
			StructureString = StructureString + Column.Name;
			CommaRequired = True;
		EndDo;
		For Each String In ValueTable Do
			NewRow = New Structure(StructureString);
			FillPropertyValues(NewRow, String);
			Array.Add(NewRow);
		EndDo;
		Return Array;
	EndIf;

EndFunction

// Checks whether the transmitted table documents fit on the page when printing.
//
// Parameters:
//  TabDocument        - SpreadsheetDocument - table document.
//  AreasToOutput   - Array of SpreadsheetDocument
//                     - SpreadsheetDocument - an array of tables to be checked or a tabular document. 
//  ResultOnError - Boolean - how to return the result when an error occurs.
//
// Returns:
//   Boolean   - whether the transferred documents fit or not.
//
Function SpreadsheetDocumentFitsPage(TabDocument, AreasToOutput, ResultOnError = True) Export

	Try
		Return TabDocument.CheckPut(AreasToOutput);
	Except
		Return ResultOnError;
	EndTry;

EndFunction 

// Returns the structure generated by the information register
//
// Parameters:
//  MetadataInformationRegister - MetadataObjectInformationRegister
//  StorageArray - Array of String -  where will the names of the information register fields containing the type of value storages be recorded
//
// Returns:
//   Structure
//
Function StructureOfInformationRegisterMetadata(MetadataInformationRegister, StorageArray = Undefined) Export
	
	Result = New Structure();
	If TypeOf(StorageArray) <> Type("Array") Then
		StorageArray = New Array();
	EndIf;
	For Each Dimension In MetadataInformationRegister.Dimensions Do
		Result.Insert(Dimension.Name);
	EndDo;
	For Each Resource In MetadataInformationRegister.Resources Do
		If Resource.Type.ContainsType(Type("ValueStorage")) Then
			StorageArray.Add(Resource.Name);
			Continue;
		EndIf;
		Result.Insert(Resource.Name);
	EndDo;
	For Each Attribute In MetadataInformationRegister.Attributes Do
		If Attribute.Type.ContainsType(Type("ValueStorage")) Then
			StorageArray.Add(Attribute.Name);
			Continue;
		EndIf;
		Result.Insert(Attribute.Name);
	EndDo;
	Return Result;
	
EndFunction // Structuresmetadannyhobjects()

#Region InterfaceProceduresAndFunctions

// Set control properties
//
// Parameters:
//  Control - FormField
//
Procedure PrepareControl(Control) Export
	
	Control.TitleLocation = FormItemTitleLocation.Top;
	Control.TitleFont = StyleFonts.SmallTextFont;
	
EndProcedure

#EndRegion

// Converts a row in the value table to a structure.
// The structure properties and their values match the columns of the passed string.
//
// Parameters:
//  ValueTableRow - ValueTableRow
//
// Returns:
//  Structure - the converted row of the value table.
//
Function ValueTableRowToStructure(ValueTableRow) Export
	
	Structure = New Structure;
	For Each Column In ValueTableRow.Owner().Columns Do
		Structure.Insert(Column.Name, ValueTableRow[Column.Name]);
	EndDo;
	
	Return Structure;
	
EndFunction

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
	
	If SourceType = Type("ValueTable") Then
		Return Source.Copy();
	EndIf;
	
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

// Returns a string value to the date.
//
// Parameters:
//  Value - String - a string value that is cast to a date.
//
// Returns:
//   Date - The given value.
//
Function StringToDate(Val Value) Export 
	
	If BSPIsUsed() Then
		
		// Calling BSP
		CommonClientServerModule = CommonModule("CommonClientServer");
		Return CommonClientServerModule.StringToDate(Value);
		// The end of the BSP Challenge
		
	Else
		Return LineInBPODate(Value);
	EndIf;
	
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
	
	Return SubsystemExists("EquipmentSupport.Peripherals.CloudCRE")
	And SubsystemExists("OnlineUserSupport.CloudCashAccounts");
	
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

// Returns True if the hardware support subsystem exists.Technical Support Servicesreferences
//
// Returns:
//   Boolean
Function UsedMessagesToTechnicalSupportService() Export
	
	// BEEP call
	Return SubsystemExists("OnlineUserSupport.MessagesToTechSupportService") 
		And SubsystemExists("EquipmentSupport.MessagesToTechSupportService");
	// End the BEEP Call
	
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

// Convert possible string values to Boolean
// 
// Parameters:
//  String - String
// 
// Returns:
//  Boolean
//
Function ConvertToBoolean(String) Export 
	
	Try
		Return XMLValue(Type("Boolean"), String);
	Except
		Return Upper(String) = "YES" Or Upper(String) = "TRUE" Or Upper(String) = "YES";
	EndTry;  
	
EndFunction

Function EnumerationValueName(Value) Export
	
	EnumerationName = Value.Metadata().Name;
	IndexOfEnumerationValue = Enums[EnumerationName].IndexOf(Value);
	EnumerationValueName = Metadata.Enums[EnumerationName].EnumValues[IndexOfEnumerationValue].Name;
	Return EnumerationValueName;
		
EndFunction

// Formats the message text in JSON format
//
// Parameters:
//  JSONMessageText           - String - the text of the message that.
//  RemoveSpacesAndLineBreaks - Boolean - indicates the use of margins. False by default.
//  BASE64DeploymentKeys - Undefined -
//                            - Map of KeyAndValue:
//  * Key - String - Name of the property for the BASE64 reversal
//  * Value - Undefined - not used
// Returns:
//  String - formatted JSON string.
//
Function FormatJSON(JSONMessageText, RemoveSpacesAndLineBreaks = False, BASE64DeploymentKeys = Undefined) Export
	
	If IsBlankString(JSONMessageText) Then
		Return "";
	EndIf;
	
	JSONReader = New JSONReader();
	JSONReader.SetString(JSONMessageText);
	
	Try
		Data = ReadJSON(JSONReader, True);
	Except
		Return JSONMessageText;
	EndTry;
	JSONReader.Close();
	
	If BASE64DeploymentKeys <> Undefined
		And TypeOf(Data) <> Type("Array") Then
		For Each KeyAndValue In BASE64DeploymentKeys Do
			DataByKey = Data[KeyAndValue.Key];
			If DataByKey = Undefined Then
				Continue;
			EndIf;
			Data[KeyAndValue.Key] = JSONTextInObject( EquipmentManagerClientServer.Base64BBarcode(DataByKey), True);
		EndDo;
	EndIf;
	
	Return ObjectInJSONText(Data, RemoveSpacesAndLineBreaks);
	
EndFunction

// Get the structure from the JSON text.
// 
// Parameters:
// 	JSONText                    - String - JSON text.
// 	ConvertToMatch - Boolean - Flag for conversion to a match.
// Returns:
// 	Structure, Undefined, Arbitrary - The result of the JSON conversion.
//
Function JSONTextInObject(JSONText, ConvertToMatch = False) Export
	
	ParsingResult = Undefined;
	
	Read = New JSONReader;
	Read.SetString(JSONText);
	
	Try
		ParsingResult = ReadJSON(Read, ConvertToMatch);
	Except
		ParsingResult = Undefined;
	EndTry;
		
	Return ParsingResult;
	
EndFunction

// Generates JSON text from the structure
// 
// Parameters:
// 	Structure                    - Structure - Arbitrary data structure
//  RemoveSpacesAndLineBreaks - Boolean    - indicates whether to use margins. True by default.
//  SerializationSettings - Undefined, JSONSerializerSettings -
// Returns:
// 	String - JSON text   
//
Function ObjectInJSONText(Structure, RemoveSpacesAndLineBreaks = False, SerializationSettings = Undefined) Export
	
	JSONText = "";
	
	If RemoveSpacesAndLineBreaks Then
		JSONWriterSettings = New JSONWriterSettings(JSONLineBreak.None, "");
	Else
		JSONWriterSettings = New JSONWriterSettings(JSONLineBreak.Auto, "  ");
	EndIf;
		
	JSONWriter = New JSONWriter();
	JSONWriter.SetString(JSONWriterSettings);
	
	WriteJSON(JSONWriter, Structure, SerializationSettings);
	
	JSONText = JSONWriter.Close();
	
	Return JSONText;
	
EndFunction

Function StringInJSON(Property, Value, AdditionalParameters, Cancel) Export  
	
	Return String(Value);   
	
EndFunction

// Deletes invalid characters in the XML string.
//
// Parameters:
//  Text - String - a string where you want to delete invalid characters.
// 
// Returns:
//  String
//
Function RemoveInvalidXMLCharacters(Val Text) Export
	
	If BSPIsUsed() Then
		// Calling BSP
		CommonClientServerModule = CommonModule("CommonClientServer");
		Return CommonClientServerModule.DeleteDisallowedXMLCharacters(Text);
		// The end of the BSP Challenge
	Else
		Return XMLStringProcessing.DeleteDisallowedXMLCharacters(Text);
	EndIf;
	
EndFunction

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
//@skip-check method-too-many-params
Procedure InformBPOUser( 
	Val MessageToUserText,
	Val DataKey = Undefined,
	Val Field = "",
	Val DataPath = "",
	Cancel = False)
	
	IsObject = False;
	
	If DataKey <> Undefined
		And XMLTypeOf(DataKey) <> Undefined Then
		
		ValueTypeAsString = XMLTypeOf(DataKey).TypeName;
		IsObject = StrFind(ValueTypeAsString, "Object.") > 0;
	EndIf;
	
	Message = New UserMessage;
	Message.Text = MessageToUserText;
	Message.Field = Field;
	
	//@skip-check empty-except-statement
	// APK: 280-off
	Try
		If IsObject Then
			Message.SetData(DataKey);
		Else
			Message.DataKey = DataKey;
		EndIf;
		
		If Not IsBlankString(DataPath) Then
			Message.DataPath = DataPath;
		EndIf;
	Except
	
	EndTry;
	// APK: 280-on
	
	Message.Message();
	
	Cancel = True;
	
EndProcedure

#EndRegion

// Returns a structure containing the Attribute values read from the information database
// by reference to the object.
// 
//  If there is no access to one of the Attributes, an exception of access rights will occur.
//  If it is necessary to read out the Attributes regardless of the Cur user's rights,
//  then a preliminary transition to privileged mode should be used.
// 
// The function is not intended for retrieving the Attribute values of empty links.
//
// Parameters:
//  Ref    - AnyRef - the object whose details are to be retrieved.
//
//  Attributes - String - names of details, separated by commas, in the format
//              of requirements for structure properties.
//              For Example, "Code, Name, Parent".
//            - Structure, FixedStructure - the
//              alias of the field for the returned structure with the result is passed as the key
//              , and the actual name of the field in the table is passed as the value (optional).
//              If the value is not defined, then the field name is taken from the key.
//            - Array of String - the names of the details in the format of the requirements
//              for the properties of the structure.
//
// Returns:
//  Structure - contains the names (keys) and values of the requested Attributes.
//              If the string of requested Attributes is empty, an empty structure is returned.
//              If an empty reference is passed as an object, all Attributes will be returned with the value Undefined.
//
Function ValuesOfAttributesOfBPOObject(Ref, Val Attributes)
	
	If TypeOf(Attributes) = Type("String") Then
		If IsBlankString(Attributes) Then
			Return New Structure;
		EndIf;
		Attributes = StrSplit(Attributes, ",", False);
	EndIf;
	
	AttributesStructure1 = New Structure;
	If TypeOf(Attributes) = Type("Structure") Or TypeOf(Attributes) = Type("FixedStructure") Then
		AttributesStructure1 = Attributes;
	ElsIf TypeOf(Attributes) = Type("Array") Or TypeOf(Attributes) = Type("FixedArray") Then
		For Each Attribute In Attributes Do
			AttributesStructure1.Insert(StrReplace(Attribute, ".", ""), Attribute);
		EndDo;
	Else
		Raise StrTemplate(NStr("vi = 'Sai kiểu tham số thứ hai Mục tin: %1';
								|ru = 'Неверный тип второго параметра Реквизиты: %1';
								|en = 'Invalid Attributes parameter type: %1.'; fa = 'Invalid Attributes parameter type: %1.';
								|it = 'Il tipo del secondo parametro Requisiti non è valido: %1';
								|pl = 'Błędny typ drugiego parametru Atrybuty: %1';
								|tr = 'İkincil ""Öznitelikler"" parametresinin geçersiz türü: %1'"), String(TypeOf(Attributes)));
	EndIf;
	
	FieldTexts = "";
	For Each KeyAndValue In AttributesStructure1 Do
		FieldName   = ?(ValueIsFilled(KeyAndValue.Value),
		              TrimAll(KeyAndValue.Value),
		              TrimAll(KeyAndValue.Key));
		
		Alias = TrimAll(KeyAndValue.Key);
		
		FieldTexts  = FieldTexts + ?(IsBlankString(FieldTexts), "", ",") + "
		|	" + FieldName + " AS " + Alias;
	EndDo;
	
	Query = New Query;
	Query.SetParameter("Ref", Ref);
	Query.Text =
	"SELECT
	|	&FieldTexts
	|FROM
	|	&FullName AS SpecifiedTableAlias
	|WHERE
	|	SpecifiedTableAlias.Ref = &Ref";
	Query.Text = StrReplace(Query.Text, "&FieldTexts", FieldTexts);
	Query.Text = StrReplace(Query.Text, "&FullName", Ref.Metadata().FullName());

	Selection = Query.Execute().Select();
	Selection.Next();
	
	Result = New Structure;
	For Each KeyAndValue In AttributesStructure1 Do
		Result.Insert(KeyAndValue.Key);
	EndDo;
	FillPropertyValues(Result, Selection);
	
	Return Result;
	
EndFunction

// Returns a reference to the shared module by name.
//
// Parameters:
//  Name          - String - the name of the shared module, for example:
//                 , "General purpose",
//                 "General purpose client".
//
// Returns:
//  CommonModule
//
Function GeneralBPOModule(Name)
	
	If Metadata.CommonModules.Find(Name) <> Undefined Then
		// APK:486-off compute in safe mode is not used to avoid calling the general module recursively.
		#If Not MobileAppServer Then
		SetSafeMode(True);
		#EndIf
		Module = Eval(Name);
		// APK:486-on
	ElsIf StrOccurrenceCount(Name, ".") = 1 Then
		Return ServerManagerModule(Name);
	Else
		Module = Undefined;
	EndIf;
	
	If TypeOf(Module) <> Type("CommonModule") Then
		Raise StrTemplate(NStr("vi = 'Mô-đun chung ""%1"" không tồn tại.';
								|ru = 'Общий модуль ""%1"" не существует.';
								|en = 'Common module ""%1"" does not exist.'; fa = 'Common module ""%1"" does not exist.';
								|it = 'Modulo generale ""%1"" non esiste.';
								|pl = 'Moduł ogólny ""%1"" nie istnieje.';
								|tr = '""%1"" ortak modülü mevcut değil.'"), Name);
	EndIf;
	
	Return Module;
	
EndFunction

// Calculates a checksum for arbitrary data using the specified algorithm.
//
// Parameters:
//  Data   - Arbitrary - any serializable value.
//  Algorithm - HashFunction   - algorithm for calculating the checksum. By default, MD5.
// 
// Returns:
//  String - the checksum is a string without spaces (for example, 32 characters).
//
Function ChecksumByBPOString(Val Data, Val Algorithm = Undefined) Export
	
	If Algorithm = Undefined Then
		Algorithm = HashFunction.MD5;
	EndIf;
	
	DataHashing = New DataHashing(Algorithm);
	If TypeOf(Data) <> Type("String") And TypeOf(Data) <> Type("BinaryData") Then
		Data = ValueToXMLString(Data);
	EndIf;
	DataHashing.Append(Data);
	
	If TypeOf(DataHashing.HashSum) = Type("BinaryData") Then 
		Result = StrReplace(DataHashing.HashSum, " ", "");
	ElsIf TypeOf(DataHashing.HashSum) = Type("Number") Then
		Result = Format(DataHashing.HashSum, "NG=");
	EndIf;
	
	Return Result;
	
EndFunction

// Returns the backend module Manager by the name of the object.
Function ServerManagerModule(Name)
	ObjectFound = False;
	
	NameParts = StrSplit(Name, ".");
	If NameParts.Count() = 2 Then
		
		KindName = Upper(NameParts[0]);
		ObjectName = NameParts[1];
		
		If KindName = Upper("Constants") Then
			If Metadata.Constants.Find(ObjectName) <> Undefined Then
				ObjectFound = True;
			EndIf;
		ElsIf KindName = Upper("InformationRegisters") Then
			If Metadata.InformationRegisters.Find(ObjectName) <> Undefined Then
				ObjectFound = True;
			EndIf;
		ElsIf KindName = Upper("AccumulationRegisters") Then
			If Metadata.AccumulationRegisters.Find(ObjectName) <> Undefined Then
				ObjectFound = True;
			EndIf;
		ElsIf KindName = Upper("AccountingRegisters") Then
			If Metadata.AccountingRegisters.Find(ObjectName) <> Undefined Then
				ObjectFound = True;
			EndIf;
		ElsIf KindName = Upper("CalculationRegisters") Then
			If Metadata.CalculationRegisters.Find(ObjectName) <> Undefined Then
				ObjectFound = True;
			EndIf;
		ElsIf KindName = Upper("Catalogs") Then
			If Metadata.Catalogs.Find(ObjectName) <> Undefined Then
				ObjectFound = True;
			EndIf;
		ElsIf KindName = Upper("Documents") Then
			If Metadata.Documents.Find(ObjectName) <> Undefined Then
				ObjectFound = True;
			EndIf;
		ElsIf KindName = Upper("Reports") Then
			If Metadata.Reports.Find(ObjectName) <> Undefined Then
				ObjectFound = True;
			EndIf;
		ElsIf KindName = Upper("DataProcessors") Then
			If Metadata.DataProcessors.Find(ObjectName) <> Undefined Then
				ObjectFound = True;
			EndIf;
		ElsIf KindName = Upper("BusinessProcesses") Then
			If Metadata.BusinessProcesses.Find(ObjectName) <> Undefined Then
				ObjectFound = True;
			EndIf;
		ElsIf KindName = Upper("DocumentJournals") Then
			If Metadata.DocumentJournals.Find(ObjectName) <> Undefined Then
				ObjectFound = True;
			EndIf;
		ElsIf KindName = Upper("Tasks") Then
			If Metadata.Tasks.Find(ObjectName) <> Undefined Then
				ObjectFound = True;
			EndIf;
		ElsIf KindName = Upper("ChartsOfAccounts") Then
			If Metadata.ChartsOfAccounts.Find(ObjectName) <> Undefined Then
				ObjectFound = True;
			EndIf;
		ElsIf KindName = Upper("ExchangePlans") Then
			If Metadata.ExchangePlans.Find(ObjectName) <> Undefined Then
				ObjectFound = True;
			EndIf;
		ElsIf KindName = Upper("ChartsOfCharacteristicTypes") Then
			If Metadata.ChartsOfCharacteristicTypes.Find(ObjectName) <> Undefined Then
				ObjectFound = True;
			EndIf;
		ElsIf KindName = Upper("ChartsOfCalculationTypes") Then
			If Metadata.ChartsOfCalculationTypes.Find(ObjectName) <> Undefined Then
				ObjectFound = True;
			EndIf;
		EndIf;
		
	EndIf;
	
	If Not ObjectFound Then
		Raise StrTemplate(
			NStr("vi = 'Không tìm thấy đối tượng metadata ""%1"",
			|hoặc đối tượng không hỗ trợ nhận mô-đun quản lý.';
			|ru = 'Объект метаданных ""%1"" не найден,
			|либо для него не поддерживается получение модуля менеджера.';
			|en = 'Metadata object %1 not found.
			|It might be missing or it does not support getting the manager module.'; fa = 'Metadata object %1 not found.
			|It might be missing or it does not support getting the manager module.';
			|it = 'L''oggetto di metadati ""%1"" non è stato trovato,
			|oppure per esso non è supportato l''ottenimento del modulo del manager.';
			|pl = 'Obiekt metadanych ""%1"" nie znaleziono,
			|albo dla niego nie jest obsługiwane otrzymanie modułu menedżerа.';
			|tr = '""%1"" Meta veri nesnesi bulunamadı 
			|veya yönetici modül alımı bunun için desteklenmiyor.'"), Name);
	EndIf;
	
	// APK: 486-off, 488-off compute in safe mode is not used to avoid calling the general module recursively.
	#If Not MobileAppServer Then
	SetSafeMode(True);
	#EndIf
	Module = Eval(Name);
	// APK: 486-on, 488-on
	
	Return Module;
EndFunction

// Converts (serializes) any value into an XML string.
// Only objects that are specified to be serialized in the syntax helper can be
// converted to. See also the values of the xmlstring.
//
// Parameters:
//  Value - Arbitrary - the value to serialize to an XML string.
//
// Returns:
//  String - XML string.
//
Function ValueToXMLString(Value)
	
	XMLWriter = New XMLWriter;
	XMLWriter.SetString();
	XDTOSerializer.WriteXML(XMLWriter, Value, XMLTypeAssignment.Explicit);
	
	Return XMLWriter.Close();
EndFunction

// Returns a string value to the date.
//
// Parameters:
//  Value - String - a string value that is cast to a date.
//
// Returns:
//   Date - The given value.
//
Function LineInBPODate(Val Value)
	
	DateEmpty = Date(1, 1, 1);
	
	If Not ValueIsFilled(Value) Then 
		Return DateEmpty;
	EndIf;
	
	DateDetails = New TypeDescription("Date");
	Date = DateDetails.AdjustValue(Value);
	
	If TypeOf(Date) = Type("Date")
		And ValueIsFilled(Date) Then 
		
		Return Date;
	EndIf;
	
	#Region PreparingDateParts
	
	CharsCount = StrLen(Value);
	
	If CharsCount > 25 Then 
		Return DateEmpty;
	EndIf;
	
	PartsOfTheValue = New Array;
	PartOfTheValue = "";
	
	For CharacterNumber = 1 To CharsCount Do 
		
		Char = Mid(Value, CharacterNumber, 1);
		
		If IsNumber(Char) Then 
			
			PartOfTheValue = PartOfTheValue + Char;
			
		Else
			
			If Not IsBlankString(PartOfTheValue) Then 
				PartsOfTheValue.Add(PartOfTheValue);
			EndIf;
			
			PartOfTheValue = "";
			
		EndIf;
		
		If CharacterNumber = CharsCount
			And Not IsBlankString(PartOfTheValue) Then 
			
			PartsOfTheValue.Add(PartOfTheValue);
		EndIf;
		
	EndDo;
	
	If PartsOfTheValue.Count() < 3 Then 
		Return DateEmpty;
	EndIf;
	
	If PartsOfTheValue.Count() < 4 Then 
		PartsOfTheValue.Add("00");
	EndIf;
	
	If PartsOfTheValue.Count() < 5 Then 
		PartsOfTheValue.Add("00");
	EndIf;
	
	If PartsOfTheValue.Count() < 6 Then 
		PartsOfTheValue.Add("00");
	EndIf;
	
	#EndRegion
	
	// If the format is yyyyMMddHHmmss:
	NormalizedValue = PartsOfTheValue[2] + PartsOfTheValue[1] + PartsOfTheValue[0]
		+ PartsOfTheValue[3] + PartsOfTheValue[4] + PartsOfTheValue[5];
	
	Date = DateDetails.AdjustValue(NormalizedValue);
	
	If TypeOf(Date) = Type("Date")
		And ValueIsFilled(Date) Then 
		
		Return Date;
	EndIf;
	
	// If the format is YYYYDDMMHMMSS
	NormalizedValue = PartsOfTheValue[2] + PartsOfTheValue[0] + PartsOfTheValue[1]
		+ PartsOfTheValue[3] + PartsOfTheValue[4] + PartsOfTheValue[5];
	
	Date = DateDetails.AdjustValue(NormalizedValue);
	
	If TypeOf(Date) = Type("Date")
		And ValueIsFilled(Date) Then 
		
		Return Date;
	EndIf;
	
	Return DateEmpty;
	
EndFunction

// Returns a flag indicating that the passed value is, or is not, a number.
//
// Parameters:
//  ValueToCheck - String - the value that is checked to match the number.
//
// Returns:
//   Boolean - indicates that the passed value is, or is not, a number.
//
Function IsNumber(Val ValueToCheck)
	
	If ValueToCheck = "0" Then
		Return True;
	EndIf;
	
	NumberDetails = New TypeDescription("Number");
	
	Return NumberDetails.AdjustValue(ValueToCheck) <> 0;
	
EndFunction

// The procedure removes the elements corresponding to the names 
// of the object's details from the array of array-Verifiedrequisits from the array array.
// For use in the event handlers of Obrabatyvaniya.
//
// Parameters:
//  AttributesArray              - Array - collection of names and details of the object.
//  NotCheckedAttributeArray - Array - collection of names of object details that do not require verification.
//
Procedure DeleteNotCheckedAttributesFromArray(AttributesArray, NotCheckedAttributeArray) Export
	
	For Each ArrayElement In NotCheckedAttributeArray Do
	
		SequenceNumber = AttributesArray.Find(ArrayElement);
		If SequenceNumber <> Undefined Then
			AttributesArray.Delete(SequenceNumber);
		EndIf;
	
	EndDo;
	
EndProcedure

#Region Data

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

#If Not MobileAppServer Then
	
Function EventLevelByPresentation(LevelPresentation)
	If LevelPresentation = "Information" Then
		Return EventLogLevel.Information;
	ElsIf LevelPresentation = "Error" Then
		Return EventLogLevel.Error;
	ElsIf LevelPresentation = "Warning" Then
		Return EventLogLevel.Warning; 
	ElsIf LevelPresentation = "Note" Then
		Return EventLogLevel.Note;
	EndIf;	
EndFunction

#EndIf

#EndRegion