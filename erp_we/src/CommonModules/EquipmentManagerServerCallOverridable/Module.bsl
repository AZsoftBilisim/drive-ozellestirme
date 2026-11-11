#Region Public

// Returns a list of available hardware types.
// 
// Parameters:
//   ListOfEquipmentTypes - Array of EnumRef.PeripheralTypes - 
//                             available types of connected equipment in the configuration.
//   StandardProcessing - Boolean - indicates whether standard processing is being performed.
// Example:
//   List of equipment types.Add(Enumerations.Type of pluggable equipment.CCT).
//
Procedure AvailableTypesOfEquipment(ListOfEquipmentTypes, StandardProcessing) Export
	
	// Bar code scanner
	ListOfEquipmentTypes.Add(Enums.PeripheralTypes.BarcodeScanner);
	// End Barcode Scanners
	
	
EndProcedure

// Retrieves the list of available types of network equipment.
// 
// Parameters:
//   ListOfEquipmentTypes - Array of EnumRef.PeripheralTypes - 
//                             available types of connected equipment in the configuration.
//   StandardProcessing - Boolean - indicates whether standard processing is being performed.
// Example:
//   List of equipment types.Add(Enumerations.Type of pluggable equipment.CCT).
//
Procedure AvailableTypesOfNetworkEquipment(ListOfEquipmentTypes, StandardProcessing) Export

EndProcedure

// Returns the flag for the possibility of adding new hardware drivers to the directory.
// Parameters:
//   AddingNewDriversIsAvailable - Boolean - flag for the possibility of adding new hardware connection components.
//   StandardProcessing - Boolean - indicates whether standard processing is being performed.
// Example:
//   Adding New drivers is available = A lie;
//   Standard processing = A lie. 
//
Procedure AvailableAddingNewDrivers(AddingNewDriversIsAvailable, StandardProcessing) Export
	
	AddingNewDriversIsAvailable = True;
	
EndProcedure

// Returns the availability of network equipment.
//
// Parameters:
//  NetworkEquipmentIsAvailable - Boolean - Network equipment is available.
//  StandardProcessing - Boolean - Standard treatment.
//
Procedure AvailableNetworkEquipment(NetworkEquipmentIsAvailable, StandardProcessing) Export
	
	StandardProcessing = False;     
	NetworkEquipmentIsAvailable = False;
	
EndProcedure

// Returns the availability of collection in the fiscal device management form.
//  
// Parameters:
//  CollectionIsAvailable - Boolean - Availability of collection.
//  StandardProcessing - Boolean - Standard treatment.
//
Procedure CollectionInManagementOfFiscalDeviceIsAvailable(CollectionIsAvailable, StandardProcessing) Export
	
EndProcedure

// Refunds without a card are available.       
//
// Parameters:
//  ReturnsWithoutCard - Structure - Refunds are available without a card:
//  * ReturnByPaymentCard - Boolean
//  * ReturnByElectronicCertificate - Boolean
//
Procedure AvailableReturnsWithoutCard(ReturnsWithoutCard) Export
	
EndProcedure  

// Redefined procedure for the access control subsystem Standardsystem
// See AccessManagementOverridable.OnFillListsWithAccessRestriction.
//
// Parameters:
//  Manager - String 
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
Procedure OnFillAccessRestriction(Manager, Restriction) Export
	
	Restriction.Text =
		"AllowReadUpdate
		|WHERE
		|	ObjectReadingAllowed(DocumentBasis)";
	
EndProcedure

#Region RefreshEnabled

// The redefined part of the update procedure from BPO 3
//  
// Parameters:
//  RefPeripherals - CatalogRef.Peripherals - equipment for updating the transition from BPO 3
//
Procedure UpdateCatalogOfConnectedEquipment(RefPeripherals) Export
	
EndProcedure

// Called when receiving driver identifiers to determine the drivers used stored in 
//   the External Components Catalog and the External Components Catalog. Allows you to change the list of supplied drivers and 
//   the list of drivers located in the undivided Catalog of general external components.
// Parameters:
//  IDs - Array of String - Driver Ids
Procedure WhenGettingDriverIds(IDs) Export

EndProcedure

// It is called when updating the information security system at the time of writing driver Templates to the external components Catalog
// Parameters:
//   UsedDrivers - See EquipmentManager.UsedDriversOfConnectedEquipment
//   StandardProcessing - Boolean
Procedure WhenLoadingDriversIntoCatalogOfExternalComponentsWhenUpdatingInformationSecurity(UsedDrivers, StandardProcessing) Export

EndProcedure

// Called when adding the connected equipment at the time of writing the driver Template to the External Components Catalog
//  
// Parameters:
//   DataToAdd - See EquipmentManager.UsedDriversOfConnectedEquipment 
//   StandardProcessing - Boolean
Procedure WhenLoadingDriverIntoCatalogOfExternalComponentsWhenAddingHardware(DataToAdd, StandardProcessing) Export

EndProcedure

#EndRegion

#Region CREEquipment

// The procedure fills in the organization's details for registering the FN.
//  
// Parameters:
//  Organization - DefinedType.CompanyCEL - organization for filling in the details.
//  RegistrationParameters - Structure - FN registration parameters.
//
Procedure FillInDetailsOfOrganizationForRegistrationOfFN(Organization, RegistrationParameters) Export
	
EndProcedure

// Overrides the generated receipt template.
//
// Parameters:
//  ReceiptTemplate - See PeripheralsReceiptPrintersClientServer.ParametersOfReceiptFiscalizationOperation
//  CommonParameters - See PeripheralsReceiptPrintersClientServer.ParametersOfReceiptFiscalizationOperation
//  AdditionalText - String - additional text of the receipt template.
//  StandardProcessing - Boolean - indicates standard processing.
//  EquipmentType - String - types of equipment by line.
//
Procedure GenerateReceiptTemplate(ReceiptTemplate, CommonParameters, AdditionalText, StandardProcessing, EquipmentType = "") Export

EndProcedure

// Returns for which types of identifiers the tag 1162 (product code) will be filled in.
//
// Parameters:
//  IDsTypes - Array of EnumRef.TypesOfGoodIDsCRE
//  StandardProcessing - Boolean - Standard treatment
//
Procedure ProductCodeIsFilledInForTypesOfIdentifiers(IDsTypes, StandardProcessing) Export
	
EndProcedure

// Returns which types of products the industry Attributes will be filled in for.
//
// Parameters:
//  TypesOfGoods - Structure:
//  * FurskinsProducts - Boolean - Fillings for natural fur products. 
//  * VolumetricAndVarietalAccounting - Boolean - Fillings for goods of volumetric and varietal accounting.
//
Procedure IndustryAttributesAreFilledInForProductTypes(TypesOfGoods) Export
	
	
EndProcedure

 // The ISMP is being recorded in the configuration
// Parameters:
//  AccountingOfISMPProducts - Boolean - The ISMP is being recorded in the configuration 
//  StandardProcessing - Boolean - performing standard processing
//
Procedure ISMPProductsAreRecorded(AccountingOfISMPProducts, StandardProcessing) Export

EndProcedure

// Volumetric and varietal accounting is conducted in the configuration
// Parameters:
//  VolumetricAndVarietalAccounting - Boolean - Volumetric and varietal accounting is conducted in the configuration 
//  StandardProcessing - Boolean - performing standard processing
//
Procedure VolumetricAndVarietalAccountingIsConducted(VolumetricAndVarietalAccounting, StandardProcessing) Export
	

	
EndProcedure 

// Returns catering services are provided
// Parameters:
//  PublicCatering - Boolean - Catering services are provided 
//  StandardProcessing - Boolean - performing standard processing
//
Procedure CateringServicesAreProvided(PublicCatering, StandardProcessing) Export


	
EndProcedure          

// A procedure where you can add any text when generating a receipt in PDF format.
//
// Parameters:
//   TitleText - String - The text that will be displayed when forming a cash receipt in PDF format
//   FooterText - String - The text that will be displayed when forming a cash receipt in PDF format
Procedure AdditionalTextWhenGeneratingPDFReceipt(TitleText, FooterText) Export
	
EndProcedure

// Called after the POS shift is opened
// Parameters:
//  DeviceID - CatalogRef.Peripherals - link to the equipment 
//                              used to open the shift
//  Result - Structure - the result of opening a cash shift:
//   * Result - Boolean - The result of the shift-end closing
//   * ErrorDescription - String - error description
//   * CREShiftNumber - String
//   * KKTReceiptNumber - String
//   * CREParameters - See PeripheralsReceiptPrintersClientServer.GeneralFiscalStorageParameters.
Procedure AfterOpeningCashShift(DeviceID, Result) Export
	
EndProcedure

// It is called after the POS shift is closed
// Parameters:
//  DeviceID - CatalogRef.Peripherals - A link to the equipment 
//                              on which the shift is being shift-end closing is being performed
//  Result - Structure - the result of closing the cash shift:
//   * Result - Boolean - The result of the shift-end closing
//   * ErrorDescription - String - error description
//   * CashRegisterShift - DocumentRef.CashRegisterShift
//   * CREShiftNumber - String
//   * KKTReceiptNumber - String
Procedure AfterCashShiftCloses(DeviceID, Result) Export  
	
	RegisterShiftState = RetailSales.GetCashShiftState(DeviceID, Result.CashRegisterShift);
	If Not ValueIsFilled(RegisterShiftState.CashRegister) Then
		Return;
	EndIf;
	
	CollectionCompleted = RetailSales.PerformAutomaticCashCollection(RegisterShiftState.CashRegister, False);
	
	ErrorDescription = "";
	RetailSales.GenerateDocumentsForCashShiftClosingOperation(RegisterShiftState, ErrorDescription);  
	
EndProcedure

// Overrides the available CCT for receipt fiscalization.
//
// Parameters:
//  ReceiptDetails_ - Structure - details of the fiscal receipt
//  ListOfDevices - Array of Arbitrary - list of available CCTS for fiscalization
//  CREDeviceID - CatalogRef.Peripherals - the selected CCPS for fiscal
//  StandardProcessing - Boolean
//
Procedure AvailableCCTForFiscalization(ReceiptDetails_, ListOfDevices, CREDeviceID, StandardProcessing) Export

EndProcedure

#EndRegion


// Fills in information about the organization using a link of the Definable Types type.Organization, to display 
// a fiscalized receipt on the view form, if the Standard Processing flag is set,
// then the Organization value representation will be used as the name.
//
// Parameters:
//  Organization - DefinedType.CompanyCEL
//  CompanyInformation - Structure:
//        * Description - String
//  StandardProcessing - Boolean
//
Procedure CompanyInformation(Organization, CompanyInformation, StandardProcessing) Export
	
EndProcedure

#Region WorkingWithInstanceForm

// Additional redefinable actions with the managed form in the hardware Instance
// when the "join Server" event occurs.
//
// Parameters:
//  Object - CatalogObject.Peripherals - object of the connected equipment.
//  ThisForm - ClientApplicationForm - Hardware configuration form
//  Cancel - Boolean - The failure of the creation
//  Parameters - Structure - Operation parameters
//  StandardProcessing - Boolean - Standard treatment
//
Procedure HardwareInstanceWhenCreatedOnServer(Object, ThisForm, Cancel, Parameters, StandardProcessing) Export
	Item = ThisForm.Items.Add("ExchangeRule", Type("FormField"), );
	Item.Type = FormFieldType.InputField;
	Item.DataPath = "Object.ExchangeRule";
	
	// Access to the node is available only for the corresponding equipment.
	If Object.EquipmentType = Enums.PeripheralTypes.LabelPrintingScales Then
		
		ChoiceParameters = New Array;
		NewParameter1 = New ChoiceParameter("Filter.PeripheralType", Enums.PeripheralTypes.LabelPrintingScales);
		ChoiceParameters.Add(NewParameter1);
		
		ParametersForSelectingExchangeRule = New FixedArray(ChoiceParameters);
		
		ThisForm.Items.ExchangeRule.Visible = True;
		If ValueIsFilled(ParametersForSelectingExchangeRule) Then
			ThisForm.Items.ExchangeRule.ChoiceParameters = ParametersForSelectingExchangeRule;
		EndIf;
	Else
		ThisForm.Items.ExchangeRule.Visible = False;
	EndIf;
EndProcedure

// Additional redefinable actions with the managed form in the hardware Instance
// when the event "due to server" occurs.
//
// Parameters:
//  CurrentObject - CatalogObject.Peripherals - object of the connected equipment.
//  ThisForm - ClientApplicationForm - Hardware configuration form
//
Procedure HardwareInstanceWhenReadingOnServer(CurrentObject, ThisForm) Export

EndProcedure

// Additional overridable actions with the managed form in the hardware Instance
// during the "re-write to Server" event.
//
// Parameters:
//  Cancel - Boolean - The failure of the operation
//  CurrentObject - CatalogObject.Peripherals - object of the connected equipment.
//  WriteParameters - Structure - Operation parameters
//
Procedure HardwareInstanceBeforeWritingToServer(Cancel, CurrentObject, WriteParameters) Export

EndProcedure

// Additional redefined actions with the managed form in the hardware Instance
// in the event "write to Server".
//
// Parameters:
//  Cancel - Boolean - The failure of the operation
//  CurrentObject - CatalogObject.Peripherals - object of the connected equipment.
//  WriteParameters - Structure - Operation parameters
//
Procedure HardwareInstanceWhenWritingToServer(Cancel, CurrentObject, WriteParameters) Export

EndProcedure

// Additional actions that can be overridden with a controlled shape in the Instance of equipment
// when the event is "Poltavavneshservice".
//
// Parameters:
//  CurrentObject - CatalogObject.Peripherals - object of the connected equipment.
//  WriteParameters - Structure - Operation parameters
//
Procedure HardwareInstanceAfterWritingToServer(CurrentObject, WriteParameters) Export

EndProcedure

// Additional redefinable actions with the managed form in the hardware Instance
// when the event "processing checkfillings on the Server".
//
// Parameters:
//  Object - CatalogObject.Peripherals - object of the connected equipment.
//  ThisForm - ClientApplicationForm - Hardware configuration form
//  Cancel - Boolean - The failure of the creation
//  CheckedAttributes - Structure - Verified Bank details
//
Procedure HardwareInstanceHandlingFillCheckOnServer(Object, ThisForm, Cancel, CheckedAttributes) Export

EndProcedure

// Additional redefinable actions with a managed form in the Fiscal operations Instance
// when the "join Server" event occurs.
//
// Parameters:
//  Record - InformationRegisterRecord.FiscalTransactions - Record fiscal transactions.
//  ThisForm - ClientApplicationForm - Hardware configuration form
//  Cancel - Boolean - The failure of the creation
//  Parameters - Structure - Operation parameters
//  StandardProcessing - Boolean - Standard treatment
//
Procedure InstanceFiscalOperationsWhenCreatedOnServer(Record, ThisForm, Cancel, Parameters, StandardProcessing) Export

EndProcedure

// Additional redefinable actions with a managed form in the Fiscal operations Instance
// when the "join Server" event occurs.
//
// Parameters:
//  Record - InformationRegisterRecord.FiscalTransactions - Record fiscal transactions.
//  ThisForm - ClientApplicationForm - Hardware configuration form
//  Cancel - Boolean - The failure of the creation
//  StandardProcessing - Boolean - Standard treatment
//
Procedure PaymentTransactionsInstanceWhenCreatedOnServer(Record, ThisForm, Cancel, StandardProcessing) Export

EndProcedure

#EndRegion

#Region WorkingWithListForm

// Additional redefinable actions with the managed form in the Fiscal operations List
// when the "join Server" event occurs.
//
// Parameters:
//  ThisForm - ClientApplicationForm - Hardware configuration form
//  Cancel - Boolean - The failure of the creation
//  Parameters - Structure - Operation parameters
//  StandardProcessing - Boolean - Standard treatment
//
Procedure ListOfFiscalTransactionsWhenCreatedOnServer(ThisForm, Cancel, Parameters, StandardProcessing) Export

EndProcedure

// Additional overridable actions with the managed form in the List of payment transactions
// at the event "Joining the Server".
//
// Parameters:
//  ThisForm - ClientApplicationForm - Equipment configuration form.
//  Cancel - Boolean - Creation failure.
//  Parameters - Structure - The operation parameters.
//  StandardProcessing - Boolean - Standard treatment.
//
Procedure ListOfPaymentTransactionsWhenCreatedOnServer(ThisForm, Cancel, Parameters, StandardProcessing) Export

EndProcedure

// It is required to determine in which places of the configuration the connected equipment can be used
//
// Parameters:
//  Peripherals - CatalogRef.Peripherals 
//  ShouldOutputWarning - Boolean - issue a warning when an item of equipment is disabled or marked for deletion.
//  WarningText - String - warning text.
//  StandardProcessing - Boolean - perform standard processing, issue a warning.
Procedure DeterminePossibilityOfEquipmentShutdown(Peripherals, ShouldOutputWarning, WarningText, StandardProcessing) Export
	
EndProcedure

#EndRegion 

// Handler of the personal data filling event.
//
// Parameters:
//  PersonalDetails - Structure - The returned parameter, personal data.
//  PersonalDataSubject - DefinedType.PersonalDataSubjectCEL - the subject of personal data. 
//  PersonalDataType - EnumRef.TypesOfPersonalDataOfTheCCT - Type of personal data
//  OnDate - Date - The date on which it is necessary to receive personal data
//
Procedure ProcessingOfPersonalDataFilling(PersonalDetails, PersonalDataSubject, PersonalDataType, OnDate) Export
	
	
EndProcedure

#Region SaleWithCashIssue

// The procedure where it is required to check the sufficiency of cash in the cash register
//
// Parameters:
//   CCTID - CatalogRef.Peripherals - link to the CTT element
//   Sum - Number - required amount for cash withdrawal
//   Cancel - Boolean - if set to True, then cash withdrawal will not be carried out
Procedure CheckSufficiencyOfCash(CCTID, Sum, Cancel) Export
	
EndProcedure

#EndRegion


#Region ObsoleteProceduresAndFunctions

#Region WorkingWithFormElement

// Deprecated: no longer in use.
// Additional overridable actions with the form element 
// are used to take into account the specifics of the visual display, depending on the type of client.
//
// Parameters:
//  Control - InterfaceControlItem - Control element.
//  StandardProcessing - Boolean - Standard treatment.
//
Procedure PrepareControl(Control, StandardProcessing) Export
	
EndProcedure

#EndRegion

#EndRegion

#EndRegion