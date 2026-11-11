#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region Public

// retrieves the list of software enabled in the Catalog by the set selection
//
// Parameters:
//  Filter - See EquipmentManagerClientServer.ListOfEquipmentSelection.
//
// Returns:
//  Array of Structure
//
Function EquipmentList(Filter) Export
	
	Id  = Filter.Id;    
	SoftwareTypes         = Filter.SoftwareTypes;
	Workplace   = Filter.Workplace;
	Organization    = Filter.Organization;     
	
	ArrayOfSOFTWARETypes = EquipmentManager.ArrayOfEquipmentTypes(SoftwareTypes);
	
	NetworkEquipment    = Filter.NetworkEquipment;
	CurrentIBUser  = String(InfoBaseUsers.CurrentUser());
	LanguageCode = Filter.LanguageCode; 
	
	SetPrivilegedMode(True);
	
	If Not ValueIsFilled(Workplace) Then
		// If the RM is not specified in the parameters, then it is always the current one from the session parameters.
		Workplace = EquipmentManagerServerCall.CustomerWorkplace();
	EndIf;
	
	Query       = New Query();
	QueryText = "SELECT ALLOWED
	               |	Peripherals.Ref AS Ref,
	               |	Peripherals.Description AS Description,
	               |	Peripherals.EquipmentType AS EquipmentType,
	               |	Peripherals.HardwareDriver AS HardwareDriver,
	               |	Peripherals.HardwareDriver.PredefinedDataName AS HardwareDriverName,
	               |	Peripherals.HardwareDriver.Predefined AS AsPartOfConfiguration,
	               |	Peripherals.HardwareDriver.ObjectID AS ObjectID,
	               |	Peripherals.HardwareDriver.NoLongerSupported AS NoLongerSupported,
	               |	Peripherals.HardwareDriver.MessageWhenUsing AS MessageWhenUsing,
	               |	Peripherals.HardwareDriver.DriverVersion AS DriverVersion,
	               |	Peripherals.HardwareDriver.DriverTemplateName AS DriverTemplateName,
	               |	Peripherals.HardwareDriver.ConnectionMethod AS ConnectionMethod,
	               |	Peripherals.HardwareDriver.PredefinedDataName AS PredefinedDataName,
	               |	Peripherals.HardwareDriver.SafeConnection AS SafeConnection,
	               |	Peripherals.AttachmentType AS AttachmentType,
	               |	Peripherals.Workplace AS Workplace,
	               |	Peripherals.AutomaticFiscalization AS AutomaticFiscalization,
	               |	Peripherals.ReinstallationIsRequired AS ReinstallationIsRequired,
	               |	Peripherals.InstallationIsRequired AS InstallationIsRequired,
	               |	Peripherals.Use36MonthsFSUTIIIs AS Use36MonthsFSUTIIIs,  
	               |	Peripherals.Organization AS Organization,
	               |	Peripherals.AccessRestriction.(
	               |		User AS User,
	               |		Ref AS Ref
	               |	) AS AccessRestriction,
	               |	Peripherals.Parameters AS Parameters
	               |FROM
	               |	Catalog.Peripherals AS Peripherals
	               |WHERE
	               |	&Condition
	               |	AND NOT Peripherals.EquipmentType IN (&ExcludedTypesOfEquipment)
	               |	AND (Peripherals.Description <> """")
	               |
	               |ORDER BY
	               |	Description"; 
	
	ConditionText = "(NOT Peripherals.DeletionMark AND Peripherals.DeviceIsInUse)";
	If Id <> Undefined Then
		If TypeOf(Id) = Type("Array") Then
			ConditionText = ConditionText + " AND (Peripherals.Ref IN (&IDs))";
			Query.SetParameter("IDs", Id);     
		Else
			ConditionText = ConditionText + " AND (Peripherals.Ref = &Id)";
			Query.SetParameter("Id", Id);     
		EndIf;
	Else
		ConditionText = ConditionText + " AND (Peripherals.Workplace = &Workplace";
		Query.SetParameter("Workplace", Workplace);
		If NetworkEquipment Then
			// Equipment connected to a specific workplace and network equipment.
			ConditionText = ConditionText
				+ " OR Peripherals.AttachmentType = VALUE(Enum.PeripheralsTypes.SharedAccess))";
		Else
			ConditionText = ConditionText + ")";
		EndIf;
		If ArrayOfSOFTWARETypes.Count()>0 Then
			ConditionText = ConditionText + " AND (Peripherals.EquipmentType  IN (&EquipmentType))";
			Query.SetParameter("EquipmentType", ArrayOfSOFTWARETypes);
		EndIf;
		If Organization <> Undefined Then
			ConditionText = ConditionText + " AND (Peripherals.Organization = &Organization)";
			Query.SetParameter("Organization", Organization);
		EndIf;
	EndIf;
	ExcludedTypesOfEquipment = New Array();
	ExcludedTypesOfEquipment.Add(Enums.PeripheralTypes.DeleteOfflineEquipment);
	Query.SetParameter("ExcludedTypesOfEquipment", ExcludedTypesOfEquipment);
	
	Query.Text = StrReplace(QueryText, "&Condition", ConditionText);
	Selection = Query.Execute().Select();
	
	// Going through the selection we make a list of devices
	EquipmentList = New Array();
	While Selection.Next() Do
		DeviceData = FillInDeviceData(Selection, CurrentIBUser, LanguageCode);
		EquipmentList.Add(DeviceData);
	EndDo;
	
	// We return the received list with the data of all found devices
	Return EquipmentList;
	
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
	
	Query = New Query("
	|SELECT
	|	Peripherals.Parameters
	|FROM
	|	Catalog.Peripherals AS Peripherals
	|WHERE
	|	Peripherals.Ref = &Id");
	
	Query.SetParameter("Id", Id);
	Selection = Query.Execute().Select();
	Selection.Next();
	
	EquipmentParameters = Selection.Parameters; // ValueStorage
	Result = EquipmentParameters.Get();
	Return Result;
	
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
	
	Query = New Query();
	Query.Text = 
		"SELECT TOP 1
	                      |	Peripherals.Ref AS Ref
		|FROM
		|	Catalog.Peripherals AS Peripherals
		|WHERE
		|	Peripherals.Ref = &Id";
		
		Query.SetParameter("Id", Id);
	QueryResult = Query.Execute();
	If QueryResult.IsEmpty() Then
		Return False;
	EndIf;
		
	Try
		Selection = QueryResult.Select();
		Selection.Next();
		ObjectOfCatalog = Selection.Ref.GetObject(); // CatalogObject.Peripherals
		ObjectOfCatalog.Lock();
		ObjectOfCatalog.Parameters = New ValueStorage(Parameters);
		ObjectOfCatalog.Write();
		Result = True;
	Except
		Result = False;
	EndTry;
	
	Return Result;
	
EndFunction

// The function returns a structure with device data
//
// Parameters:
//  Id - CatalogRef.Peripherals
//  LanguageCode - String
//
// Returns:
//  - Arbitrary
//  - Undefined 
//  - Structure:
//   * Ref - CatalogRef.Peripherals
//   * EquipmentType - Structure
//   * Description - String
//   * Parameters - Structure
//   * HardwareDriver - CatalogRef.HardwareDrivers
//   * AsPartOfConfiguration - Boolean
//   * ObjectID - String
//   * NoLongerSupported - Boolean
//   * DriverVersion - String
//   * NetworkEquipment - Boolean
//   * ConnectionMethod - EnumRef.DriverConnectionMethod
//   * ConnectingFromTemplate - Boolean
//   * ConnectingLocallyById - Boolean
//   * DriverTemplateName - String
//   * TemplateIsAvailable - Boolean
//   * AutomaticFiscalization - Boolean
//   * Use36MonthsFSUTIIIs - Boolean
//   * ReinstallationIsRequired - Boolean
//   * InstallationIsRequired - Boolean
//   * AccessRestriction - Array of String
//   * AvailableToCurrentUser - Boolean
//   * RegistrationParameters - Structure
//
Function DeviceData(Id, LanguageCode = Undefined) Export
	
	SelectionList = EquipmentManagerClientServer.ListOfEquipmentSelection();   
	SelectionList.Id = Id;    
	SelectionList.LanguageCode = LanguageCode;
	
	EquipmentList = EquipmentList(SelectionList);
	If EquipmentList.Count() > 0 Then
		Result = EquipmentList[0]
	Else
		Result = Undefined;
	EndIf;
	
	Return Result;
	
EndFunction

// StandardSubsystems.AccessManagement
// See AccessManagementOverridable.OnFillListsWithAccessRestriction.
//
// Parameters:
//  Restriction - Structure:
//    * Text                             - String - restricting access for users.
//                                          If the string is empty, it means that access is allowed.
//    * TextForExternalUsers1      - String - restricting access for external users.
//                                          If the string is empty, it means that access is denied.
//    * ByOwnerWithoutSavingAccessKeys - Undefined - to determine automatically.
//                                        - Boolean - if False, then always write access keys,
//                                          if True, then do not write access keys,
//                                          but use the owner's access keys (it is required
//                                          that the restriction be strictly on the owner object).
//   * ByOwnerWithoutSavingAccessKeysForExternalUsers - Undefined, Boolean - the
//                                          same as for the parameter for the owner of the record of the key access.
//
Procedure OnFillAccessRestriction(Restriction) Export
	
	Manager = "Catalog.Peripherals";
	EquipmentManagerServerCallOverridable.OnFillAccessRestriction(Manager, Restriction);
	
EndProcedure
// End StandardSubsystems.AccessManagement

// The procedure fills in the item in the Catalog of connected equipment.
//
// Parameters:
//  CreationParameters - Structure - parameters for creating plug-in equipment.
//
// Returns:
//  CatalogRef.Peripherals - 
//
Function CreateNewItem(CreationParameters) Export
	
	NewItem = Catalogs.Peripherals.CreateItem();
	
	If TypeOf(CreationParameters.EquipmentType) = Type("String") Then
		CreationParameters.EquipmentType = EquipmentManager.EquipmentTypeByLine(CreationParameters.EquipmentType);
	EndIf;
	Description = CreationParameters.Description;
	If IsBlankString(Description) Then
		Description = "'" + String(CreationParameters.HardwareDriver) + "'"
					   + ?(IsBlankString(String(CreationParameters.Workplace)), "", " " + NStr("vi = 'vào';
																								|ru = 'на';
																								|en = 'to'; fa = 'تا';
																								|it = 'на';
																								|pl = 'to';
																								|tr = 'itibarıyla'") + " " + String(CreationParameters.Workplace));   
	EndIf;
	NewItem.Description = Description;
	NewItem.EquipmentType = CreationParameters.EquipmentType;   
	NewItem.AttachmentType  = CreationParameters.AttachmentType;
	NewItem.DeviceIsInUse = CreationParameters.DeviceIsInUse;
	NewItem.HardwareDriver    = CreationParameters.HardwareDriver;
	NewItem.Organization            = CreationParameters.Organization; 
	NewItem.Workplace           = CreationParameters.Workplace;
	NewItem.SerialNumber          = CreationParameters.SerialNumber;
	NewItem.MethodOfFormatLogicalControl = CreationParameters.MethodOfFormatLogicalControl;   
	NewItem.AllowableDiscrepancyOfFormatLogicalControl = CreationParameters.AllowableDiscrepancyOfFormatLogicalControl;
	NewItem.Use36MonthsFSUTIIIs = CreationParameters.Use36MonthsFSUTIIIs;
	
	NewItem.Write();
	
	Return NewItem.Ref;
	
EndFunction

#EndRegion

#Region Internal

// Returns a table of drivers for all hardware that has been added to the Catalog 
// of connected hardware
// 
// Parameters:
//   ConnectionMethod - EnumRef.DriverConnectionMethod - if the value is not passed, 
//                       it will be selected regardless of the connection method
//   HardwareId - CatalogRef.Peripherals, Undefined - 
//   Workplace - CatalogRef.Workplaces, Undefined - 
//
// Returns:
//  ValueTable:
//    * Ref - CatalogRef.HardwareDrivers
//    * Description - String
//    * Id - String
//    * Version - String
//    * ConnectionMethod - EnumRef.DriverConnectionMethod
//    * TemplateName - String - name of the Template where the driver is located
//    * TemplateIsAvailable - Boolean - if False, then there is no driver Template in the library
//    * VBPOEnters - Boolean - flag that the driver is included in the BPO library
//
Function UsedDrivers(ConnectionMethod = Undefined, HardwareId = Undefined, Workplace = Undefined) Export
	
	SetPrivilegedMode(True);
	
	Query = New Query;
	Query.Text = 
		"SELECT DISTINCT
		|	Peripherals.HardwareDriver.Ref AS HardwareDriverLink
		|INTO DriversUsed
		|FROM
		|	Catalog.Peripherals AS Peripherals
		|WHERE
		|	Peripherals.DeviceIsInUse
		|	AND NOT Peripherals.DeletionMark";
	
	If Workplace <> Undefined Then
		Query.Text = Query.Text + "
			|	AND Peripherals.Workplace = &Workplace";
		Query.SetParameter("Workplace", Workplace);
	EndIf;
	
	If HardwareId <> Undefined Then
		Query.Text = Query.Text + "
			|	AND Peripherals.Ref = &HardwareId";
		Query.SetParameter("HardwareId", HardwareId);
	EndIf;
	
	
	Query.Text = Query.Text + "
		|;
		|////////////////////////////////////////////////////////////////////////////////
		|";
	
	Query.Text = Query.Text + 
		"SELECT
		|	HardwareDrivers.Ref AS Ref,
		|	HardwareDrivers.ObjectID AS Id,
		|	HardwareDrivers.Description AS Description,
		|	HardwareDrivers.DriverVersion AS Version,
		|	HardwareDrivers.ConnectionMethod AS ConnectionMethod,
		|	CAST("""" AS STRING(100)) AS TemplateName,
		|	FALSE AS TemplateIsAvailable,
		|	HardwareDrivers.DriverTemplateName AS DriverTemplateName,
		|	HardwareDrivers.PredefinedDataName AS PredefinedDataName,
		|	HardwareDrivers.Predefined AS VBPOEnters
		|FROM
		|	Catalog.HardwareDrivers AS HardwareDrivers
		|WHERE
		|	HardwareDrivers.Ref IN
		|			(SELECT
		|				DriversUsed.HardwareDriverLink AS HardwareDriverLink
		|			FROM
		|				DriversUsed AS DriversUsed)";
	
	If ConnectionMethod <> Undefined Then
		Query.Text = Query.Text + "
			|	AND HardwareDrivers.ConnectionMethod = &ConnectionMethod";
		Query.SetParameter("ConnectionMethod", ConnectionMethod);
	EndIf;
	
	QueryResult = Query.Execute();
	ResultTable = QueryResult.Unload();
	
	For Each String In ResultTable Do
		
		TemplateIsAvailable = False;
		NameOfDriver = String.PredefinedDataName;
		DriverTemplateName = String.DriverTemplateName;        
		If Not IsBlankString(NameOfDriver) Then
			EquipmentManager.FillINTemplateData(NameOfDriver, DriverTemplateName, TemplateIsAvailable, Undefined);       
		EndIf;
		String.TemplateName = ?(TemplateIsAvailable, StrReplace(DriverTemplateName, "CommonTemplate.", ""), "");
		String.TemplateIsAvailable = TemplateIsAvailable;
		
	EndDo;
	
	ColumnIndex = ResultTable.Columns.Find("PredefinedDataName");
	ResultTable.Columns.Delete(ColumnIndex);
	ColumnIndex = ResultTable.Columns.Find("DriverTemplateName");
	ResultTable.Columns.Delete(ColumnIndex);
	
	Return ResultTable;
	
EndFunction

// Returns an array of drivers for all hardware that has been added to the Catalog 
// of connected hardware
// 
// Returns:
//   Array of String - array containing driver IDs
Function IdsOfDriversUsed() Export
	
	SetPrivilegedMode(True);
	
	Result = New Array();
	
	Query = New Query;
	Query.Text = 
		"SELECT DISTINCT
		|	Peripherals.HardwareDriver.Ref AS HardwareDriverLink
		|INTO DriversUsed
		|FROM
		|	Catalog.Peripherals AS Peripherals
		|WHERE
		|	Peripherals.DeviceIsInUse
		|	AND NOT Peripherals.DeletionMark
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT
		|	HardwareDrivers.ObjectID AS Id
		|FROM
		|	Catalog.HardwareDrivers AS HardwareDrivers
		|WHERE
		|	HardwareDrivers.Ref IN
		|			(SELECT
		|				DriversUsed.HardwareDriverLink AS HardwareDriverLink
		|			FROM
		|				DriversUsed AS DriversUsed)
		|	AND HardwareDrivers.Predefined";
	
	Selection = Query.Execute().Select();
	While Selection.Next() Do
		Result.Add(Selection.Id);
	EndDo;
	
	Return Result;
	
EndFunction

#Region LoggingDrivers

// Returns information about the driver logs for the specified connected hardware.
//
// Parameters:
//   Peripherals - CatalogRef.Peripherals - 
//     Link To The Connected Equipment
//
// Returns:
//   See InformationRegisters.HardwareDriverLogArchive.InformationAboutDriverLogs
//
Function InformationAboutDriverLogs(Peripherals) Export
	
	Return InformationRegisters.HardwareDriverLogArchive.InformationAboutDriverLogs(Peripherals);
	
EndFunction

// Returns an archive of driver logs for the specified connected hardware.
//
// Parameters:
//   Peripherals - CatalogRef.Peripherals - 
//     Link To The Connected Equipment
//
// Returns:
//   See InformationRegisterRecordManager.HardwareDriverLogArchive
//
Function ArchiveOfDriverLogs(Peripherals) Export
	
	Return InformationRegisters.HardwareDriverLogArchive.ArchiveOfDriverLogs(Peripherals);
	
EndFunction

// Clears the archive of driver logs for the specified connected hardware.
//
// Parameters:
//   Peripherals - CatalogRef.Peripherals - 
//     link to the Catalog item of the connected equipment
//
Procedure ClearArchiveOfDriverLogs(Peripherals) Export
	
	InformationRegisters.HardwareDriverLogArchive.
		ClearArchiveOfDriverLogs(Peripherals);
	
EndProcedure

// Sends a request for an archive of driver logs to the client for the specified connected hardware.
//
// Parameters:
//   Peripherals - CatalogRef.Peripherals - 
//     Link To The Connected Equipment
//
Procedure SendRequestForDriverLogArchive(Peripherals, UUID = Undefined) Export

	// ++ Non-mobile application
#If Not MobileAppServer Then
	If Not ValueIsFilled(Peripherals) Then
		Raise NStr("vi = 'Khi gửi yêu cầu lưu trữ nhật ký, không chỉ ra thiết bị được kết nối';
					|ru = 'При отправке запроса архива логов, не указано подключаемое оборудование';
					|en = 'The peripherals are not specified when sending a log archive request'; fa = 'The peripherals are not specified when sending a log archive request';
					|it = 'The peripherals are not specified when sending a log archive request';
					|pl = 'The peripherals are not specified when sending a log archive request';
					|tr = 'Günlük arşivi isteği gönderilirken bağlı ekipman belirtilmedi'");
	EndIf;
	
	Attributes = CommonCEL.ObjectAttributesValues(
		Peripherals, 
		"Workplace, HardwareDriver");
	IBUser = InfoBaseUsers.CurrentUser();
	IBUserID = IBUser.UUID;
	
	QueryData = New Structure;
	QueryData.Insert("Peripherals", Peripherals);
	QueryData.Insert("Workplace", Attributes.Workplace);
	QueryData.Insert("HardwareDriver", Attributes.HardwareDriver);
	QueryData.Insert("FormUniqueID", UUID);
	QueryData.Insert("WorkplaceSender", EquipmentManagerServerCall.CustomerWorkplace());
	
	RecipientSessions = New Array();
	RecipientSessions.Add("*");
	Recipients = New Map;
	Recipients.Insert(IBUserID, RecipientSessions);
	QueryData.Insert("Recipients", Recipients);
	
	InformationRegisters.HardwareDriverLogArchive.RecordStartOfRequestForDriverLogArchive(Peripherals);
	
	ServerAlertsModule = CommonCEL.CommonModule("ServerNotifications");
	ServerAlertsModule.SendServerNotification(
			EquipmentManagerClientServer.KeyForRequestingDriverLogArchive(), 
		QueryData,
		Undefined,
		True);
#EndIf
	// -- Non-mobile application
	
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
Procedure SendResponseToDriverLogArchiveEntry(QueryData, ImportResult1) Export

	// ++ Non-mobile application
	ResponseData = New Structure;
	ResponseData.Insert("Success", ImportResult1.Success);
	ResponseData.Insert("ErrorText", ImportResult1.ErrorText);
	ResponseData.Insert("Peripherals", QueryData.Peripherals);
	ResponseData.Insert("FormUniqueID", QueryData.FormUniqueID);
	ResponseData.Insert("WorkplaceSender", QueryData.WorkplaceSender);
	Recipients = QueryData.Recipients;
	
	ServerAlertsModule = CommonCEL.CommonModule("ServerNotifications");
	ServerAlertsModule.SendServerNotification(
			EquipmentManagerClientServer.KeyForRespondingToRequestForDriverLogArchive(), 
			ResponseData,
		Recipients, 
		True);
	// -- Non-mobile application
	
EndProcedure

Function StateOfDriverLogsArchiveRequest(Peripherals) Export
	
	Return InformationRegisters.HardwareDriverLogArchive.QueryStatus(Peripherals);
	
EndFunction

#EndRegion

#EndRegion

#Region Private

// Fill in the device data structure
//
Function FillInDeviceData(Selection, CurrentIBUser, LanguageCode)

	DeviceData = New Structure();   
	EquipmentParameters = Selection.Parameters; // ValueStorage
	
	DeviceData.Insert("Ref"                    , Selection.Ref);
	DeviceData.Insert("TypesOfEquipment"          , EquipmentManager.ParametersTypesOfEquipment(Selection.EquipmentType));     
	DeviceData.Insert("EquipmentType"           , Selection.EquipmentType);   
	DeviceData.Insert("EquipmentTypeName"        , XMLString(Selection.EquipmentType));   
	DeviceData.Insert("Description"              , Selection.Description);  
	DeviceData.Insert("Parameters"                 , EquipmentParameters.Get());
	DeviceData.Insert("HardwareDriver"       , Selection.HardwareDriver);
	DeviceData.Insert("AsPartOfConfiguration"      , Selection.AsPartOfConfiguration);
	DeviceData.Insert("ObjectID"      , Selection.ObjectID);
	DeviceData.Insert("NoLongerSupported"            , Selection.NoLongerSupported);        
	DeviceData.Insert("MessageWhenUsing" , Selection.MessageWhenUsing); 
	DeviceData.Insert("DriverVersion"            , Selection.DriverVersion);
	DeviceData.Insert("NetworkEquipment"       , Selection.AttachmentType = Enums.PeripheralsTypes.SharedAccess);
	DeviceData.Insert("SafeConnection"     , Selection.SafeConnection);                                                
	DeviceData.Insert("XMLParameters"              , EquipmentManager.GetXMLParameters(DeviceData.Parameters, DeviceData.EquipmentTypeName)); 
	DeviceData.Insert("XMLApplicationParameters"    , EquipmentManager.ApplicationParametersForDriver());         
	
	ConnectionMethod = Selection.ConnectionMethod;
	ConnectingFromTemplate = ConnectionMethod = Enums.DriverConnectionMethod.From_Template;
	ConnectingLocallyById = ConnectionMethod = Enums.DriverConnectionMethod.DriverIsInstalledOnLocalComputer;
	
	LocalizationPattern = Undefined;    
	TemplateIsAvailable = False;
	NameOfDriver = Selection.PredefinedDataName;
	DriverTemplateName = Selection.DriverTemplateName;        
	If Not IsBlankString(NameOfDriver) Then
		EquipmentManager.FillINTemplateData(NameOfDriver, DriverTemplateName, TemplateIsAvailable, LocalizationPattern, LanguageCode); 
	EndIf;
	
	DeviceData.Insert("ConnectionMethod"        , ConnectionMethod);      
	DeviceData.Insert("ConnectingFromTemplate"      , ConnectingFromTemplate);
	DeviceData.Insert("ConnectingLocallyById", ConnectingLocallyById);
	DeviceData.Insert("DriverTemplateName"  , DriverTemplateName);
	DeviceData.Insert("TemplateIsAvailable"      , TemplateIsAvailable);
	DeviceData.Insert("LocalizationPattern"  , LocalizationPattern);
	DeviceData.Insert("AutomaticFiscalization" , Selection.AutomaticFiscalization);
	DeviceData.Insert("Use36MonthsFSUTIIIs"           , Selection.Use36MonthsFSUTIIIs);       
	DeviceData.Insert("ReinstallationIsRequired"     , Selection.ReinstallationIsRequired);
	DeviceData.Insert("InstallationIsRequired"         , Selection.InstallationIsRequired);
	DeviceData.Insert("Organization"                , Selection.Organization);

	TypesOfEquipment = EquipmentManager.AvailableTypesOfNonCertifiedEquipment();
	If TypesOfEquipment.Find(Selection.EquipmentType) = Undefined Then
		NonCertified = False;
	Else
		NonCertified = True;
	EndIf;
	DeviceData.Insert("NonCertified"  , NonCertified);
	
	// Access restriction
	AccessRestriction = New Array();
	ResultOfAccessRestrictionRequest = Selection.AccessRestriction; // QueryResult
	SelectionRestrictionOfAccess = ResultOfAccessRestrictionRequest.Select(); 
	While SelectionRestrictionOfAccess.Next() Do
		AccessRestriction.Add(String(SelectionRestrictionOfAccess.User));
	EndDo;
	DeviceData.Insert("AccessRestriction", AccessRestriction);
	If AccessRestriction.Count() > 0 Then
		AvailableToCurrentUser = AccessRestriction.Find(CurrentIBUser) <> Undefined;
	Else
		AvailableToCurrentUser = True;
	EndIf;
	DeviceData.Insert("AvailableToCurrentUser", AvailableToCurrentUser);
	
	// Parameters for registering a KKT
	If Selection.EquipmentType = Enums.PeripheralTypes.CREWithDataTransfer 
		And CommonCEL.CheckPrintingDevicesAreUsed() Then
			ModuleEquipmentReceiptPrintingDevices = CommonCEL.CommonModule("PeripheralsReceiptPrinters");
			RegistrationParameters = ModuleEquipmentReceiptPrintingDevices.DeviceRegistrationParameters(Selection.Ref);
	Else
		RegistrationParameters = New Structure();
	EndIf;
	DeviceData.Insert("RegistrationParameters", RegistrationParameters);
	
	Return DeviceData;
	
EndFunction

#EndRegion

#EndIf