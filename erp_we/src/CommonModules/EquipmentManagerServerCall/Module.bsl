
#Region Public

#Region System

// Refunds without a card are available.       
//
// Returns:
//  Structure - Refunds are available without a card:
//   * ReturnByPaymentCard - Boolean
//   * ReturnByElectronicCertificate - Boolean
//
Function AvailableReturnsWithoutCard() Export
	
	ReturnsWithoutCard = New Structure();
	ReturnsWithoutCard.Insert("ReturnByPaymentCard"       , True);
	ReturnsWithoutCard.Insert("ReturnByElectronicCertificate", True);
	EquipmentManagerServerCallOverridable.AvailableReturnsWithoutCard(ReturnsWithoutCard);    
	Return ReturnsWithoutCard; 
	
EndFunction  

// Isolated Connection Of External Components On The Client 
// Returns:
//  Boolean - Isolated
//
Function IsolatedConnectionOfExternalComponentsOnClient() Export
	
	Return AddInsCEL.IsolatedConnectionOfExternalComponentsOnClient();
	
EndFunction

// Get Matching Equipment Types
//
// Returns:
//   Map of KeyAndValue -
//
Function CompatibilityOfEquipmentTypes() Export
	
	Return EquipmentManager.CompatibilityOfEquipmentTypes();
	
EndFunction

#EndRegion

#Region Workplace

// The function returns the client's workplace from the session variable.
// 
// Parameters:
//   IsPeripherals - Boolean - True is returned if there is connected hardware in the database.
//   WorkplaceSearchParameters - Structure
// 
// Returns:
//  CatalogRef.Workplaces
//
Function CustomerWorkplace(IsPeripherals = True, WorkplaceSearchParameters = Undefined) Export
	
	SetPrivilegedMode(True);
	Workplace = SessionParameters.CustomerWorkplace;
	If Not ValueIsFilled(Workplace) Then
		UpdateClientWorkplace(WorkplaceSearchParameters);
		Workplace = SessionParameters.CustomerWorkplace;
	EndIf;
	// check that the connected equipment is in the directory and send this information to the client
	IsPeripherals = EquipmentManager.IsPeripherals();
	
	Return Workplace;
	
EndFunction

// The function returns a list of jobs that match the specified computer name.
//
// Parameters:
//  ClientID - String - Client ID for the workplace      
//  ComputerName - String - computer name  
//  MACAddress - String, Array of String - MAC address or array of MAC addresses 
//
// Returns:
//  Array of CatalogRef.Workplaces
//
Function FindWorkplacesById(ClientID, ComputerName, MACAddress = "") Export
	
	Result = New Array();
	
	If Not CommonCEL.SeparatedDataUsageAvailable() Then
		Return Result;
	EndIf;
	
	SetPrivilegedMode(True);
	
	If TypeOf(MACAddress) = Type("String") Then
		MACAddresses = New Array();
		If ValueIsFilled(MACAddress) Then
			MACAddresses.Add(MACAddress);
		EndIf;
	Else
		MACAddresses = MACAddress;
	EndIf;
	
	Query = New Query(
	"SELECT
	|	0 AS Priority,
	|	Workplaces.Ref AS Ref,
	|	Workplaces.ComputerName AS ComputerName
	|INTO WorkplacesByPriority
	|FROM
	|	Catalog.Workplaces AS Workplaces
	|WHERE
	|	Workplaces.Code = &ClientID
	|	AND NOT Workplaces.DeletionMark
	|
	|UNION ALL
	|
	|SELECT
	|	1,
	|	WorkplacesClientIDs.Ref,
	|	WorkplacesClientIDs.Ref.ComputerName
	|FROM
	|	Catalog.Workplaces.ClientIDs AS WorkplacesClientIDs
	|WHERE
	|	WorkplacesClientIDs.ClientID = &ClientID
	|	AND NOT WorkplacesClientIDs.Ref.DeletionMark
	|
	|UNION ALL
	|
	|SELECT
	|	2,
	|	Workplaces.Ref,
	|	Workplaces.ComputerName
	|FROM
	|	Catalog.Workplaces AS Workplaces
	|WHERE
	|	Workplaces.MACAddress IN(&MACAddresses)
	|	AND Workplaces.ComputerName = &ComputerName
	|	AND &ComputerName <> """"
	|	AND NOT Workplaces.DeletionMark
	|
	|UNION ALL
	|
	|SELECT
	|	2,
	|	Workplaces.Ref,
	|	Workplaces.ComputerName
	|FROM
	|	Catalog.Workplaces AS Workplaces
	|WHERE
	|	Workplaces.ComputerName = &ComputerName
	|	AND &ComputerName <> """"
	|	AND NOT Workplaces.DeletionMark
	|	AND Workplaces.MACAddresses.Address IN(&MACAddresses)
	|
	|UNION ALL
	|
	|SELECT
	|	3,
	|	WorkplacesClientIDs.Ref,
	|	WorkplacesClientIDs.Ref.ComputerName
	|FROM
	|	Catalog.Workplaces.ClientIDs AS WorkplacesClientIDs
	|WHERE
	|	WorkplacesClientIDs.ClientID = &ClientID
	|	AND WorkplacesClientIDs.Ref.MACAddress IN(&MACAddresses)
	|	AND NOT WorkplacesClientIDs.Ref.DeletionMark
	|
	|UNION ALL
	|
	|SELECT
	|	4,
	|	Workplaces.Ref,
	|	Workplaces.ComputerName
	|FROM
	|	Catalog.Workplaces AS Workplaces
	|WHERE
	|	Workplaces.ComputerName = &ComputerName
	|	AND &ComputerName <> """"
	|	AND NOT Workplaces.DeletionMark
	|
	|UNION ALL
	|
	|SELECT
	|	5,
	|	Workplaces.Ref,
	|	Workplaces.ComputerName
	|FROM
	|	Catalog.Workplaces AS Workplaces
	|WHERE
	|	Workplaces.MACAddress IN(&MACAddresses)
	|	AND NOT Workplaces.DeletionMark
	|
	|UNION ALL
	|
	|SELECT
	|	5,
	|	Workplaces.Ref,
	|	Workplaces.ComputerName
	|FROM
	|	Catalog.Workplaces AS Workplaces
	|WHERE
	|	Workplaces.MACAddresses.Address IN(&MACAddresses)
	|	AND NOT Workplaces.DeletionMark
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT TOP 1
	|	WorkplacesByPriority.Ref AS Ref,
	|	WorkplacesByPriority.ComputerName AS ComputerName
	|FROM
	|	WorkplacesByPriority AS WorkplacesByPriority
	|
	|ORDER BY
	|	WorkplacesByPriority.Priority");
	
	
	Query.SetParameter("ClientID", ClientID);
	Query.SetParameter("ComputerName", ComputerName);
	Query.SetParameter("MACAddresses", MACAddresses);
	QueryResult = Query.Execute();
	If QueryResult.IsEmpty() Then
		Return Result;
	EndIf;
	
	Selection = QueryResult.Select();
	Selection.Next();
	WorkplaceLink = Selection.Ref;
	Result.Add(WorkplaceLink);
	
	If IsBlankString(Selection.ComputerName) And Not IsBlankString(ComputerName) Then
		WorkplaceObject = WorkplaceLink.GetObject();
		WorkplaceObject.ComputerName = ComputerName;
		WorkplaceObject.Write();
	EndIf;
	
	Return Result;
	
EndFunction

// This function sets the name of the client's computer to the session variable.
//
// Parameters:
//  CustomerWorkplace - CatalogRef.Workplaces
//
Procedure SetClientSWorkplace(CustomerWorkplace) Export

	SetPrivilegedMode(True);
	SessionParameters.CustomerWorkplace = CustomerWorkplace;

EndProcedure

// The function returns the created client workplace.
//
// Parameters:
//  Parameters - Structure:
//  * ClientID - String - unique identifier.
//  * ComputerName - String - computer name     
//  * MACAddress - String - MAC Address     
//
// Returns:
//  CatalogRef.Workplaces
//
Function CreateCustomerWorkplace(Parameters) Export

	If Not CommonCEL.SeparatedDataUsageAvailable() Then
		Return Catalogs.Workplaces.EmptyRef();
	EndIf;
	
	SetPrivilegedMode(True);
	
	Workplace = Catalogs.Workplaces.CreateItem();
	Workplace.Code = Parameters.ClientID;
	Workplace.ComputerName = Parameters.ComputerName;
	If Parameters.Property("MACAddresses") And Parameters.MACAddresses.Count() > 0 Then
		For Each MACAddress In Parameters.MACAddresses Do
			String = Workplace.MACAddresses.Add();
			String.Address = MACAddress;
		EndDo;
	EndIf;
	
	EquipmentManagerClientServer.FillInWorkplaceName(Workplace, InfoBaseUsers.CurrentUser());
	Workplace.Write();
	
	SetClientSWorkplace(Workplace.Ref);
	
	Return Workplace.Ref;

EndFunction 

// This procedure sets the values of session parameters related to the connected hardware.
//
// Parameters:
//  ParameterName - String - name of the session parameter. 
//  SpecifiedParameters - Array of String
//
Procedure SetSessionParametersOfConnectedHardware(ParameterName, SpecifiedParameters) Export

	If ParameterName = "CustomerWorkplace" Then
		
		UpdateClientWorkplace();
		
	EndIf;
	
EndProcedure

// The function returns the types of equipment used for the current workplace.
// 
// Returns:
//  Array
// 
Function TypesOfCurWorkplaceEquipmentUsed()  Export
	
	SetPrivilegedMode(True);
	Workplace = CustomerWorkplace();
	
	If ValueIsFilled(Workplace) Then
		
		Query = New Query(
		"SELECT DISTINCT
		|	Peripherals.EquipmentType AS EquipmentType
		|FROM
		|	Catalog.Peripherals AS Peripherals
		|WHERE
		|	Peripherals.DeviceIsInUse
		|	AND Peripherals.Workplace = &Workplace
		|	AND NOT Peripherals.DeletionMark
		|
		|UNION
		|
		|SELECT DISTINCT
		|	Peripherals.EquipmentType
		|FROM
		|	Catalog.Peripherals AS Peripherals
		|WHERE
		|	Peripherals.AttachmentType = VALUE(Enum.PeripheralsTypes.SharedAccess)
		|	AND Peripherals.DeviceIsInUse
		|	AND NOT Peripherals.DeletionMark");
		
		Query.SetParameter("Workplace", Workplace);
		
		Result = Query.Execute();
		Return Result.Unload().UnloadColumn("EquipmentType");
		
	Else
		Return Undefined;
	EndIf;
	
EndFunction

#EndRegion

#Region EquipmentOperation

// retrieves the list of software enabled in the Catalog by the set selection
//
// Parameters:
//  Filter - See EquipmentManagerClientServer.ListOfEquipmentSelection.
//
// Returns:
//  Array of Structure:
//    * Description - String
Function EquipmentList(Filter) Export
	
	Return EquipmentManager.EquipmentList(Filter);
	
EndFunction

// The function returns a structure with device data.
//
// Parameters:
//  Id - CatalogRef.Peripherals    
//  LanguageCode - String                                     
//  DeviceParameters - Structure - Device settings.
//
// Returns:
//  See Catalogs.Peripherals.DeviceData
//
Function DeviceData(Id, LanguageCode = Undefined, DeviceParameters = Undefined) Export
	
	Result = EquipmentManager.DeviceData(Id, LanguageCode);        
	
	If Not DeviceParameters = Undefined Then
		Result.Parameters = DeviceParameters;  
		Result.XMLParameters = EquipmentManager.GetXMLParameters(DeviceParameters, Result.EquipmentTypeName);
	EndIf;
	
	Return Result;
	
EndFunction

// Get connection parameters in XML
//
// Parameters:
//   Parameters - Structure - Connection parameters.     
//   EquipmentType - String - type of equipment.    
//   RecordParameters - Boolean - Flag for recording driver parameters.      
// Returns:
//   String -
//
Function GetXMLParameters(Parameters, EquipmentType = Undefined, RecordParameters = True)  Export
	
	Return EquipmentManager.GetXMLParameters(Parameters, EquipmentType, RecordParameters);
	
EndFunction    

// The function returns its parameters by the device ID
//
// Parameters:
//  Id - CatalogRef.Peripherals
//
// Returns:
//  - Arbitrary
//  - Structure
//
Function DeviceParameters(Id) Export
	
	Return EquipmentManager.DeviceParameters(Id);
	
EndFunction

// This procedure is intended for saving device parameters
// to the parameters of the storage type and values in the reference list element.
//
// Parameters:
//  Id - CatalogRef.Peripherals
//  Parameters - Structure - Device settings.
//
// Returns:
//  Boolean
//
Function SaveDeviceSettings(Id, Parameters) Export
	
	Return EquipmentManager.SaveDeviceSettings(Id, Parameters);
	
EndFunction

// The function returns a structure with driver data.
//
// Parameters:
//  DriverID - CatalogRef.HardwareDrivers - ID of the driver.
//
// Returns:
//  Structure
//
Function HardwareDriverData(DriverID) Export
	
	Return EquipmentManager.HardwareDriverData(DriverID);
	
EndFunction

// Get connection parameters from XML
//
// Parameters:
//   XMLParameters - String - Connection parameters in XML.     
// Returns:
//   Structure -
//
Function LoadXMLParameters(XMLParameters) Export
	
	Return EquipmentManager.LoadXMLParameters(XMLParameters);
	
EndFunction

Function DriverIsSuppliedInConfiguration(DeviceID) Export
	
	Return EquipmentManager.DriverIsSuppliedInConfiguration(DeviceID);
	
EndFunction

// ++ Non-mobile application

Function HardwareErrorTextAnalysis(DeviceID, Val ConnectionParameters, Val ErrorText) Export
	
	Return EquipmentManager.HardwareErrorTextAnalysis(DeviceID, ConnectionParameters, ErrorText);
	
EndFunction

// -- Non-mobile application


#EndRegion

#Region ObsoleteProceduresAndFunctions

// Outdated: you should use the equipment list.
// The Function Returns a list of connected Software in The Catalog
//
// Parameters:
//  SoftwareTypes - Structure, Array of String, String - the type of equipment to select the device.
//  Id - CatalogRef.Peripherals - connected device.
//  Workplace - CatalogRef.Workplaces
//  NetworkEquipment - Boolean - use network equipment when connecting.
//  ServerEquipment - Boolean
//  AutomaticFiscalizationOnly - Boolean
//
// Returns:
//  Array of Structure
// 
Function EquipmentByParameters(SoftwareTypes = Undefined, Id = Undefined, Workplace = Undefined, 
	NetworkEquipment = True, ServerEquipment = False, AutomaticFiscalizationOnly = False) Export
	
	SelectionList = EquipmentManagerClientServer.ListOfEquipmentSelection();
	SelectionList.SoftwareTypes                = SoftwareTypes;
	SelectionList.Id         = Id;
	SelectionList.Workplace          = Workplace;
	SelectionList.NetworkEquipment   = NetworkEquipment;  
	SelectionList.ServerEquipment = ServerEquipment;  
	SelectionList.AutomaticFiscalizationIsAllowed = AutomaticFiscalizationOnly;
	
	Return EquipmentManager.EquipmentList(SelectionList);
	
EndFunction

#Region System

// Outdated: You should use management equipment.Library versionsreferences.
// Returns the version number of the connected hardware library.
//
// Returns:
//  String
//
Function LibraryVersion() Export
	
	Return EquipmentManager.LibraryVersion();
	
EndFunction

// Deprecated: You should use a general purpose PO.A data session.
// Retrieves the Cur date of the server, set to the time zone of the session.
// It is intended to be used instead of the function of the current session date.
//
// Returns:
//  Date - the current date of the session.
//
Function SessionDate() Export
	
	Return CommonCEL.SessionDate();
	
EndFunction

// Outdated: you should use management equipment.Types of equipment are available.
// Retrieves the list of available hardware types.
// 
// Returns:
//   Array of EnumRef.PeripheralTypes - Array of available types of connected equipment in the configuration.
//
Function AvailableTypesOfEquipment() Export
	
	Return EquipmentManager.AvailableTypesOfEquipment();
	
EndFunction

// Outdated: The appropriate types of equipment should be used.
// Get matching equipment types
//
// Returns:
//   Map of KeyAndValue -
//
Function GetMatchingEquipmentTypes() Export
	
	Return EquipmentManager.CompatibilityOfEquipmentTypes();
	
EndFunction

// Deprecated: no longer in use.
// Returns True if the functional subsystem exists in the configuration.
//
// Parameters:
//  FullSubsystemName - String - the full name of the subsystem metadata object
//                        without the words " Subsystem."and case-sensitive.
//                        For example: "Standard subsystems.Variants of reports".
//  Returns:
//   Boolean - The truth, if it exists.
//
Function SubsystemExists(FullSubsystemName) Export
	
	Return CommonCEL.SubsystemExists(FullSubsystemName);
	
EndFunction

// Deprecated: you should use the integration system.Adding parameters to the work when you start.
// Fills in the client's operation parameters on the server
// When using BSP, the procedure must be called from the procedure 
// The general purpose is undefined.Adding parameters to the workinglient startup()
//
// Parameters:
//   Parameters - Structure:
//    * ClientID - String - (incoming) ID of the client's workplace
//    * EquipmentForReinstalling - Array of Structure - names of Templates for reinstalling external components
//    * IdOfDistributedFiscalizationDiscussion - CollaborationSystemConversationID -
Procedure OnAddClientParametersOnStart(Parameters) Export
	
	PELSubsystemsIntegration.OnAddClientParametersOnStart(Parameters);
	
EndProcedure

// Deprecated: you should use the integration system.Setting the Session parameters.
// The procedure sets the values of the session parameters related to the connected equipment.
//
// Parameters:
//  SessionParametersNames - Array of String - session parameter identifiers to be set
//
Procedure SessionParametersSetting(SessionParametersNames)  Export
	
	PELSubsystemsIntegration.SessionParametersSetting(SessionParametersNames);
	
EndProcedure

// Outdated: you should use management equipment.Available add-ons for new drivers.
// Returns the availability of adding new drivers.
// 
// Returns:
//  Boolean
//
Function AvailableAddingNewDrivers() Export
	
	Return EquipmentManager.AvailableAddingNewDrivers();
	
EndFunction

// Outdated: you should use management equipment.Available network equipment.
// Returns the availability of network equipment.
//
// Returns:
//  Boolean
//
Function AvailableNetworkEquipment() Export
	
	Return EquipmentManager.AvailableNetworkEquipment();
	
EndFunction

// Deprecated: Distributed virtualization should be used.Available distributedfiscalization.
// Returns a sign that distributed fiscalization is available.
// 
// Returns:
//  Boolean
//
Function AvailableDistributedFiscalization() Export
	
	If CommonCEL.DistributedFiscalizationIsUsed() Then
		ModuleDistributedFiscalization = CommonCEL.CommonModule("Distributed_Fiscalization");
		Return ModuleDistributedFiscalization.AvailableDistributedFiscalization();
	Else
		Return False;
	EndIf;
	
EndFunction

// Outdated: you should use management equipment.Available network equipment.
// Returns the availability of collection in the Fiscal device management form.
// 
// Returns:
//  Boolean
//
Function CollectionInManagementOfFiscalDeviceIsAvailable() Export
	
	Return EquipmentManager.CollectionInManagementOfFiscalDeviceIsAvailable();
	
EndFunction

// Deprecated: no longer in use.
// Returns True if input devices are used and these subsystems exist in the configuration.
// It is intended for the implementation of an optional subsystem call (conditional call).
//
// Returns:
//  Boolean
//
Function InputDevicesAreUsed() Export
	
	Return CommonCEL.InputDevicesAreUsed();
	
EndFunction

// Deprecated: no longer in use.
// Returns True if "Magnetic Card Templates" devices are used and these subsystems exist in the configuration.
// It is intended for the implementation of an optional subsystem call (conditional call).
//
// Returns:
//  Boolean
//
Function MagneticCardTemplatesAreUsed() Export
	
	Return CommonCEL.MagneticCardTemplatesAreUsed();
	
EndFunction

// Deprecated: no longer in use.
// Returns True if subsystems of fiscal devices are used and these subsystems exist in the configuration.
// It is intended for the implementation of an optional subsystem call (conditional call).
//
// Returns:
//  Boolean
//
Function CheckPrintingDevicesAreUsed() Export
	
	Return CommonCEL.CheckPrintingDevicesAreUsed();
	
EndFunction

// Deprecated: no longer in use.
// Returns True if the "Cash Shift" is used and these subsystems exist in the configuration.
// It is intended for the implementation of an optional subsystem call (conditional call).
//
// Returns:
//  Boolean
//
Function CashShiftIsUsed() Export
	
	Return CommonCEL.CashShiftIsUsed();
	
EndFunction               

// Deprecated: no longer in use.
// Returns True if "Formatological Control" is used and these subsystems exist in the configuration.
// It is intended for the implementation of an optional subsystem call (conditional call).
//
// Returns:
//  Boolean
//
Function FormatLogicalControlIsUsed() Export
	
	Return CommonCEL.FormatLogicalControlIsUsed();
	
EndFunction  

// Deprecated: no longer in use.
// Returns True if the Payment Systems subsystem is used and this subsystem exists in the configuration.
// It is intended for the implementation of an optional subsystem call (conditional call).
//
// Returns:
//  Boolean
//
Function UsedPaymentSystems() Export
	
	Return CommonCEL.UsedPaymentSystems();
	
EndFunction

// Deprecated: no longer in use.
// Returns True if the "Customer Displays" subsystem is used and this subsystem exists in the configuration.
// It is intended for the implementation of an optional subsystem call (conditional call).
//
// Returns:
//  Boolean
//
Function UsedBuyerSDisplays() Export
	
	Return CommonCEL.UsedBuyerSDisplays();
	
EndFunction

// Deprecated: no longer in use.
// Returns True if the Weighing Equipment subsystem is used and this subsystem exists in the configuration.
// It is intended for the implementation of an optional subsystem call (conditional call).
//
// Returns:
//  Boolean
//
Function WeightEquipmentIsUsed() Export
	
	Return CommonCEL.WeightEquipmentIsUsed();
	
EndFunction

// Deprecated: no longer in use.
// Returns True if the subsystem "Data collection terminals" is used and this subsystem exists in the configuration.
// It is intended for the implementation of an optional subsystem call (conditional call).
//
// Returns:
//  Boolean
//
Function DataCollectionTerminalsAreUsed() Export
	
	Return CommonCEL.DataCollectionTerminalsAreUsed();
	
EndFunction

// Deprecated: no longer in use.
// Returns True if the Label Printers subsystem is used and this subsystem exists in the configuration.
// It is intended for the implementation of an optional subsystem call (conditional call).
//
// Returns:
//  Boolean
//
Function LabelPrintersAreUsed() Export
	
	Return CommonCEL.LabelPrintersAreUsed();
	
EndFunction

// Deprecated: no longer in use.
// Returns True if the "RFID Reader" subsystem is used and this subsystem exists in the configuration.
// It is intended for the implementation of an optional subsystem call (conditional call).
//
// Returns:
//  Boolean
//
Function RFIDReaderIsUsed() Export
	
	Return CommonCEL.RFIDReaderIsUsed();
	
EndFunction

// Deprecated: no longer in use.
// Returns True if the "Offline Equipment" subsystem is used and this subsystem exists in the configuration.
// It is intended for the implementation of an optional subsystem call (conditional call).
//
// Returns:
//  Boolean
//
Function OfflineEquipmentIsUsed() Export
	
	Return CommonCEL.OfflineEquipmentIsUsed();
	
EndFunction

// Deprecated: no longer in use.
// Returns True if the "Label and price tag printing" subsystem is used and this subsystem exists in the configuration.
// It is intended for the implementation of an optional subsystem call (conditional call).
//
// Returns:
//  Boolean
//
Function PrintingOfLabelsAndPriceTagsIsUsed() Export
	
	Return CommonCEL.PrintingOfLabelsAndPriceTagsIsUsed();
	
EndFunction

// Deprecated: no longer in use.
// Returns True if the subsystem "NSPK Electronic Certificates" is used and this subsystem exists in the configuration.
// It is intended for the implementation of an optional subsystem call (conditional call).
//
// Returns:
//  Boolean
//
Function ElectronicCertificatesOfNSPKAreUsed() Export
	
	Return CommonCEL.ElectronicCertificatesOfNSPKAreUsed();
	
EndFunction

// Deprecated: no longer in use.
// Returns True if the subsystem "Certificates of NUC Mincifra" is used and this subsystem exists in the configuration.
// It is intended for the implementation of an optional subsystem call (conditional call).
//
// Returns:
//  Boolean
//
Function UsingCertificatesOfNCAMDD() Export
	
	Return CommonCEL.UsingCertificatesOfNCAMDD();
	
EndFunction

#EndRegion

#Region GOSISCompatibility
 
// Outdated: You should use a working client.
// The function returns the name of the client's computer from the session variable.
//
// Returns: 
//   CatalogRef.Workplaces - the client's workplace.
//
Function GetClientSWorkplace() Export
	
	Return CustomerWorkplace();
	
EndFunction

// Outdated: Printing equipment should be used.Fiscal Management supports the verification of labeling codes.
// Returns whether the fiscal device supports it.
// 
// Parameters:
//  DeviceID - CatalogRef.Peripherals - Device ID.
// 
// Returns:
//  Boolean - The fiscal device supports checking the marking codes
Function FiscalDeviceSupportsVerificationOfMarkingCodes(DeviceID) Export
	
	If CommonCEL.CheckPrintingDevicesAreUsed() Then
		ModuleEquipmentReceiptPrintingDevices = CommonCEL.CommonModule("PeripheralsReceiptPrinters");
		Return ModuleEquipmentReceiptPrintingDevices.FiscalDeviceSupportsVerificationOfMarkingCodes(DeviceID);
	Else
		Return Undefined;
	EndIf;
	
EndFunction

// Outdated: You should use the equipment of the printer call server.Fiscal Management supports the version of the UFFD.
// The function returns the FFD version for the fiscal device.
// 
// Parameters:
//  DeviceID - CatalogRef.Peripherals - Device ID.
// 
// Returns:
//  Undefined - The fiscal device supports the FFD version
Function FiscalDeviceSupportsFFDVersion(DeviceID) Export
	
	If CommonCEL.CheckPrintingDevicesAreUsed() Then
		ModuleHardwareReceiptPrintingDevicesServerCall = CommonCEL.CommonModule("EquipmentReceiptPrintersServerCall");
		Return ModuleHardwareReceiptPrintingDevicesServerCall.FiscalDeviceSupportsFFDVersion(DeviceID);
	Else
		Return Undefined;
	EndIf;
	
EndFunction

#EndRegion

#Region CodeForTypeOfNomenclatureClassification

// Deprecated: no longer in use.
// Returns the classifier of the code of the type of nomenclature classification
//
// Returns:
//  ValueTable
//
Function CodesForTypeOfNomenclatureClassification() Export
	
	ValueTable = New ValueTable;
	ValueTable.Columns.Add("ProductClassificationTypeDescription",,"ProductClassificationTypeDescription");
	ValueTable.Columns.Add("ProductClassificationTypeCode",,"ProductClassificationTypeCode");
	
	
	Return ValueTable;
	
EndFunction

#EndRegion

#Region DistributedFiscalization

#If Not MobileAppServer Then 

// Deprecated: Distributed virtualization should be used.Discussion of fiscalization.
// Creates a discussion of fiscalization.
// 
// Returns:
//  Undefined, CollaborationSystemConversationID - The discussion of fiscal
//
Function DiscussionOfFiscalization() Export
	
	If CommonCEL.DistributedFiscalizationIsUsed() Then
		ModuleDistributedFiscalization = CommonCEL.CommonModule("Distributed_Fiscalization");
		Return ModuleDistributedFiscalization.DiscussionOfFiscalization();
	EndIf;
	
EndFunction

// Deprecated: Distributed virtualization should be used.Create a Fiscalization message.
// Creates a message for fiscalizing the receipt
// 
// Parameters:
//  ReceiptID - UUID
//  IinOrganization - String
//
Procedure CreateFiscalizationMessage(ReceiptID, IinOrganization = Undefined) Export
	
	If CommonCEL.DistributedFiscalizationIsUsed() Then
		ModuleDistributedFiscalization = CommonCEL.CommonModule("Distributed_Fiscalization");
		ModuleDistributedFiscalization.CreateFiscalizationMessage(ReceiptID, IinOrganization);
	EndIf;
	
EndProcedure

#EndIf

#EndRegion


// Deprecated: You should use the Client Server Hardware manageringprocess.youre64vshtrichcode.
// Base64 in barcode.
// 
// Parameters:
//  BarcodeInBase64 - String - Barcode in base64
// 
// Returns:
//  String - Base64 to Barcode
//
Function Base64BBarcode(BarcodeInBase64) Export
	
	BinaryData = Base64Value(BarcodeInBase64);
	If BinaryData = Undefined Then
		Barcode = BarcodeInBase64;
	Else
		Barcode = GetStringFromBinaryData(BinaryData);
	EndIf;
	
	Return Barcode;
	
EndFunction

// Deprecated: You should use the Client Server Hardware manageringprocess.Barcode in base64.
// Barcode in base64.
// 
// Parameters:
//  Barcode - String - Barcode
// 
// Returns:
//  String - Barcode in base64
//
Function BarcodeInBase64(Barcode) Export
	
	If Barcode = Undefined Then 
		RowBinaryData = Undefined;
	Else
		RowBinaryData = GetBinaryDataFromString(Barcode);
		BarcodeBASE64 = Base64String(RowBinaryData);
		BarcodeBASE64 = StrReplace(BarcodeBASE64, Chars.LF, "");
		BarcodeBASE64 = StrReplace(BarcodeBASE64, Chars.CR, "");
	EndIf;
	
	Return BarcodeBASE64;
	
EndFunction

#EndRegion

#EndRegion

#Region Internal

Function ParametersTypesOfEquipment() Export
	
	Return EquipmentManagerCached.ParametersTypesOfEquipment();
	
EndFunction

// The function calls the procedure for preparing of operation data on the server.
//
// Parameters:
//  ConnectionParameters - Structure - hardware connection parameters.   
//  ProcessorOfData - String - Data processing module. 
//  Command - String - name of the command to run. 
//  OperationParametersList - Structure - Parameters of operation being performed.   
//
// Returns:
//  Structure
//
Function PrepareOperationData(ConnectionParameters, ProcessorOfData, Command, OperationParametersList) Export 
	
	ModuleDataProcessor = CommonCEL.CommonModule(ProcessorOfData);
	Return ModuleDataProcessor.PrepareOperationData(ConnectionParameters, Command, OperationParametersList);
	
EndFunction

// Procedure for processing of operation data on the server.
//
// Parameters:
//  ConnectionParameters - Structure - hardware connection parameters.   
//  ProcessorOfData - String - Data processing module. 
//  Command - String - name of the command to run.       
//  ExecutionResult - Structure - The result of the execution.   
//  OperationData - Structure - Data of the completed of operation.   
//
Procedure ProcessOperationData(ConnectionParameters, ProcessorOfData, Command, ExecutionResult, OperationData) Export 
	
	ModuleDataProcessor = CommonCEL.CommonModule(ProcessorOfData);
	ModuleDataProcessor.ProcessOperationData(ConnectionParameters, Command, ExecutionResult, OperationData);
	
EndProcedure

Function CompatibilityOfExternalComponentFromFile(Val TemplateName) Export
	
	Return EquipmentManagerCached.CompatibilityOfExternalComponentFromFile(TemplateName);
	
EndFunction

#Region RFID

// Get a table of RFID tags. Used for contacting the web client.
//
// Parameters:
//  LBLData - String
//
// Returns:
//  Array of Structure
// 
Function RFIDTags(LBLData) Export
	
	Return EquipmentManagerClientServer.RFIDTags(LBLData);
	
EndFunction

#EndRegion         

#Region Workplaces

// Returns the client's workplace found based on the transmitted selection
// 
// Parameters:
//  WorkplaceSearchParameters - See EquipmentManagerClient.Peripherals
//  CreateWorkplace - Boolean - Create A Workplace
// 
// Returns:
//  CatalogRef.Workplaces, Arbitrary - The found workplace of the client, otherwise an empty link
Function UpdateClientWorkplace(WorkplaceSearchParameters = Undefined, CreateWorkplace = False) Export
	
	SetPrivilegedMode(True);
	EquipmentManager.FillInCurrentAttributesOfWorkplace(WorkplaceSearchParameters);
	
	ClientID = "";
	ComputerName = "";
	MACAddresses = "";
	If WorkplaceSearchParameters <> Undefined Then
		ClientID = WorkplaceSearchParameters.ClientID;
		ComputerName = WorkplaceSearchParameters.ComputerName;
		MACAddresses = WorkplaceSearchParameters.MACAddresses;
	EndIf;
	
	CurCurrentRM = Catalogs.Workplaces.EmptyRef();
	ListOfRM = FindWorkplacesById(ClientID, ComputerName, MACAddresses);
	If ListOfRM.Count() > 0 Then
		CurCurrentRM = ListOfRM[0];
		EquipmentManager.UpdateWorkplaceAttributes(CurCurrentRM, WorkplaceSearchParameters);
	Else
		If CreateWorkplace Then
			CurCurrentRM = CreateCustomerWorkplace(WorkplaceSearchParameters);
		EndIf;
	EndIf;
	
	SetClientSWorkplace(CurCurrentRM);
	Return CurCurrentRM;
	
EndFunction

// Updates workplace Attributes
// 
// Parameters:
//  Workplace - CatalogRef.Workplaces - Job
//  CurrentWorkplaceAttributes - See EquipmentManagerClient.Peripherals
//
Procedure UpdateWorkplaceAttributes(Workplace, CurrentWorkplaceAttributes) Export
	
	EquipmentManager.UpdateWorkplaceAttributes(Workplace, CurrentWorkplaceAttributes);
	
EndProcedure


Procedure UpdateWorkplaceId(Workplace, NewID1) Export
	
	If ValueIsFilled(Workplace) Then
		
		WorkplaceObject = Workplace.GetObject();
		WorkplaceObject.Code = NewID1;
		WorkplaceObject.Write();
		
	EndIf;
	
EndProcedure

// Binds client ID to workplace Catalog element
//
// Parameters:
//   ClientID - String
//   MACAddress - String
//
// Returns:
//   Array of CatalogRef.Workplaces
//
Function LinkWorkplaceToMACAddress(ClientID, MACAddress) Export
	
	If Not CommonCEL.SeparatedDataUsageAvailable() Then
		Return New Array();
	EndIf;
	
	SetPrivilegedMode(True);
	
	ListOfJobs = FindWorkplacesById(ClientID, "", MACAddress);
	
	If ListOfJobs.Count() > 0 Then   
		CurrentWorkplace = ListOfJobs[0].GetObject();                     
		If CurrentWorkplace.ClientIDs.Find(ClientID, "ClientID") = Undefined  Then 
			ClientIDs = CurrentWorkplace.ClientIDs.Add();   
			ClientIDs.ClientID = ClientID;
			CurrentWorkplace.LocalDevice = True;
			CurrentWorkplace.Write();       
		EndIf;
	Else
		Parameters = New Structure;
		Parameters.Insert("ClientID", ClientID);
		Parameters.Insert("MACAddress"            , MACAddress);     
		Parameters.Insert("ComputerName");
		Workplace = CreateCustomerWorkplace(Parameters);         
		CurrentWorkplace = Workplace.GetObject();         
		If CurrentWorkplace.ClientIDs.Find(ClientID, "ClientID") = Undefined  Then 
			ClientIDs = CurrentWorkplace.ClientIDs.Add();   
			ClientIDs.ClientID = ClientID;
			CurrentWorkplace.LocalDevice = True;
			CurrentWorkplace.Write();       
		EndIf;
		ListOfJobs.Add(Workplace);
	EndIf;
	SetClientSWorkplace(ListOfJobs[0]);
	
	Return ListOfJobs;
	
EndFunction

Procedure SaveMACAddressForWorkplace(MACAddress) Export
	
	SetPrivilegedMode(True);
	
	CustomerWorkplace = CustomerWorkplace();
	If ValueIsFilled(CustomerWorkplace) Then
		ClientWorkplaceMACAddress = CommonCEL.ObjectAttributeValue(CustomerWorkplace, "MACAddress");
		If ClientWorkplaceMACAddress <> MACAddress Then
			WorkplaceObject = CustomerWorkplace.GetObject();
			WorkplaceObject.MACAddress = MACAddress;
			WorkplaceObject.Write();
		EndIf;
	EndIf;
	
EndProcedure

// The function provides information about the current workplace.
// 
// Returns:
//  Structure:
//   * Workplace - CatalogRef.Workplaces
//   * IsPeripherals - Boolean
//
Function InformationAboutClientSWorkplace() Export
	
	Result = New Structure();
	Result.Insert("Workplace", CustomerWorkplace());
	Result.Insert("IsPeripherals", EquipmentManager.IsPeripherals());
	Return Result;
	
EndFunction

#EndRegion

#Region ExchangeWithServer

Procedure ExchangeWithServer(DataForServer, Val DataForServerByValue) Export
	
	If CommonCEL.CashShiftIsUsed() Then
		If DataForServer.Property("StatusesOfCashShifts") Then
			StatusesOfCashShifts = DataForServer.StatusesOfCashShifts;
			CashShiftModule = CommonCEL.CommonModule("RegisterShifts");
			For Each Status In StatusesOfCashShifts Do
				ShiftStatus = CashShiftModule.LastShiftStatus(Status.Key);
				StatusesOfCashShifts.Insert(Status.Key, ShiftStatus);
			EndDo;
		EndIf;
		
	EndIf;
	
	If DataForServerByValue.Property("LoggingRecords") Then
		
		LoggingRecords = DataForServerByValue.LoggingRecords;
		LoggingOfCELOperations.RecordLogOfOperationsATServerInBackground(LoggingRecords);
		
	EndIf;
	
	
EndProcedure

#EndRegion

// Records an archive of driver logs for the specified connected hardware.
//
// Parameters:
//  Peripherals - CatalogRef.Peripherals - 
//      equipment for which logs are recorded
//  Data - Array of TransferableFileDescription - if the files are transferred to the server for archiving
//         - BinaryData  - if the files were archived on the client
Procedure RecordArchiveOfDriverLogs(Peripherals, Val Data) Export
	
	InformationRegisters.HardwareDriverLogArchive.
		RecordArchiveOfDriverLogs(Peripherals, Data);
	
EndProcedure

// Sends a response to a request to record an archive of the connected hardware driver logs.
//
// Parameters:
//   QueryData - Structure - data from the original request:
//    * Peripherals - CatalogRef.Peripherals - 
//       Link To The Connected Equipment
//    * SessionNumberToRespondTo - Number - session number for sending the request
//    * Data - Structure - log archive record data
//   ImportResult1 - Structure - the result of processing the request to be sent:
//    * Success - Boolean - whether the request was processed successfully
//    * ErrorText - String - processing error text
//
Procedure SendResponseToDriverLogArchiveEntry(Val QueryData, Val ImportResult1) Export

	Catalogs.Peripherals.
		SendResponseToDriverLogArchiveEntry(QueryData, ImportResult1);
	
EndProcedure

Function CallHTTPMethodServer(Method, ConnectionParameters) Export
	
	Result = EquipmentManagerClientServer.ResultOfCallingHTTPMethod();
	Result.CallingAtServer = True;
	
	If CommonCEL.SubsystemExists("StandardSubsystems.GetFilesFromInternet") Then
		GettingFilesFromInternetModule = CommonCEL.CommonModule("GetFilesFromInternet");
		Proxy = GettingFilesFromInternetModule.GetProxy("https");
	Else
		Proxy = Undefined;
	EndIf;
	
	If ConnectionParameters.Port = 443 Then
		SecureConnection = CommonCELClientServer.NewSecureConnection();
		Join = New HTTPConnection(
			ConnectionParameters.Host, ConnectionParameters.Port, , , Proxy, ConnectionParameters.Timeout, SecureConnection);
	Else
		Join = New HTTPConnection(
			ConnectionParameters.Host, ConnectionParameters.Port, , , Proxy, ConnectionParameters.Timeout);
	EndIf;
		
	If ValueIsFilled(ConnectionParameters.AccessToken) Then
		ConnectionParameters.Headers.Insert("Authorization", ConnectionParameters.AccessToken);
	EndIf;
	HTTPRequest = New HTTPRequest(ConnectionParameters.ResourceAddress, ConnectionParameters.Headers);
	
	Try
		HTTPResponse = Join.CallHTTPMethod(Method, HTTPRequest);
		Result.ResponseCode = HTTPResponse.StatusCode;
		Result.ResponseBody = HTTPResponse.GetBodyAsString();
	Except
		ErrorInfo = ErrorInfo();
		If ErrorInfo.IsErrorOfCategory(ErrorCategory.NetworkError) Then
			Result.Timeout = True;
		Else
			CommonCEL.WriteErrorToEventLog(
				NStr("vi = 'Lỗi truy cập vào dịch vụ xác minh độ tuổi Max';
					|ru = 'Ошибка доступа к сервису проверки возраста Макс';
					|en = 'Error accessing the Max age verification service'; fa = 'Error accessing the Max age verification service';
					|it = 'Error accessing the Max age verification service';
					|pl = 'Error accessing the Max age verification service';
					|tr = 'Maks yaş doğrulama hizmetine erişim hatası'"), 
				ErrorProcessing.DetailErrorDescription(ErrorInfo()));
		EndIf;
		Result.ErrorDescription = ErrorProcessing.ErrorDescriptionForUser(ErrorInfo);
	EndTry;
	
	Return Result;
	
EndFunction

#Region AllowedMethodsToBeCalledAsArbitraryCode

// Returns a list of methods that can be called as arbitrary code
// (for routine tasks and background tasks)
Procedure OnDefineMethodsAllowedForCallAsArbitraryCode(Methods) Export
	
	Methods.Insert("SetSessionParametersOfConnectedHardware", True);
	
EndProcedure

#EndRegion

#EndRegion

