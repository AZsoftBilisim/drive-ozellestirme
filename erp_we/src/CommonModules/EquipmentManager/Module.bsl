#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region Public

#Region System

// Returns the version number of the library of the connected hardware.
//
// Returns:
//  String
//
Function LibraryVersion() Export
	
	VersionOfBPOLibrary = "3.2.9.19";
	Return VersionOfBPOLibrary;
	
EndFunction

// Returns a list of available hardware types.
//
// Parameters:
//  IncludingUnusedOnes - Boolean - the default is False, unused ones should not be output for the user to select
// 
// Returns:
//   Array of EnumRef.PeripheralTypes - Array of available types of connected equipment in the configuration.
//
Function AvailableTypesOfEquipment(IncludingUnusedOnes = False) Export
	
	Return EquipmentManagerCached.AvailableTypesOfEquipment(IncludingUnusedOnes);
	
EndFunction

// Returns the availability of adding new drivers.
// 
// Returns:
//  Boolean
//
Function AvailableAddingNewDrivers() Export
	
#If MobileAppServer Then  
	Result = False; 
#Else
	Result = True;
	AddingNewDriversIsAvailable = Result; 
	StandardProcessing = True;
	EquipmentManagerServerCallOverridable.AvailableAddingNewDrivers(AddingNewDriversIsAvailable, StandardProcessing);
	Result = ?(StandardProcessing, Result, AddingNewDriversIsAvailable);
#EndIf
	Return Result; 
	
EndFunction

// Returns the availability of network equipment.
//
// Returns:
//  Boolean
//
Function AvailableNetworkEquipment() Export
	
#If MobileAppServer Then    
	Result = False;
#Else
	Result = True;  
	NetworkEquipmentIsAvailable = Result; 
	StandardProcessing = True;
	EquipmentManagerServerCallOverridable.AvailableNetworkEquipment(NetworkEquipmentIsAvailable, StandardProcessing);
	Result = ?(StandardProcessing, Result, NetworkEquipmentIsAvailable);
#EndIf
	Return Result; 
	
EndFunction

// Returns the availability of collection in the fiscal device management form.
// 
// Returns:
//  Boolean
//
Function CollectionInManagementOfFiscalDeviceIsAvailable() Export
	
	Result = False;
	CollectionIsAvailable = Result; 
	StandardProcessing = True;
	EquipmentManagerServerCallOverridable.CollectionInManagementOfFiscalDeviceIsAvailable(CollectionIsAvailable, StandardProcessing);
	Result = ?(StandardProcessing, Result, CollectionIsAvailable);
	Return Result; 
	
EndFunction

// The ISMP is being recorded in the configuration
// 
// Returns:
//  Boolean - The ISMP is being recorded in the configuration
//
Function ISMPProductsAreRecorded() Export
	
	StandardProcessing = True;
	AccountingOfISMPProducts = False;
	EquipmentManagerServerCallOverridable.ISMPProductsAreRecorded(AccountingOfISMPProducts, StandardProcessing);
	Result = ?(Not StandardProcessing, AccountingOfISMPProducts, False); 
	Return Result;
	
EndFunction

// Retrieves the list of available types of public hardware.
// 
// Returns:
//   Array of EnumRef.PeripheralTypes - Array of available types of connected equipment in the configuration.
//
Function AvailableTypesOfPublicEquipment() Export
	
	ListOfEquipmentTypes = New Array;
	StandardProcessing = True;
	
	EquipmentManagerServerCallOverridable.AvailableTypesOfNetworkEquipment(ListOfEquipmentTypes, StandardProcessing);
	
	If StandardProcessing Then
		ListOfEquipmentTypes.Clear();
		If CommonCEL.CheckPrintingDevicesAreUsed() Then
			ListOfEquipmentTypes.Add(Enums.PeripheralTypes.CREWithDataTransfer);
		EndIf;
		If CommonCEL.CloudCCTSAreUsed() Then
			ListOfEquipmentTypes.Add(Enums.PeripheralTypes.CloudCashRegister);
		EndIf;
	EndIf;
	 
	Return ListOfEquipmentTypes;
	
EndFunction

// Returns True if the driver is supplied in the configuration
//
// Parameters:
//  DeviceID - CatalogRef.Peripherals
//
// Returns:
//  Boolean
//
Function DriverIsSuppliedInConfiguration(DeviceID) Export
	
	Result = True;
	
	If ValueIsFilled(DeviceID) Then
		Attributes = CommonCEL.ObjectAttributesValues(
			DeviceID, 
			"HardwareDriver.Predefined, HardwareDriver.NoLongerSupported");
			
		If ValueIsFilled(Attributes.HardwareDriverPredefined) 
			And ValueIsFilled(Attributes.HardwareDriverRemovedFromSupport) Then
			Result = Attributes.HardwareDriverPredefined And Not Attributes.HardwareDriverRemovedFromSupport;
		Else
			Result = False;
		EndIf;
		
	EndIf;
	
	Return Result;
	
EndFunction

#EndRegion

#Region UpdatingDrivers

// To update the supplied driver to the PCM.
//
Procedure UpdateSuppliedDrivers() Export
	
	UpgradeModules = New Array();
	If CommonCEL.InputDevicesAreUsed() Then
		UpgradeModules.Add(CommonCEL.CommonModule("PeripheralsInputDevices"));       
	EndIf;
	If CommonCEL.CheckPrintingDevicesAreUsed() Then
		UpgradeModules.Add(CommonCEL.CommonModule("PeripheralsReceiptPrinters"));       
	EndIf;
	If CommonCEL.UsedPaymentSystems() Then
		UpgradeModules.Add(CommonCEL.CommonModule("PeripheralsPaymentSystemsServer"));       
	EndIf;          
	If CommonCEL.UsedBuyerSDisplays() Then
		UpgradeModules.Add(CommonCEL.CommonModule("PeripheralsCustomerDisplaysServer"));       
	EndIf;
	If CommonCEL.WeightEquipmentIsUsed() Then
		UpgradeModules.Add(CommonCEL.CommonModule("PeripheralsWeighingEquipmentServer"));       
	EndIf;                          
// ++ Non-mobile application
	If CommonCEL.DataCollectionTerminalsAreUsed() Then
		UpgradeModules.Add(CommonCEL.CommonModule("PeripheralsPortableDataTerminalsServer"));       
	EndIf;
	If CommonCEL.LabelPrintersAreUsed() Then
		UpgradeModules.Add(CommonCEL.CommonModule("PeripheralsLabelPrintersServer"));       
	EndIf;
	If CommonCEL.RFIDReaderIsUsed() Then
		UpgradeModules.Add(CommonCEL.CommonModule("PeripheralsRFIDReader"));       
	EndIf;
	If CommonCEL.RecognitionDeviceIsUsed() Then
		UpgradeModules.Add(CommonCEL.CommonModule("EquipmentRecognitionDevice"));       
	EndIf;
	If CommonCEL.CloudCCTSAreUsed() Then
		UpgradeModules.Add(CommonCEL.CommonModule("EquipmentCloudCRE"));       
	EndIf;
	
	If CommonCEL.NonCertifiedEquipmentIsUsed() Then
		ModuleNonCertifiedEquipment = CommonCEL.CommonModule("UncertifiedPeripherals");
		ModuleNonCertifiedEquipment.RegisterDrivers();
	EndIf;
	
	
// -- Non-mobile application
	DriversOfHardware = NewTableOfSuppliedHardwareDrivers();
	For Each UpdateModule In UpgradeModules Do
		UpdateModule.UpdateSuppliedDrivers(DriversOfHardware);
	EndDo;
	
	Catalogs.HardwareDrivers.OnInitialItemsFilling(DriversOfHardware);
	
	RemoveOutdatedDrivers();
	
EndProcedure

// Update the installed drivers.
//
Procedure UpdateInstalledDrivers() Export
	
	TypesOfDrivers = TypesOfDriversThatMustBeUpdated();
	SetUpdateFlagByType(TypesOfDrivers);
	
EndProcedure

// Records changes to the passed object.
// For use in update handlers.
//
// Parameters:
//   Data                            - Arbitrary - the object, recordset, or constant Manager
//                                                      to record.
//   RegisterOnExchangePlanNodes - Boolean       - enables registration of exchange plans on nodes when writing an object.
//   EnableBusinessLogic              - Boolean       - enables business logic when writing an object.
//
Procedure WriteData(Val Data, Val RegisterOnExchangePlanNodes = False, Val EnableBusinessLogic = False) Export
	
	Data.DataExchange.Load = Not EnableBusinessLogic;
	If Not RegisterOnExchangePlanNodes Then
		Data.AdditionalProperties.Insert("DisableObjectChangeRecordMechanism");
		Data.DataExchange.Recipients.AutoFill = False;
	EndIf;
	
	Try
		Data.Lock();
		Data.Write();
	Except
		CommonCEL.WriteErrorToEventLog(
			NStr("vi = 'Cập nhật thiết bị kết nối';
				|ru = 'Обновление подключаемого оборудования';
				|en = 'Update peripherals'; fa = 'Update peripherals';
				|it = 'Обновление подключаемого оборудования';
				|pl = 'Update peripherals';
				|tr = 'Çevre birimlerini güncelle'"), 
			ErrorProcessing.DetailErrorDescription(ErrorInfo()));
	EndTry;
	
EndProcedure

// Sets whether you need to reinstall hardware for connected equipment in the workplace.
//
// Parameters:
//  Workplace - CatalogRef.Workplaces
//  HardwareDriver - CatalogRef.HardwareDrivers 
//  Flag - Boolean - you need to reinstall the driver
//
Procedure SetFlagForReinstallingDriver(Workplace, HardwareDriver, Flag) Export
	
	SetPrivilegedMode(True);
	
	Query = New Query(
	"SELECT  
	|	Peripherals.Ref
	|FROM
	|	Catalog.Peripherals AS Peripherals
	|WHERE
	|	Peripherals.Workplace = &Workplace
	|	AND Peripherals.HardwareDriver = &HardwareDriver
	|	AND NOT Peripherals.ReinstallationIsRequired = &ReinstallationIsRequired"); 
	
	Query.SetParameter("Workplace", Workplace);
	Query.SetParameter("HardwareDriver", HardwareDriver);
	Query.SetParameter("ReinstallationIsRequired", Flag);
	
	Selection = Query.Execute().Select();
	While Selection.Next() Do
		CatalogObject = Selection.Ref.GetObject();
		CatalogObject.ReinstallationIsRequired = Flag;
		WriteData(CatalogObject)
	EndDo;
	
EndProcedure

// Update the installed drivers from the connected hardware reference.
//
// Parameters:
//  EquipmentType - EnumRef.PeripheralTypes
Procedure UpdateInstalledDriversByType(EquipmentType) Export
	
	SetPrivilegedMode(True);
	
	Query = New Query("SELECT
							|	Peripherals.Ref
							|FROM
							|	Catalog.Peripherals AS Peripherals
							|WHERE
							|	(Peripherals.EquipmentType = &EquipmentType)");
							
	Query.SetParameter("EquipmentType", EquipmentType);
	
	Selection = Query.Execute().Select();
	While Selection.Next() Do
		CatalogObject = Selection.Ref.GetObject();
		CatalogObject.ReinstallationIsRequired = True;
		WriteData(CatalogObject)
	EndDo;
	
EndProcedure

// Returns a table of drivers supplied in the library
//
// Returns:
//  See NewTableOfSuppliedHardwareDrivers
Function SuppliedDrivers() Export
	
	Return EquipmentManagerCached.SuppliedDrivers();
	
EndFunction

// Returns information about hardware drivers from the "Informationdrivers" Template.
//
// Returns:
//   Map of Structure - information about hardware drivers obtained from the Template.
//
Function DriversInformation() Export
	
	Template = Catalogs.HardwareDrivers.GetTemplate("DriversInformation");
	
	JSONReader = New JSONReader;
	JSONReader.SetString(Template.GetText());
	PropertiesWithDateValuesNames = New Array;
	PropertiesWithDateValuesNames.Add("VersionDate");
	PropertiesWithDateValuesNames.Add("FileDate");
	ReadToMap = True;
	InformationAboutComponents = ReadJSON(JSONReader, ReadToMap, PropertiesWithDateValuesNames);
	JSONReader.Close();
	
	Result = New Map;
	For Each AddInInformation In InformationAboutComponents Do
		StructureOfComponentInformation = New Structure;
		StructureOfComponentInformation.Insert("Id", AddInInformation.Value["Id"]);
		StructureOfComponentInformation.Insert("Description", AddInInformation.Value["Description"]);
		StructureOfComponentInformation.Insert("Version", AddInInformation.Value["Version"]);
		StructureOfComponentInformation.Insert("VersionDate", AddInInformation.Value["VersionDate"]);
		Result.Insert(AddInInformation.Key, StructureOfComponentInformation);
	EndDo;
	
	Return Result;
	
	
EndFunction

// ++ Non-mobile application      
// Returns elements of drivers that are recommended to be updated
// Parameters:
//   HardwareId - CatalogRef.Peripherals, Undefined - 
//   Workplace - CatalogRef.Workplaces, Undefined - 
// Returns:
//  Structure:
//    * Ref - CatalogRef.HardwareDrivers
//    * Description - String
//    * Id - String
//    * Version - String
//    * ConnectionMethod - EnumRef.DriverConnectionMethod
//    * TemplateName - String - name of the Template where the driver is located
//    * TemplateIsAvailable - Boolean - if False, then there is no driver Template in the library
//    * ItIsInVKCatalog - Boolean - will the driver hold up in the Catalog of External components of the BSP
//    * VersionInVKCatalog - String - driver version in the Catalog of External BSP components
//    * DateInECCatalog - Date - driver date in the Catalog of External BSP components
//    * VBPOEnters - Boolean - flag that the driver is included in the connected hardware library
//    * LatestVersion - String - current driver version
//    * RelevantDate - Date - date of the current driver
//
Function CheckForUpdates(HardwareId = Undefined, Workplace = Undefined) Export
	
	UsedDrivers = UsedDriversOfConnectedEquipment(, HardwareId, Workplace);

	DriversInformation = DriversInformation();
	UpdateRequired = New Array;
	
	For Each Driver In UsedDrivers Do
		
		Information = DriversInformation[Driver.Id];
		If Information = Undefined Then
			Continue;
		EndIf;
		
		If Driver.ItIsInVKCatalog
			And Driver.DateInECCatalog < Information.VersionDate Then
			
			Result = CommonCEL.ValueTableRowToStructure(Driver);
			Result.Insert("LatestVersion", Information.Version);
			Result.Insert("RelevantDate", Information.VersionDate);
			UpdateRequired.Add(Result);
		EndIf;
		
	EndDo;
	
	Return UpdateRequired;
	
EndFunction
// -- Non-mobile application

#EndRegion

// ++ Non-mobile application
#Region ForTransitionalPeriodOfCuttingOffDrivers

// Returns a table of drivers for all hardware that has been added to the Catalog 
//   of connected hardware
// Parameters:
//   ConnectionMethod - EnumRef.DriverConnectionMethod - if the value is not passed, 
//                       it will be selected regardless of the connection method
//   HardwareId - CatalogRef.Peripherals, Undefined - 
//   Workplace - CatalogRef.Workplaces, Undefined - 
// Returns:
//  ValueTable:
//    * Ref - CatalogRef.HardwareDrivers
//    * Description - String
//    * Id - String
//    * Version - String
//    * ConnectionMethod - EnumRef.DriverConnectionMethod
//    * TemplateName - String - name of the Template where the driver is located
//    * TemplateIsAvailable - Boolean - if False, then there is no driver Template in the library
//    * ItIsInVKCatalog - Boolean - will the driver hold up in the Catalog of External components of the BSP
//    * VersionInVKCatalog - String - driver version in the Catalog of External BSP components
//    * DateInECCatalog - Date - driver date in the Catalog of External BSP components
//    * VBPOEnters - Boolean - flag that the driver is included in the connected hardware library
Function UsedDriversOfConnectedEquipment(
		ConnectionMethod = Undefined, 
		HardwareId = Undefined, 
		Workplace = Undefined) Export
	
	UsedDrivers = Catalogs.Peripherals.UsedDrivers(
		ConnectionMethod, HardwareId, Workplace);
	UsedDrivers.Columns.Add("ItIsInVKCatalog", New TypeDescription("Boolean"));
	UsedDrivers.Columns.Add("VersionInVKCatalog", New TypeDescription("String"));
	UsedDrivers.Columns.Add("DateInECCatalog", New TypeDescription("Date"));

	If Not CommonCEL.SubsystemExists("StandardSubsystems.AddIns") Then
		Return UsedDrivers;
	EndIf;
	
	ExternalComponentsServerModule = CommonCEL.CommonModule("AddInsServer");
	UploadedExternalComponents = ExternalComponentsServerModule.ComponentsToUse("ForUpdate");
	
	For Each Driver In UsedDrivers Do
		
		FoundRow = UploadedExternalComponents.Find(Driver.Id, "Id");
		If FoundRow = Undefined Then
			Driver.ItIsInVKCatalog = False;
			Driver.VersionInVKCatalog = "";
		Else
			Driver.ItIsInVKCatalog = True;
			Driver.VersionInVKCatalog = FoundRow.Version;
			Driver.DateInECCatalog = FoundRow.VersionDate;
		EndIf;
		
	EndDo;
	
	Return UsedDrivers;
	
EndFunction

// Add external components drivers from the Template to the Catalog
// Parameters:
//  IDs - Array of String
//  
// Returns:
//  See AddExternalComponentFromTemplateToCatalogInternal
// 
Function AddExternalComponentFromTemplateToCatalog(IDs) Export
	
	SetPrivilegedMode(True);
	
	DriversToAdd = New Array();
	Query = New Query;
	Query.Text = 
		"SELECT
		|	HardwareDrivers.ObjectID AS Id,
		|	HardwareDrivers.Ref AS Ref,
		|	HardwareDrivers.DriverVersion AS Version,
		|	HardwareDrivers.Description AS Description,
		|	HardwareDrivers.PredefinedDataName AS PredefinedDataName,
		|	HardwareDrivers.DriverTemplateName AS DriverTemplateName
		|FROM
		|	Catalog.HardwareDrivers AS HardwareDrivers
		|WHERE
		|	CAST(HardwareDrivers.ObjectID AS STRING(100)) IN (&IDs)";
	
	Query.SetParameter("IDs", IDs);
	QueryResult = Query.Execute();
	Selection = QueryResult.Select();
	While Selection.Next() Do
		
		TemplateIsAvailable = False;
		NameOfDriver = Selection.PredefinedDataName;
		DriverTemplateName = Selection.DriverTemplateName;
		FillINTemplateData(NameOfDriver, DriverTemplateName, TemplateIsAvailable, Undefined);
		If TemplateIsAvailable Then
			DataToAdd = NewDataToAddExternalComponentsToCatalog();
			FillPropertyValues(DataToAdd, Selection);
			DataToAdd.TemplateName = StrReplace(DriverTemplateName, "CommonTemplate.", "");
			DriversToAdd.Add(DataToAdd);
		EndIf;
		
	EndDo;
	
	Return AddExternalComponentFromTemplateToCatalogInternal(DriversToAdd);
	
EndFunction

// Download external components drivers from ITS website to the Catalog
// 
// Parameters:
//  IDs - Array of String
//  
// Returns:
//  See DownloadDriversFromITSWebsiteInternal
//
Function DownloadDriversFromITSWebsite(IDs) Export
	
	SetPrivilegedMode(True);
	
	Query = New Query;
	Query.Text = 
		"SELECT
		|	HardwareDrivers.ObjectID AS Id,
		|	HardwareDrivers.Ref AS Ref
		|FROM
		|	Catalog.HardwareDrivers AS HardwareDrivers
		|WHERE
		|	CAST(HardwareDrivers.ObjectID AS STRING(100)) IN (&IDs)";
	
	Query.SetParameter("IDs", IDs);
	QueryResult = Query.Execute();
	Selection = QueryResult.Select();
	While Selection.Next() Do
		
		DataForImport = NewDataForDownloadingDriverFromITSWebsite();
		FillPropertyValues(DataForImport, Selection);
		DataForImport.Add(DataForImport);
		
	EndDo;
	
	Return DownloadDriversFromITSWebsiteInternal(DataForImport);
	
EndFunction

#EndRegion
// -- Non-mobile application

#Region EquipmentOperation

// retrieves the list of software enabled in the Catalog by the set selection
//
// Parameters:
//  Filter - See EquipmentManagerClientServer.ListOfEquipmentSelection.
//
// Returns:
//  Array of Structure
//
Function EquipmentList(Filter) Export
	
	Return Catalogs.Peripherals.EquipmentList(Filter);
	
EndFunction

// The function returns a structure with device data.
//
// Parameters:
//  Id - CatalogRef.Peripherals    
//  LanguageCode - Undefined, String - 
//
// Returns:
//  See Catalogs.Peripherals.DeviceData
//
Function DeviceData(Id, LanguageCode = Undefined) Export
	
	Return Catalogs.Peripherals.DeviceData(Id, LanguageCode);
	
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
	
	Return Catalogs.Peripherals.DeviceParameters(Id);
	
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
	
	Return Catalogs.Peripherals.SaveDeviceSettings(Id, Parameters);
	
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
	
	Return Catalogs.HardwareDrivers.HardwareDriverData(DriverID);
	
EndFunction

// The function returns drivers by hardware type
//
// Parameters:
//  EquipmentType - EnumRef.PeripheralTypes - Types of connected equipment.
//  OnlyAvailable - Boolean - indicates only available drivers.
//  RemovedFromDriverSupport - Boolean - indicates whether drivers removed from support are displayed.      
//  RecommendedUse - Boolean - indicates whether the recommended drivers are displayed.
//
// Returns:
//  ValueList
//
Function Drivers_ByHardwareType(EquipmentType, OnlyAvailable = True, RemovedFromDriverSupport = False, RecommendedUse = False) Export
	
	Return Catalogs.HardwareDrivers.Drivers_ByHardwareType(EquipmentType, OnlyAvailable, RemovedFromDriverSupport, RecommendedUse);
	
EndFunction

// The function creates an entry in the directory about the new driver.
//
// Parameters:
//  CreationParameters - See EquipmentManagerClientServer.ParametersForCreatingNewDriver
//
// Returns:
//  CatalogRef.HardwareDrivers
//
Function CreateHardwareDriver(CreationParameters) Export
	
	Return Catalogs.HardwareDrivers.CreateNewItem(CreationParameters);
	
EndFunction

// The function creates an entry in the directory about the new driver.
//
// Parameters:
//  CreationParameters - See EquipmentManagerClientServer.ParametersForCreatingNewAttachableHardware
//
// Returns:
//  CatalogRef.Peripherals
//
Function CreatePeripherals(CreationParameters) Export
	
	Return Catalogs.Peripherals.CreateNewItem(CreationParameters);
	
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
Function GetXMLParameters(Parameters, EquipmentType = Undefined, RecordParameters = True) Export
	
	Result = ""; 
	
	If Parameters <> Undefined Then 
		
		XMLWriter = New XMLWriter; 
		XMLWriter.SetString("UTF-8");
		XMLWriter.WriteXMLDeclaration();
		XMLWriter.WriteStartElement("Parameters");    
		
		If Not IsBlankString(EquipmentType) Then
			XMLWriter.WriteStartElement("Parameter");   
			XMLWriter.WriteAttribute("Name", "EquipmentType");      
			XMLWriter.WriteAttribute("Value", XMLString(EquipmentType));
			XMLWriter.WriteEndElement();
		EndIf;
		
		If RecordParameters Then
			For Each Parameter In Parameters Do
				If Left(Parameter.Key, 2) = "P_" Then
					XMLWriter.WriteStartElement("Parameter");   
					XMLWriter.WriteAttribute("Name", Mid(Parameter.Key, 3));      
					XMLWriter.WriteAttribute("Value", XMLString(Parameter.Value));
					XMLWriter.WriteEndElement();
				EndIf;
			EndDo;
		Else
			For Each Parameter In Parameters Do
				XMLWriter.WriteStartElement("Parameter");   
				XMLWriter.WriteAttribute("Name", XMLString(Parameter.Key));      
				XMLWriter.WriteAttribute("Value", XMLString(Parameter.Value));
				XMLWriter.WriteEndElement();
			EndDo;
		EndIf;
			
		XMLWriter.WriteEndElement();
		Result = XMLWriter.Close();   
		
	EndIf;
	
	Return Result;
	
EndFunction                        

// Get connection parameters from XML
//
// Parameters:
//   XMLParameters - String - Connection parameters in XML.     
// Returns:
//   Structure -
//
Function LoadXMLParameters(XMLParameters) Export
	
	Parameters = New Structure();
	
	If Not IsBlankString(XMLParameters) Then
		
		XMLReader = New XMLReader; 
		XMLReader.SetString(XMLParameters);
		XMLReader.MoveToContent();
		
		If XMLReader.Name = "Parameters" And XMLReader.NodeType = XMLNodeType.StartElement Then  
			While XMLReader.Read() Do  
				If XMLReader.Name = "Parameter" And XMLReader.NodeType = XMLNodeType.StartElement Then     
					NameParameter = XMLReader.AttributeValue("Name");
					ParameterValue1 = XMLReader.AttributeValue("Value");   
					If NameParameter <> "EquipmentType" Then  
						NameParameter = "P_" + NameParameter;
						Parameters.Insert(NameParameter, ParameterValue1);
					EndIf;
				EndIf;
			EndDo;
		EndIf;
		
	EndIf;
	
	Return Parameters;
	
EndFunction                        

// Application parameters for the driver.
// 
// Returns:
//  String       
//
Function ApplicationParametersForDriver() Export
	
	AppName = "1C:Connected Equipment Library, ver 3.2";
	Application_Version = LibraryVersion(); 
	
	XMLWriter = New XMLWriter; 
	XMLWriter.SetString("UTF-8");
	XMLWriter.WriteXMLDeclaration();
	XMLWriter.WriteStartElement("ApplicationSettings");    
	XMLWriter.WriteAttribute("ApplicationName", XMLString(AppName));      
	XMLWriter.WriteAttribute("ApplicationVersion", XMLString(Application_Version));
	XMLWriter.WriteEndElement();
	Result = XMLWriter.Close();   
	
	Return Result;
	
EndFunction 

#EndRegion


#Region PaymentTransactions

// Checks whether there have been any cancellations according to the foundation document.
//
// Parameters:
//  DocumentBasis1 - DefinedType.BaseDocumentForFiscalPLTransaction - document Foundation.
//  
// Returns:
//  Boolean
//
Function CancellationOfPaymentByCheckIsPossible(DocumentBasis1) Export   
	
	If CommonCEL.UsedPaymentSystems() Then    
		ModuleEquipmentPaymentSystems = CommonCEL.CommonModule("PeripheralsPaymentSystemsServer");
		Return ModuleEquipmentPaymentSystems.CancellationOfPaymentByCheckIsPossible(DocumentBasis1);
	EndIf;
	
EndFunction

#EndRegion

#Region ConnectingEquipment

// Add a list of connected equipment to the form
// Parameters:
//  Form - ClientApplicationForm
//  TypesOfEquipment - See EquipmentManagerClientServer.ParametersTypesOfEquipment
Procedure OnCreateAtServer(Form, TypesOfEquipment) Export
	
	Peripherals = AttachableEquipmentOnForm(Form);
	If IsPeripherals() Then
		Peripherals.SoftwareTypes = TypesOfEquipment;
		Filter = EquipmentManagerClientServer.ListOfEquipmentSelection();
		Filter.SoftwareTypes = TypesOfEquipment;
		WorkplaceOfClientOnServer = EquipmentManagerServerCall.CustomerWorkplace();
		If ValueIsFilled(WorkplaceOfClientOnServer) Then
			Peripherals.EquipmentList = EquipmentList(Filter);
		Else
			Peripherals.RequestForListOfEquipmentOnClientIsRequired = True;
		EndIf;
	EndIf;
	
EndProcedure

// Checks whether the connected equipment exists in the database, and returns 
// True if at least one item is missing from the Connected Equipment Catalog.
//
// Returns:
//  Boolean
Function IsPeripherals() Export
	
	If CommonCEL.DataSeparationEnabled() 
		And Not CommonCEL.SeparatedDataUsageAvailable() Then
		Return False;
	EndIf;
	
	SetPrivilegedMode(True);
	Query = New Query;
	Query.Text = 
		"SELECT ALLOWED TOP 1
		|	Peripherals.Ref AS Ref
		|FROM
		|	Catalog.Peripherals AS Peripherals";
	
	Result = Query.Execute();
	Return Not Result.IsEmpty();
	
EndFunction

// Checks whether the connected equipment exists in the database at the workplace, and returns 
// True if at least one item is present in the Catalog of Connected equipment.
//
// Parameters:
//  Workplace - CatalogRef.Workplaces
//  
// Returns:
//  Boolean
Function ThereIsPlugInEquipmentAtWorkplace(Workplace) Export
	
	If CommonCEL.DataSeparationEnabled() 
		And Not CommonCEL.SeparatedDataUsageAvailable() Then
		Return False;
	EndIf;
	
	If Not ValueIsFilled(Workplace) Then
		Return False;
	EndIf;
	
	SetPrivilegedMode(True);
	Query = New Query;
	Query.Text = 
		"SELECT ALLOWED TOP 1
		|	Peripherals.Ref AS Ref
		|FROM
		|	Catalog.Peripherals AS Peripherals
		|WHERE
		|	Peripherals.Workplace = &Workplace";
	
	Query.SetParameter("Workplace", Workplace);
	
	Result = Query.Execute();
	Return Not Result.IsEmpty();
	
EndFunction

#EndRegion



#Region ObsoleteProceduresAndFunctions

#Region Integration

// Deprecated: you should use the integration system.When defining the settings of the regulatory tasks.
// It is called from the routine taskdetermined procedure.When
// defining the settings of the scheduled tasks to set the availability of the scheduled task, determines the dependence on the functional options.
// 
// Parameters:
//  Settings - ValueTable
//  FunctionalOption - MetadataObjectFunctionalOption
Procedure OnDefineScheduledJobSettings(Settings, FunctionalOption) Export
	
	PELSubsystemsIntegration.OnDefineScheduledJobSettings(Settings, FunctionalOption);
	
EndProcedure

// Deprecated: you should use the integration system.Receipt ofpiscal patterns.
// See JobsQueueOverridable.OnGetTemplateList
Procedure OnGetTemplateList(JobTemplates) Export
	
	PELSubsystemsIntegration.OnGetTemplateList(JobTemplates);
	
EndProcedure

// Deprecated: you should use the integration system.When defining all the names of processors.
// See JobsQueueOverridable.OnDefineHandlerAliases
Procedure OnDefineHandlerAliases(NamesAndAliasesMap) Export
	
	PELSubsystemsIntegration.OnDefineHandlerAliases(NamesAndAliasesMap);
	
EndProcedure

#EndRegion

// The function returns drivers by hardware type
//
// Parameters:
//  EquipmentType - EnumRef.PeripheralTypes - Types of connected equipment.
//  OnlyAvailable - Boolean - indicates only available drivers.
//  RemovedFromDriverSupport - Boolean - indicates whether drivers removed from support are displayed.      
//  RecommendedUse - Boolean - indicates whether the recommended drivers are displayed.
//
// Returns:
//  ValueList
//
Function DriversByHardwareType(EquipmentType, OnlyAvailable = True, RemovedFromDriverSupport = False, RecommendedUse = False) Export
	
	Return Drivers_ByHardwareType(EquipmentType, OnlyAvailable, RemovedFromDriverSupport, RecommendedUse);
	
EndFunction

#EndRegion

#EndRegion

#Region Internal

#Region TypesOfEquipment

// Structure of equipment type  
//
// Parameters:
//   EquipmentType - EnumRef.PeripheralTypes - 
// Returns:
//   Structure
//
Function ParametersTypesOfEquipment(EquipmentType = Undefined) Export
	
	TypesOfEquipment = EquipmentManagerCached.ParametersTypesOfEquipment();
	TypesOfEquipment = CommonCEL.CopyRecursive(TypesOfEquipment); // Structure
	
	If ValueIsFilled(EquipmentType) Then
		EnumerationValueName = CommonCEL.EnumerationValueName(EquipmentType);
		If TypesOfEquipment.Property(EnumerationValueName) Then
			TypesOfEquipment[EnumerationValueName] = True;
		EndIf;
	EndIf;
	
	Return TypesOfEquipment;
	
EndFunction

// Forming an array of equipment types
// 
// Parameters:
//   TypesOfEquipment - Structure, Array, String - type of equipment.
// Returns:
//   Array of DefinedType.PeripheralTypes
//           
Function ArrayOfEquipmentTypes(TypesOfEquipment) Export
	
	TypesArray = New Array();
	If TypeOf(TypesOfEquipment) = Type("String") Then    
		
		TypesInArray = StrSplit(TypesOfEquipment, ",", False);
		For Each EquipmentType In TypesInArray Do
			TypesArray.Add(EquipmentTypeByLine(EquipmentType));
		EndDo;
		
	ElsIf TypeOf(TypesOfEquipment) = Type("Array") Then
		
		AvailableTypesOfEquipment = AvailableTypesOfEquipment(True);
		For Each EquipmentType In TypesOfEquipment Do   
			
			If TypeOf(EquipmentType) = Type("String") Then 
				TypesArray.Add(EquipmentTypeByLine(EquipmentType));
			ElsIf AvailableTypesOfEquipment.Find(EquipmentType) <> Undefined Then 
				TypesArray.Add(EquipmentType);
			EndIf;
			
		EndDo;
		
	ElsIf TypeOf(TypesOfEquipment) = Type("Structure") Then
		
		MapTypes = CompatibilityOfEquipmentTypes();
		For Each Type In TypesOfEquipment Do
			
			If Type.Value Then
				TypesArray.Add(MapTypes[Type.Key]);
			EndIf;
			
		EndDo;
		
	EndIf;
	
	Return TypesArray; 
	
EndFunction

// Get Matching Equipment Types
//
// Returns:
//   Map -
//
Function CompatibilityOfEquipmentTypes() Export
	
	Return EquipmentManagerCached.CompatibilityOfEquipmentTypes();
	
EndFunction

// Get the type of equipment by line
//
// Parameters:
//   EquipmentType - String - type of equipment.
// Returns:
//   EnumRef.PeripheralTypes -
//
Function EquipmentTypeByLine(EquipmentType) Export
	
	Result = CompatibilityOfEquipmentTypes();
	Return Result.Get(EquipmentType);
	
EndFunction

// Returns an array of other types of equipment that are not included in the BPO
//
// Returns:
//  Array of EnumRef.PeripheralTypes
//
Function AvailableTypesOfNonCertifiedEquipment() Export
	
	TypesOfEquipment = New Array();
	TypesOfEquipment.Add(Enums.PeripheralTypes.Uncertified);

	// ++ Non-mobile application
	TypeDescription = Metadata.DefinedTypes.PeripheralTypes.Type;
	For Each Type In TypeDescription.Types() Do
		
		MetadataEnumeration = Metadata.FindByType(Type);
		If MetadataEnumeration =  Metadata.Enums.PeripheralTypes Then
			Continue;
		EndIf;
		
		Name = MetadataEnumeration.Name;
		For Each MetadataValue In MetadataEnumeration.EnumValues Do
			Value = PredefinedValue("Enum."+MetadataEnumeration.Name+"."+MetadataValue.Name);
			TypesOfEquipment.Add(Value);
		EndDo;
		
	EndDo;
	// -- Non-mobile application
	
	Return TypesOfEquipment;
	
EndFunction

#EndRegion

// fills in data about Templates
//
// Parameters:
//   NameOfDriver - String- 
//   DriverTemplateName - String- 
//   TemplateIsAvailable - Boolean- 
//   LocalizationPattern - String- 
//   LanguageCode - String- 
//
Procedure FillINTemplateData(NameOfDriver, DriverTemplateName, TemplateIsAvailable, LocalizationPattern, LanguageCode = "") Export
	
	DriverTemplateName = ?(IsBlankString(DriverTemplateName), NameOfDriver, DriverTemplateName);    
	NameOfDriverTemplatePatch = DriverTemplateName + "_fix";
	DriverTemplate = Metadata.CommonTemplates.Find(DriverTemplateName); 
	DriverTemplatePatch = Metadata.CommonTemplates.Find(NameOfDriverTemplatePatch);  
	
	If DriverTemplatePatch <> Undefined And DriverTemplatePatch.TemplateType = Metadata.ObjectProperties.TemplateType.AddIn Then 
		TemplateIsAvailable = True;      
		If Not IsBlankString(LanguageCode) Then // We check the file with the presence of localization
			TemplateLocalizationPattern = NameOfDriverTemplatePatch + "_" + LanguageCode;   
			TemplatePattern = Metadata.CommonTemplates.Find(TemplateLocalizationPattern);
			If TemplatePattern <> Undefined And TemplatePattern.TemplateType = Metadata.ObjectProperties.TemplateType.TextDocument Then
				LocalizationPattern = GetCommonTemplate(TemplateLocalizationPattern).GetText();
			EndIf;              
		EndIf;              
		DriverTemplateName = NameOfDriverTemplatePatch;
	ElsIf DriverTemplate <> Undefined And DriverTemplate.TemplateType = Metadata.ObjectProperties.TemplateType.AddIn Then
		TemplateIsAvailable = True;                 
		If Not IsBlankString(LanguageCode) Then // We check the file with the presence of localization
			TemplateLocalizationPattern = DriverTemplateName + "_" + LanguageCode;   
			TemplatePattern = Metadata.CommonTemplates.Find(TemplateLocalizationPattern);
			If TemplatePattern <> Undefined And TemplatePattern.TemplateType = Metadata.ObjectProperties.TemplateType.TextDocument Then
				LocalizationPattern = GetCommonTemplate(TemplateLocalizationPattern).GetText();
			EndIf;              
		EndIf;              
	Else // We check the presence of the driver by the mask type "*_ru"
		If IsBlankString(LanguageCode) Then
			LanguageCode = CurrentLanguage().LanguageCode;
		EndIf;
		DriverTemplateName = DriverTemplateName + "_" + LanguageCode;   
		TemplatePattern = Metadata.CommonTemplates.Find(DriverTemplateName);
		TemplateIsAvailable = TemplatePattern <> Undefined And TemplatePattern.TemplateType = Metadata.ObjectProperties.TemplateType.AddIn;
	EndIf;              
	
	DriverTemplateName = "CommonTemplate." + DriverTemplateName;     
	
EndProcedure

// Fills in data about the external components used
//
// Parameters:
//   Components - ValueTable
Procedure FillInExternalComponentsUsed(Components) Export
	
	If CommonCEL.SubsystemExists("StandardSubsystems.BarcodeGeneration") Then
		NewRow = Components.Add();
		NewRow.Id = "Barcode";
		NewRow.AutoUpdate = True;   
	EndIf;
	
	
	// add hardware drivers that are present in the connected hardware Catalog
	DriverIds = EquipmentManagerCached.DriverIds();
	For Each Id In DriverIds Do
		NewRow = Components.Add();
		NewRow.Id = Id;
		NewRow.AutoUpdate = True;
	EndDo
	
EndProcedure

// Returns an empty table of supplied hardware drivers. 
//
// Returns:
//  ValueTable:
//   * EquipmentType - EnumRef.PeripheralTypes - Type of equipment
//   * Description - String - Equipment name
//   * ObjectID - String - unique object ID
//   * NameOfDriver - String - internal driver name
//   * DriverTemplateName - String - the name of the driver Template, if it differs from the driver name
//   * DriverVersion - String
//   * NoLongerSupported - Boolean - indicates that the driver has been removed from support
//   * ConnectionMethod - EnumRef.DriverConnectionMethod
//   * LocalMode_ - Boolean - indicates whether the driver is local
//   * NetworkMode - Boolean - indicates that it is working in network mode
//   * ServerMode - Boolean    
//   * SafeConnection - Boolean - Connecting the driver in a separate thread
//   * RecommendedUse - Boolean - The driver is recommended for use
//
Function NewTableOfSuppliedHardwareDrivers() Export
	
	DriversOfHardware = New ValueTable;
	// General properties.
	DriversOfHardware.Columns.Add("EquipmentType"     , New TypeDescription("EnumRef.PeripheralTypes"));
	DriversOfHardware.Columns.Add("Description"        , New TypeDescription("String", , New StringQualifiers(0)));
	DriversOfHardware.Columns.Add("ObjectID", New TypeDescription("String", , New StringQualifiers(0)));
	DriversOfHardware.Columns.Add("NameOfDriver"         , New TypeDescription("String", , New StringQualifiers(0)));
	DriversOfHardware.Columns.Add("DriverTemplateName"   , New TypeDescription("String", , New StringQualifiers(0)));
	DriversOfHardware.Columns.Add("DriverVersion"      , New TypeDescription("String", , New StringQualifiers(0)));
	DriversOfHardware.Columns.Add("NoLongerSupported"      , New TypeDescription("Boolean"));
	DriversOfHardware.Columns.Add("ConnectionMethod"   , New TypeDescription("EnumRef.DriverConnectionMethod"));
	DriversOfHardware.Columns.Add("SafeConnection"      , New TypeDescription("Boolean"));
	DriversOfHardware.Columns.Add("RecommendedUse" , New TypeDescription("Boolean"));
	// Operation parameters
	DriversOfHardware.Columns.Add("LocalMode_", New TypeDescription("Boolean"));
	DriversOfHardware.Columns.Add("NetworkMode"  , New TypeDescription("Boolean"));
	DriversOfHardware.Columns.Add("ServerMode", New TypeDescription("Boolean"));   
	Return DriversOfHardware;
	
EndFunction

// Returns an array containing the names of layouts for reinstalling drivers that require reinstalling,
// as well as removes the flag of the reinstalling feature from the found elements.
//
// Parameters:
//   Workplace - CatalogRef.Workplaces - Current workplace
//
// Returns:
//   Array of Structure - names of layouts of external components that need to be reinstalled
Function TemplatesForReinstallingDrivers(Workplace) Export

	EquipmentForReinstalling = New Array();
	
	// Reinstall the drivers marked with the flag for reinstalling.
	If ValueIsFilled(Workplace) Then
		SelectionList = EquipmentManagerClientServer.ListOfEquipmentSelection();
		SelectionList.Workplace = Workplace;
		EquipmentList = EquipmentList(SelectionList);
		HardwareDrivers = New Array();
		For Each Equipment In EquipmentList Do
			If Equipment.ConnectingFromTemplate And Equipment.TemplateIsAvailable And Equipment.ReinstallationIsRequired Then
				DescriptionOfEquipmentForReinstalling = New Structure();   
				DescriptionOfEquipmentForReinstalling.Insert("DriverTemplateName", Equipment.DriverTemplateName);
				DescriptionOfEquipmentForReinstalling.Insert("Description", Equipment.Description);
				DescriptionOfEquipmentForReinstalling.Insert("Version", Equipment.DriverVersion);
				DescriptionOfEquipmentForReinstalling.Insert("TemplateIsAvailable", Equipment.TemplateIsAvailable);
				DescriptionOfEquipmentForReinstalling.Insert("ConnectingFromTemplate", Equipment.ConnectingFromTemplate);
				EquipmentForReinstalling.Add(DescriptionOfEquipmentForReinstalling);
				HardwareDrivers.Add(Equipment.HardwareDriver);
			EndIf;
		EndDo;
		SetSignOfReinstallingDriversAtWorkplace(
			Workplace,
			HardwareDrivers,
			False); 
	EndIf;
	
	Return EquipmentForReinstalling;
	
EndFunction

// ++ Non-mobile application

// Returns the value of the constant using the RDP protocol
// 
// Returns:
//  Boolean
//
Function RDPProtocolIsUsed() Export
	SetPrivilegedMode(True);
	Return Constants.RDPProtocolIUsedInCEL.Get();
EndFunction

// -- Non-mobile application

// Set the update flag for the transmitted types of connected equipment
//
// Parameters:
//  TypesOfEquipment - Array of EnumRef.PeripheralTypes
//
Procedure SetUpdateFlagByType(TypesOfEquipment) Export
	
	SetPrivilegedMode(True);
	
	Query = New Query("SELECT
							|	Peripherals.Ref
							|FROM
							|	Catalog.Peripherals AS Peripherals
							|WHERE
							|	(Peripherals.EquipmentType IN (&TypesOfEquipment))");
							
	Query.SetParameter("TypesOfEquipment", TypesOfEquipment);
	
	Selection = Query.Execute().Select();
	While Selection.Next() Do
		CatalogObject = Selection.Ref.GetObject();
		CatalogObject.ReinstallationIsRequired = True;
		WriteData(CatalogObject);
	EndDo;
	
EndProcedure

// ++ Non-mobile application

// Update required external components from ITS website
Procedure UpdateInstalledAttachableEquipmentFromSite(Parameters) Export
	
	If Not CommonCEL.SubsystemExists("OnlineUserSupport.GetAddIns") Then
		Return
	EndIf;
	If Not CommonCEL.SubsystemExists("StandardSubsystems.AddIns") Then
		Return
	EndIf;
	If CommonCEL.DataSeparationEnabled() Then
		Return;
	EndIf;
	
	TypesOfDrivers = TypesOfDriversThatMustBeUpdated();
	
	Query = New Query;
	Query.Text = 
		"SELECT ALLOWED DISTINCT
		|	CAST(Peripherals.HardwareDriver.ObjectID AS STRING(100)) AS Id,
		|	CAST(Peripherals.HardwareDriver.DriverTemplateName AS STRING(100)) AS DriverTemplateName,
		|	Peripherals.HardwareDriver.PredefinedDataName AS PredefinedDataName
		|FROM
		|	Catalog.Peripherals AS Peripherals
		|WHERE
		|	NOT Peripherals.DeletionMark
		|	AND Peripherals.DeviceIsInUse
		|	AND Peripherals.EquipmentType IN(&TypesOfEquipment)
		|	AND Peripherals.HardwareDriver.ConnectionMethod <> VALUE(Enum.DriverConnectionMethod.From_Template)";
		
	Query.SetParameter("TypesOfEquipment", TypesOfDrivers);
	
	DriverIds = Query.Execute().Unload().UnloadColumn("Id");
	If DriverIds.Count()=0 Then
		Return;
	EndIf;
	
	ModuleGetAddIns = CommonCEL.CommonModule("GetAddIns");
	AddInsDetails = ModuleGetAddIns.AddInsDetails(); // ValueTable 
	For Each Id In DriverIds Do // String
		String = AddInsDetails.Add();
		String.Id = Id;
		String.AutoUpdate = True;
	EndDo;
	Result = ModuleGetAddIns.CurrentVersionsOfExternalComponents(AddInsDetails);
	If ValueIsFilled(Result.ErrorCode) Then
		CommonCEL.WriteErrorToEventLog(NStr("vi = 'Cập nhật thiết bị kết nối';
											|ru = 'Обновление подключаемого оборудования';
											|en = 'Update peripherals'; fa = 'Update peripherals';
											|it = 'Обновление подключаемого оборудования';
											|pl = 'Update peripherals';
											|tr = 'Çevre birimlerini güncelle'"), Result.ErrorMessage);
		Return;
	EndIf;
	
	Id = New UUID();
	ResultAddress = PutToTempStorage("", Id);
	
	ExternalComponentsServerModule = CommonCEL.CommonModule("AddInsServer");
	ExternalComponentsServerModule.UpdateAddIns(Result.AddInsData, ResultAddress);
	UpdateResult = GetFromTempStorage(ResultAddress);
	
	Parameters.ProcessingCompleted = True;
	
EndProcedure

#Region ForTransitionalPeriodOfCuttingOffDrivers

Procedure ProcessDriversWhenUpdatingInformationBase(Parameters) Export
	
	DownloadDriversToExternalComponentsCatalog();
	Parameters.ProcessingCompleted = True;
	
EndProcedure

// Check and download all used drivers plugged in from the Template
Procedure DownloadDriversToExternalComponentsCatalog() Export
	
	If CommonCEL.DataSeparationEnabled() Then
		Return;
	EndIf;
	If Not CommonCEL.SubsystemExists("OnlineUserSupport.GetAddIns") Then
		Return
	EndIf;
	If Not CommonCEL.SubsystemExists("StandardSubsystems.AddIns") Then
		Return
	EndIf;
	
	// 1. Get a list of used drivers
	ToDownloadFromITSWebsite = New Array();
	ToAddToExternalComponentsFromTemplate = New Array();
	
	UsedDrivers = UsedDriversOfConnectedEquipment();
	
	StandardProcessing = True;
	EquipmentManagerServerCallOverridable.WhenLoadingDriversIntoCatalogOfExternalComponentsWhenUpdatingInformationSecurity(UsedDrivers, StandardProcessing);
	If Not StandardProcessing Then
		Return;
	EndIf;
	
	For Each Driver In UsedDrivers Do
		
		If Not Driver.VBPOEnters Then
			Continue;
		EndIf;
		
		// 3. Not found in the External Components Catalog
		If Not Driver.ItIsInVKCatalog Then
			
			// 4. The Template is available in the configuration
			If Driver.TemplateIsAvailable Then
				DataToAdd = NewDataToAddExternalComponentsToCatalog();
				FillPropertyValues(DataToAdd, Driver);
				
				ToAddToExternalComponentsFromTemplate.Add(DataToAdd);
			Else
				
				DataForImport = NewDataForDownloadingDriverFromITSWebsite();
				FillPropertyValues(DataForImport, Driver);
				
				ToDownloadFromITSWebsite.Add(DataForImport);
			EndIf;     
		Else
			SetDriverConnectionMethod(Driver.Ref, Enums.DriverConnectionMethod.DriverIsAttachedFromInfobase);
			
			// 4. The Template is available in the configuration
			If Driver.TemplateIsAvailable Then
				DataToAdd = NewDataToAddExternalComponentsToCatalog();
				FillPropertyValues(DataToAdd, Driver);
				ToAddToExternalComponentsFromTemplate.Add(DataToAdd);
			EndIf;
		EndIf;
			
	EndDo;
	
	If ToAddToExternalComponentsFromTemplate.Count()>0 Then
		AddExternalComponentFromTemplateToCatalogInternal(ToAddToExternalComponentsFromTemplate);
	EndIf;
	
	If ToDownloadFromITSWebsite.Count()>0 Then
		DownloadDriversFromITSWebsiteInternal(ToDownloadFromITSWebsite);
	EndIf;
	
EndProcedure

// Constructor for data to add to the Catalog of connected equipment
// 
// Returns:
//  Structure:
//   * Ref - String - 
//   * Id - String - 
//   * TemplateName - String - 
//   * Description - String - 
//   * Version - String - 
Function NewDataToAddExternalComponentsToCatalog() Export
	
	Result = New Structure();
	Result.Insert("Ref", "");
	Result.Insert("Id", "");
	Result.Insert("TemplateName", "");
	Result.Insert("Description", "");
	Result.Insert("Version", "");
	Return Result;
	
EndFunction

// Add external components drivers from the Template to the Catalog
// 
// Parameters:
//  ToAddToExternalComponentsFromTemplate - Array of See NewDataToAddExternalComponentsToCatalog
// 
// Returns:
//  Structure:
//   * Result - Boolean - 
//   * Errors - Map of KeyAndValue - 
Function AddExternalComponentFromTemplateToCatalogInternal(ToAddToExternalComponentsFromTemplate) Export
	
	InformationAboutBPOComponents = EquipmentManager.DriversInformation();
	
	OperationResult = New Structure();
	OperationResult.Insert("Result", False);
	OperationResult.Insert("Errors", New Map());
	
	ToSetStatusItIsConnectedFromIB = New Map();
	
	AddInsData = New ValueTable();
	AddInsData.Columns.Add("Id");
	AddInsData.Columns.Add("Version");
	AddInsData.Columns.Add("VersionDate");
	AddInsData.Columns.Add("Description");
	AddInsData.Columns.Add("FileName");
	AddInsData.Columns.Add("FileAddress");
	AddInsData.Columns.Add("ErrorCode");
	
	For Each Data In ToAddToExternalComponentsFromTemplate Do // Structure
		
		If Metadata.CommonTemplates.Find(Data.TemplateName)<> Undefined Then
			String = AddInsData.Add();
			String.Id = Data.Id;
			String.Version = Data.Version;
			AddInInformation = InformationAboutBPOComponents[Data.Id];
			If AddInInformation <> Undefined Then
				String.VersionDate = AddInInformation.VersionDate;
			Else
				String.VersionDate = Date(1,1,1);
			EndIf;
			String.Description = Data.Description;
			Template = GetCommonTemplate(Data.TemplateName);
			String.FileAddress = PutToTempStorage(Template);
			ToSetStatusItIsConnectedFromIB.Insert(Data.Id, Data.Ref);
		EndIf;
		
	EndDo;
	
	Id = New UUID();
	ResultAddress = PutToTempStorage("", Id);
	
	ExternalComponentsServerModule = CommonCEL.CommonModule("AddInsServer");
	ExternalComponentsServerModule.UpdateAddIns(AddInsData, ResultAddress);
	ImportResult1 = GetFromTempStorage(ResultAddress);
	If Not ImportResult1.Result Then
		For Each Error In ImportResult1.Errors Do
			OperationResult.Errors.Insert(Error.Key, Error.Value);
			ToSetStatusItIsConnectedFromIB.Delete(Error.Key);
		EndDo;
	EndIf;
	
	For Each KeyAndValue In ToSetStatusItIsConnectedFromIB Do
		SetDriverConnectionMethod(KeyAndValue.Value, Enums.DriverConnectionMethod.DriverIsAttachedFromInfobase);
	EndDo;
	
	OperationResult.Result = (OperationResult.Errors.Count() = 0);
	Return OperationResult;
	
	
EndFunction

// Constructor for data to add to the Catalog of connected equipment
// 
// Returns:
//  Structure:
//   * Ref - String - 
//   * Id - String - 
Function NewDataForDownloadingDriverFromITSWebsite() Export
	
	Result = New Structure();
	Result.Insert("Ref", "");
	Result.Insert("Id", "");
	Return Result;
	
EndFunction

// Downloads drivers from ITS website.
// 
// Parameters:
//  ToDownloadFromITSWebsite - Array of See NewDataForDownloadingDriverFromITSWebsite
// 
// Returns:
//  Structure - Download drivers from the IT Service website:
//   * Result - Boolean - 
//   * Errors - Map of KeyAndValue - 
//   * ErrorMessage - String - 
Function DownloadDriversFromITSWebsiteInternal(ToDownloadFromITSWebsite) Export
	
	ToSetStatusItIsConnectedFromIB = New Map();
	
	OperationResult = New Structure();
	OperationResult.Insert("Result", False);
	OperationResult.Insert("Errors", New Map());
	OperationResult.Insert("ErrorMessage", "");
	
	ModuleGetAddIns = CommonCEL.CommonModule("GetAddIns");
	AddInsDetails = ModuleGetAddIns.AddInsDetails();
	For Each Data In ToDownloadFromITSWebsite Do // Structure
		String = AddInsDetails.Add(); // ValueTableRow
		String.Id = Data.Id;
		String.AutoUpdate = True;
		
		ToSetStatusItIsConnectedFromIB.Insert(Data.Id, Data.Ref);
	EndDo;
	
	UpdatingResult = ModuleGetAddIns.CurrentVersionsOfExternalComponents(AddInsDetails);
	If ValueIsFilled(UpdatingResult.ErrorCode) Then
		
		CommonCEL.WriteErrorToEventLog(NStr("vi = 'Cập nhật thiết bị kết nối';
											|ru = 'Обновление подключаемого оборудования';
											|en = 'Update peripherals'; fa = 'Update peripherals';
											|it = 'Обновление подключаемого оборудования';
											|pl = 'Update peripherals';
											|tr = 'Çevre birimlerini güncelle'"), UpdatingResult.ErrorMessage);
		OperationResult.ErrorMessage = UpdatingResult.ErrorMessage;
		For Each AddIn In UpdatingResult.AddInsData Do // Structure
			If IsBlankString(AddIn.ErrorCode) Then
				Continue;
			EndIf;
			OperationResult.Errors.Insert(AddIn.Id, AddIn.ErrorCode);
			ToSetStatusItIsConnectedFromIB.Delete(AddIn.Id);
		EndDo;
		
		Return OperationResult;
	EndIf;
	
	Id = New UUID();
	ResultAddress = PutToTempStorage("", Id);
	
	ExternalComponentsServerModule = CommonCEL.CommonModule("AddInsServer");
	ExternalComponentsServerModule.UpdateAddIns(UpdatingResult.AddInsData, ResultAddress);
	ImportResult1 = GetFromTempStorage(ResultAddress);
	If Not ImportResult1.Result Then
		For Each Error In ImportResult1.Errors Do
			OperationResult.Errors.Insert(Error.Key, Error.Value);
			ToSetStatusItIsConnectedFromIB.Delete(Error.Key);
		EndDo;
		ErrorText = NStr("vi = 'Lỗi thêm driver vào danh mục Cấu phần ngoài.';
						|ru = 'Ошибка добавления драйвера в справочник Внешние компоненты.';
						|en = 'An error occurred when adding the driver to the ""Add-ins"" catalog.'; fa = 'An error occurred when adding the driver to the ""Add-ins"" catalog.';
						|it = 'Ошибка добавления драйвера в справочник Внешние компоненты.';
						|pl = 'An error occurred when adding the driver to the ""Add-ins"" catalog.';
						|tr = 'Harici Eklentiler kataloğuna sürücü eklenirken hata oluştu.'");
		OperationResult.Insert("ErrorMessage", ErrorText);
	EndIf;
	
	For Each KeyAndValue In ToSetStatusItIsConnectedFromIB Do
		SetDriverConnectionMethod(KeyAndValue.Value, Enums.DriverConnectionMethod.DriverIsAttachedFromInfobase);
	EndDo;
	
	OperationResult.Result = (OperationResult.Errors.Count() = 0);
	Return OperationResult;
	
EndFunction

Procedure SetDriverConnectionMethod(ObjectReference, ConnectionMethod) Export
	
	BeginTransaction();
	Try
		
		SetPrivilegedMode(True);
		
		Block = New DataLock;
		LockItem = Block.Add("Catalog.HardwareDrivers");
		LockItem.SetValue("Ref", ObjectReference);
		Block.Lock();
		
		Object = ObjectReference.GetObject();
		Object.Lock();
		Object.ConnectionMethod = ConnectionMethod;
		Object.Write();
		
		CommitTransaction();
	Except
		RollbackTransaction();
		
		CommonCEL.WriteErrorToEventLog(
			NStr("vi = 'Cập nhật cấu phần ngoài';
				|ru = 'Обновление внешних компонент';
				|en = 'Updating add-ins'; fa = 'به‌روزرسانی افزونه‌ها';
				|it = 'Обновление внешних компонент';
				|pl = 'Aktualizacja komponentów zewnętrznych';
				|tr = 'Harici eklentilerin güncellenmesi'", CommonCEL.DefaultLanguageCode()),
			ErrorProcessing.DetailErrorDescription(ErrorInfo()));
	EndTry;
	
EndProcedure

#EndRegion

// -- Non-mobile application

#Region Workplaces

Function WorkplaceSettingsAtStartup(Workplace) Export
	
	WorkplaceParameters = EquipmentManagerClientServer.NewWorkplaceSettings();
	WorkplaceParameters.Workplace = Workplace;
	If ValueIsFilled(Workplace) Then
		FillInRecordedAttributesOfWorkplace(Workplace, WorkplaceParameters.RecordedSearchAttributes);
	EndIf;
	FillInCurrentAttributesOfWorkplace(WorkplaceParameters.CurrentSearchAttributes);
	Return WorkplaceParameters;
	
EndFunction

Procedure FillInRecordedAttributesOfWorkplace(Workplace, WorkplaceAttributes) Export
	
	SetPrivilegedMode(True);
	If ValueIsFilled(Workplace) Then
		Attributes = CommonCEL.ObjectAttributesValues(Workplace, "Code, ComputerName, MACAddress, MACAddresses");
		If Attributes.MACAddresses <> Undefined Then
			WorkplaceAttributes.MACAddresses = Attributes.MACAddresses.Unload().UnloadColumn("Address");
			WorkplaceAttributes.ComputerName = Attributes.ComputerName;
			WorkplaceAttributes.ClientID = Attributes.Code;
		EndIf;
	EndIf;
	
EndProcedure

Procedure FillInCurrentAttributesOfWorkplace(WorkplaceAttributes) Export
	
	If WorkplaceAttributes = Undefined Then
		WorkplaceAttributes = EquipmentManagerClientServer.NewWorkplaceSearchAttributes();
	EndIf;
	
	If Not ValueIsFilled(WorkplaceAttributes.ComputerName) Then
		ComputerName = CommonCEL.ClientSComputerName();
		WorkplaceAttributes.ComputerName = ComputerName;
	EndIf;
	
	If Not ValueIsFilled(WorkplaceAttributes.ClientID) Then
		ClientID = EquipmentManagerClientServer.ClientIDForWorkplace();
		WorkplaceAttributes.ClientID = ClientID;
	EndIf;
	
EndProcedure

// Updates workplace Attributes
// 
// Parameters:
//  Workplace - CatalogRef.Workplaces - Job
//  CurrentWorkplaceAttributes - See EquipmentManagerClient.Peripherals
//
Procedure UpdateWorkplaceAttributes(Workplace, CurrentWorkplaceAttributes) Export
	
	If Not ValueIsFilled(Workplace) Then
		Return;
	EndIf;
	
	SetPrivilegedMode(True);
	
	WorkplaceAttributes = EquipmentManagerClientServer.NewWorkplaceSearchAttributes();
	FillInRecordedAttributesOfWorkplace(Workplace, WorkplaceAttributes);
	AttributesForRecording = New Structure;
	
	If ValueIsFilled(CurrentWorkplaceAttributes.ComputerName)
		And CurrentWorkplaceAttributes.ComputerName <> WorkplaceAttributes.ComputerName Then
		AttributesForRecording.Insert("ComputerName", CurrentWorkplaceAttributes.ComputerName);
	EndIf;
	
	If CurrentWorkplaceAttributes.MACAddresses.Count() > 0
		And Not CommonCELClientServer.ArraysMatch(
			CurrentWorkplaceAttributes.MACAddresses, WorkplaceAttributes.MACAddresses) Then
		AttributesForRecording.Insert("MACAddresses", CurrentWorkplaceAttributes.MACAddresses);
	EndIf;
	
	If AttributesForRecording.Count() > 0 Then
		
		BeginTransaction();
		Try
			Block = New DataLock;
			LockItem = Block.Add("Catalog.Workplaces");
			LockItem.SetValue("Ref", Workplace);
			LockItem.Mode = DataLockMode.Exclusive;
			Block.Lock();
			
			ObjectWorkplace = Workplace.GetObject();
			If AttributesForRecording.Property("Code") Then
				ObjectWorkplace.Code = AttributesForRecording.Code;
			EndIf;
			If AttributesForRecording.Property("ComputerName") Then
				ObjectWorkplace.ComputerName = AttributesForRecording.ComputerName;
			EndIf;
			If AttributesForRecording.Property("MACAddresses") Then
				ObjectWorkplace.MACAddresses.Clear();
				For Each MACAddress In AttributesForRecording.MACAddresses Do
					NewAddress = ObjectWorkplace.MACAddresses.Add();
					NewAddress.Address = MACAddress;
				EndDo;
			EndIf;
			If ObjectWorkplace.CheckFilling() Then
				ObjectWorkplace.Write();
			EndIf;
			CommitTransaction();
		Except
			RollbackTransaction();
			CommonCEL.WriteErrorToEventLog(
				NStr("vi = 'Chỗ làm việc của Thư viện thiết bị được kết nối.';
					|ru = 'Рабочие места БПО.';
					|en = 'PEL workplaces.'; fa = 'PEL workplaces.';
					|it = 'PEL workplaces.';
					|pl = 'PEL workplaces.';
					|tr = 'Eklenti Donanım Kütüphanesi çalışma alanları.'"),
				ErrorProcessing.DetailErrorDescription(ErrorInfo()));
		EndTry;
	EndIf;
	
EndProcedure

#EndRegion

Function LibraryClassifiers() Export
	
	Classifiers = New Structure;
	Classifiers.Insert("CodesOfPlannedStatusesOfMarkedProduct", New Map);
	Classifiers.Insert("MeasureOfQuantityOfSubjectOfCalculationByUnitCode", New Map);
	Classifiers.Insert("MeasureOfQuantityOfSubjectOfCalculationOfKKTByCode", New Map);
	Classifiers.Insert("CodesOfMeasureOfQuantityOfSubjectOfCalculationOfCCT", New Map);
	Classifiers.Insert("CodesOfUnitsOfMeasurementByKKTCode", New Map);
	Classifiers.Insert("ProductStatusResponseCodes", New Map);
	Classifiers.Insert("ResponsesAboutProductStatusByCode", New Map);
	Classifiers.Insert("StatusesOfKMRequestProcessingByCode", New Map);
	Classifiers.Insert("PaymentTypeCodeAtTerminal", New Map);
	Classifiers.Insert("TypeOfPaymentAtTerminalByCode", New Map);
	
	If CommonCEL.CheckPrintingDevicesAreUsed() Then
	EndIf;
	
	If CommonCEL.UsedPaymentSystems() Then
		Classifiers.PaymentTypeCodeAtTerminal =
			Enums.PaymentKindOnTerminal.PaymentTypeCodeAtTerminal();
		Classifiers.TypeOfPaymentAtTerminalByCode =
			Enums.PaymentKindOnTerminal.TypeOfPaymentAtTerminalByCode();
	EndIf;
		
	Return Classifiers;
	
EndFunction

// ++ Non-mobile application

Function HardwareErrorTextAnalysis(DeviceID, Val ConnectionParameters, Val ErrorText) Export
	
	Result = New Structure;
	Result.Insert("LocalError_Handling", False);
	Result.Insert("ShortDescription", "");
	Result.Insert("ErrorDescription", "");
	
	DriverIsSuppliedInConfiguration = DriverIsSuppliedInConfiguration(DeviceID);

	Current_DriverVersion = "";
	CurrentDriverVersion = "";
	CurrentDriverVersionIsInstalled = True;
	If ConnectionParameters <> Undefined Then
		Current_DriverVersion = ConnectionParameters.DriverVersion;
		CurrentDriverVersion = CurrentDriverVersion(ConnectionParameters.DeviceID_);
		If ValueIsFilled(CurrentDriverVersion) And CurrentDriverVersion <> Current_DriverVersion Then
			CurrentDriverVersionIsInstalled = False;
		EndIf;
	EndIf;
	
	If DriverIsSuppliedInConfiguration And CurrentDriverVersionIsInstalled Then
		
		ErrorClass = ErrorClass(ErrorText);
		Result.LocalError_Handling = ErrorClass.LocalError_Handling;
		Result.ErrorDescription = ErrorText + Chars.LF + ErrorClass.DetailedDescription;
		Result.ShortDescription = ErrorClass.ShortDescription;
		
	ElsIf Not DriverIsSuppliedInConfiguration Then
		Result.LocalError_Handling = True;
		DetailedDescription = 
			NStr("vi = 'Driver của thiết bị đang sử dụng chưa được chứng nhận hoặc đã bị dừng hỗ trợ.';
				|ru = 'Используемый драйвер оборудования не сертифицирован или снят с поддержки.';
				|en = 'The used hardware driver is not certified or is no longer supported.'; fa = 'The used hardware driver is not certified or is no longer supported.';
				|it = 'The used hardware driver is not certified or is no longer supported.';
				|pl = 'The used hardware driver is not certified or is no longer supported.';
				|tr = 'Kullanılan donanım sürücüsü sertifikalı değildir veya desteği kaldırılmıştır.'") + Chars.LF +  
			NStr("vi = 'Vui lòng liên hệ với nhà cung cấp driver để được trợ giúp.';
				|ru = 'Обратитесь, пожалуйста, за помощью к поставщику драйвера.';
				|en = 'Please contact the driver vendor for help.'; fa = 'Please contact the driver vendor for help.';
				|it = 'Обратитесь, пожалуйста, за помощью к поставщику драйвера.';
				|pl = 'Please contact the driver vendor for help.';
				|tr = 'Destek için lütfen sürücü sağlayıcınız ile irtibata geçin.'");
		Result.ErrorDescription = ErrorText + Chars.LF + DetailedDescription;
		Result.ShortDescription = NStr("vi = 'Chưa chứng thực driver';
										|ru = 'Драйвер не сертифицирован';
										|en = 'Driver not certified'; fa = 'Driver not certified';
										|it = 'Driver not certified';
										|pl = 'Driver not certified';
										|tr = 'Sürücü sertifikalı değil.'");
	ElsIf Not CurrentDriverVersionIsInstalled Then
		Result.LocalError_Handling = True;
		DetailedDescription = 
			StrTemplate(NStr("vi = 'Phiên bản của driver này đã cũ, phiên bản hiện tại của driver %1, phiên bản driver mới nhất %2.';
							|ru = 'Версия этого драйвера устарела, текущая версия драйвера %1, актуальная версия драйвера %2.';
							|en = 'The version of this driver is outdated. The current driver version is %1, the latest driver version is %2.'; fa = 'The version of this driver is outdated. The current driver version is %1, the latest driver version is %2.';
							|it = 'The version of this driver is outdated. The current driver version is %1, the latest driver version is %2.';
							|pl = 'The version of this driver is outdated. The current driver version is %1, the latest driver version is %2.';
							|tr = 'Bu sürücünün sürümü güncel değil, mevcut sürücü sürümü %1 , güncel sürücü sürümü %2 .'"), 
				Current_DriverVersion, 
				CurrentDriverVersion) + 
			Chars.LF +  
			NStr("vi = 'Vui lòng cập nhật driver để thiết bị hoạt động bình thường.';
				|ru = 'Обновите драйвер для корректной работы.';
				|en = 'Update the driver for correct operation.'; fa = 'Update the driver for correct operation.';
				|it = 'Update the driver for correct operation.';
				|pl = 'Update the driver for correct operation.';
				|tr = 'Doğru çalışması için sürücüyü güncelleyin.'");
		Result.ShortDescription = NStr("vi = 'Phiên bản driver lỗi thời';
										|ru = 'Устаревшая версия драйвера';
										|en = 'Outdated driver version'; fa = 'Outdated driver version';
										|it = 'Outdated driver version';
										|pl = 'Outdated driver version';
										|tr = 'Güncel olmayan sürücü sürümü'");
		Result.ErrorDescription = ErrorText + Chars.LF + DetailedDescription;
	EndIf;
	
	Return Result;
	
EndFunction

// -- Non-mobile application

#Region AllowedMethodsToBeCalledAsArbitraryCode

// Returns a list of methods that can be called as arbitrary code
// (for routine tasks and background tasks)
Procedure OnDefineMethodsAllowedForCallAsArbitraryCode(Methods) Export
	
	Methods.Insert("ProcessDriversWhenUpdatingInformationBase");
	Methods.Insert("UpdateInstalledAttachableEquipmentFromSite");
	
EndProcedure

#EndRegion

#EndRegion

#Region Private

Procedure RemoveOutdatedDrivers()
	
	Query = New Query;
	Query.Text = 
		"SELECT
		|	HardwareDrivers.Ref AS Ref,
		|	HardwareDrivers.Presentation AS Presentation
		|FROM
		|	Catalog.HardwareDrivers AS HardwareDrivers
		|		LEFT JOIN Catalog.Peripherals AS Peripherals
		|		ON HardwareDrivers.Ref = Peripherals.HardwareDriver
		|WHERE
		|	HardwareDrivers.EquipmentType = VALUE(Enum.PeripheralTypes.EmptyRef)
		|	AND Peripherals.Ref IS NULL";
	
	Result = Query.Execute();
	If Result.IsEmpty() Then
		Return;
	EndIf;
	
	Selection = Result.Select();
	While Selection.Next() Do
		OutdatedDriverObject = Selection.Ref.GetObject();
		Try
			OutdatedDriverObject.Lock();
			OutdatedDriverObject.DataExchange.Load = True;
			OutdatedDriverObject.DataExchange.Recipients.AutoFill = False;
			OutdatedDriverObject.AdditionalProperties.Insert("DisableObjectChangeRecordMechanism");
			OutdatedDriverObject.Delete();
		Except
			ErrorText = StrTemplate(NStr("vi = 'Không thể chặn driver đã bị xóa %1.';
										|ru = 'Не удается заблокировать удаляемый драйвер %1.';
										|en = 'Cannot lock the %1 driver to delete.'; fa = 'Cannot lock the %1 driver to delete.';
										|it = 'Non è stato possibile bloccare il driver eliminabile %1.';
										|pl = 'Nie udaje się zablokować usuwany sterownik %1.';
										|tr = 'Kaldırmakta olduğunuz %1 sürücüsü kilitlenemiyor.'", 
				CommonCEL.DefaultLanguageCode()), Selection.Presentation);
			CommonCEL.WriteErrorToEventLog(ErrorText);
		EndTry;
		
	EndDo;
	
EndProcedure

Function AttachableEquipmentOnForm(Form)

	PropertiesValues = New Structure("AttachableBPOEquipment", Null);
	FillPropertyValues(PropertiesValues, Form);

	Result = PropertiesValues.AttachableBPOEquipment;
	
	If TypeOf(Result) <> Type("Structure") Then
		If Result = Null Then
			AttributesToBeAdded = New Array;
			AttributesToBeAdded.Add(New FormAttribute("AttachableBPOEquipment", New TypeDescription));
			Form.ChangeAttributes(AttributesToBeAdded);
		EndIf;
		
		Result = New Structure;
		Result.Insert("EquipmentList", New Array());
		Result.Insert("RequestForListOfEquipmentOnClientIsRequired", False);
		Result.Insert("SoftwareTypes", ParametersTypesOfEquipment());
		
		Form.AttachableBPOEquipment = Result;
	EndIf;
	
	Return Result;

EndFunction

// Sets whether you need to reinstall hardware for connected equipment in the workplace.
//
// Parameters:
//  Workplace - CatalogRef.Workplaces
//  HardwareDrivers - Array of CatalogRef.HardwareDrivers 
//  Flag - Boolean - you need to reinstall the driver
//
Procedure SetSignOfReinstallingDriversAtWorkplace(Workplace, HardwareDrivers, Flag) Export
	
	SetPrivilegedMode(True);
	
	Query = New Query(
	"SELECT
	|	Peripherals.Ref AS Ref
	|FROM
	|	Catalog.Peripherals AS Peripherals
	|WHERE
	|	(Peripherals.Workplace = &Workplace  OR Peripherals.AttachmentType = VALUE(Enum.PeripheralsTypes.SharedAccess))
	|	AND Peripherals.HardwareDriver IN(&HardwareDrivers)
	|	AND Peripherals.ReinstallationIsRequired <> &ReinstallationIsRequired"); 
	
	Query.SetParameter("Workplace", Workplace);
	Query.SetParameter("HardwareDrivers", HardwareDrivers);
	Query.SetParameter("ReinstallationIsRequired", Flag);
	
	Selection = Query.Execute().Select();
	While Selection.Next() Do
		CatalogObject = Selection.Ref.GetObject();
		CatalogObject.ReinstallationIsRequired = Flag;
		WriteData(CatalogObject)
	EndDo;
	
EndProcedure

// Returns an array of hardware types that need to be reinstalled during the update
//
// Returns:
//   Array of EnumRef.PeripheralTypes
//
Function TypesOfDriversThatMustBeUpdated()
	
	Result = New Array();
	Result.Add(Enums.PeripheralTypes.CREWithDataTransfer);
	Result.Add(Enums.PeripheralTypes.LabelPrinters);
	Result.Add(Enums.PeripheralTypes.BarcodeScanner);
	Return Result;
	
EndFunction

// ++ Non-mobile application
Function ErrorClass(Val ErrorText)
	
#If MobileAppServer Then
	ErrorClass = EquipmentManagerCached.NewErrorClass("NotSupported", "", "", "");
	Return ErrorClass;
#Else
	ErrorsClassifier = EquipmentManagerCached.ErrorsClassifier();
	ErrorTextNormalized = TrimAll(Lower(ErrorText));
	
	For Each ErrorClass In ErrorsClassifier Do
		For Each SearchMask In ErrorClass.SearchMasks Do
			SearchResult = StrFindByRegularExpression(ErrorTextNormalized, SearchMask,,,,True);
			If SearchResult.StartIndex > 0 Then
				Return ErrorClass;
			EndIf;
		EndDo;
	EndDo;
	
	ShortMessage = NStr("vi = 'Đã xảy ra lỗi không xác định. Vui lòng liên hệ bộ phận hỗ trợ kỹ thuật';
						|ru = 'Произошла неизвестная ошибка. Пожалуйста, обратитесь в техническую поддержку';
						|en = 'An unknown error occurred. Please contact technical support'; fa = 'An unknown error occurred. Please contact technical support';
						|it = 'An unknown error occurred. Please contact technical support';
						|pl = 'An unknown error occurred. Please contact technical support';
						|tr = 'Bilinmeyen bir hata oluştu. Lütfen teknik destek ekibiyle iletişime geçin.'");
	ErrorClass = EquipmentManagerCached.NewErrorClass("NotFound4", ShortMessage, "", "");
	Return ErrorClass;
#EndIf
	
EndFunction

Function CurrentDriverVersion(DeviceID_)
	
	DriversInformation = DriversInformation();
	Information = DriversInformation[DeviceID_];
	If Information = Undefined Or Not ValueIsFilled(Information.Version) Then
		Return Undefined;
	EndIf;
	
	Return Information.Version;
	
EndFunction
// -- Non-mobile application

#EndRegion

#EndIf