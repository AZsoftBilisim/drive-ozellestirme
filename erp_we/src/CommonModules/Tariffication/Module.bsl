////////////////////////////////////////////////////////////////////////////////
// The General Billing module.

// Obtaining/releasing licenses for unique services is carried out in two stages:
// 1) First, a request for obtaining/releasing a license is made (for example, at the beginning of a transaction),
//    and a unique transaction identifier is transmitted to the billing system.
// 2) Then either confirmation or cancellation of the previously requested operation is performed
//    (for example, before completing a transaction).
//
// Important! The "lifetime" of an incomplete operation in the BTS billing system is 15 minutes,
// after this time, incomplete operations are automatically canceled.

#Region Public

// Returns a link to the service by its ID and the ID of the service provider.
// @skip-warning EmptyMethod - a feature of the implementation.
//
// Parameters:
//  ServiceID - String - service ID.
//  VendorID - String - provider id.
//	RaiseException1 - Boolean - flag to raise an exception if the service is not found
//
// Returns:
//  CatalogRef.SaaSServices - link to the service.
//
Function ServiceByIDAndProviderID(Val ServiceID, Val VendorID, RaiseException1 = True) Export
EndFunction

// Checks whether the service billing system allows the use of the specified unlimited service
// to the specified user.
// @skip-warning EmptyMethod - a feature of the implementation.
//
// Parameters:
//  VendorID - String - unique string identifier (code) of the service provider in the service.
//  ServiceID - String - unique string identifier (code) of the service in the service.
//
// Returns:
//  Boolean - verification result (True = license registered).
//
Function UnlimitedServiceLicenseRegistered(VendorID, ServiceID) Export
EndFunction

// Checks whether the specified
// license identifier for using the specified unique limited service is registered in the service billing system.
// @skip-warning EmptyMethod - a feature of the implementation.
//
// Parameters:
//  VendorID - String - unique string identifier (code) of the service provider in the service.
//  ServiceID - String - unique string identifier (code) of the service in the service.
//  LicenseName - String - String (200) a unique string representation of the license that is UNDERSTANDABLE to the USER.
//  LicenseContext - String - String (200), the context of the license.
//
// Returns:
//  Boolean - verification result (True = license registered).
//
Function UniqueServiceLicenseRegistered(VendorID, ServiceID, LicenseName, LicenseContext = "") Export
EndFunction

// Attempts to obtain a license to use a unique service in the service billing system.
// @skip-warning EmptyMethod - a feature of the implementation.
//
// Parameters:
//  VendorID - String - unique string identifier (code) of the service provider in the service.
//  ServiceID - String - unique string identifier (code) of the service in the service.
//  LicenseName - String - String (200) a unique string representation of the license that is UNDERSTANDABLE to the USER.
//  OperationID - UUID - unique ID of the operation, required for confirmation.
//  LicenseContext - String - String (200) license context, indicating the uniqueness of the license.
//
// Returns:
//  Structure - with properties:
//    * Result - Boolean - execution result (True = license successfully obtained).
//    * AvailableLicenses_ - Number - the maximum number of licenses available to the subscriber for the specified service (if "-1", it means an unlimited number).
//    * BusyLicenses - Number - the number of licenses already received (used) for the service.
//    * NumberOfLicenses - Number - the number of free licenses (if "-1", it means an unlimited number).
//
Function BorrowUniqueServiceLicense(VendorID, ServiceID, LicenseName, OperationID, LicenseContext = "") Export
EndFunction

// Attempts to release a license for a unique service in the service billing system.
// @skip-warning EmptyMethod - a feature of the implementation.
//
// Parameters:
//  VendorID - String - unique string identifier (code) of the service provider in the service.
//  ServiceID - String - unique string identifier (code) of the service in the service.
//  LicenseName - String - String (200) a unique string representation of the license that is UNDERSTANDABLE to the USER.
//  OperationID - UUID - unique ID of the operation, required for confirmation.
//  DataAreaCode - Number - code of the data area (if we call the function from an undivided session).
//  LicenseContext - String - String (200) license context, indicating the uniqueness of the license.
//  RemoveLicenseInAllDataAreas - Boolean - delete or not this license by data area.
//
// Returns:
//  Boolean - execution result (True = license successfully released, False - this license was not found).
//
Function ReleaseLicenseForUniqueService(VendorID, ServiceID, LicenseName, 
	OperationID, DataAreaCode = Undefined,
	LicenseContext = "", RemoveLicenseInAllDataAreas = False) Export
EndFunction

// Attempts to obtain licenses to use the limited service in the service.
// @skip-warning EmptyMethod - a feature of the implementation.
//
// Parameters:
//  VendorID - String - unique string identifier (code) of the service provider in the service.
//  ServiceID - String - unique string identifier (code) of the service in the service.
//  LicensesCount - Number - required number of licenses (natural number, 10 digits).
//  DataAreaCode - Number - code of the data area (if we call the function from an undivided session).
//
// Returns:
//  Structure - with properties:
//    * Result - Boolean - execution result (True = license successfully obtained).
//    * AvailableLicenses_ - Number - the maximum number of licenses available to the subscriber for the specified service (if "-1", it means an unlimited number).
//    * BusyLicenses - Number - the number of licenses already received (used) for the service.
//    * NumberOfLicenses - Number - the number of free licenses (if "-1", it means an unlimited number).
//
Function ObtainingLimitedServiceLicense(VendorID, ServiceID, LicensesCount, DataAreaCode = Undefined) Export
EndFunction

// Attempts to release licenses for the use of a limited service in the service.
// @skip-warning EmptyMethod - a feature of the implementation.
//
// Parameters:
//  VendorID - String - unique string identifier (code) of the service provider in the service.
//  ServiceID - String - unique string identifier (code) of the service in the service.
//  LicensesCount - Number - required number of licenses (natural number, 10 digits).
//  DataAreaCode - Number - code of the data area (if we call the function from an undivided session).
//
// Returns:
//  Boolean - execution result (True = license successfully released).
//
Function ReleaseLimitedServiceLicenses(VendorID, ServiceID, LicensesCount, DataAreaCode = Undefined) Export
EndFunction

// Performs confirmation of the previously requested license of operation (receipt or release).
// @skip-warning EmptyMethod - a feature of the implementation.
//
// Parameters:
//  OperationID - UUID - ID of the operation that was passed when the operation was requested.
//
// Returns:
//  Boolean - the result of the operation (True = operation confirmed).
//
Function ConfirmOperation(OperationID) Export
EndFunction

// Cancels a previously requested license of operation (receipt or release).
// @skip-warning EmptyMethod - a feature of the implementation.
//
// Parameters:
//  OperationID - UUID - ID of the operation that was passed when the operation was requested.
//
// Returns:
//    Boolean - the result of the operation (True = operation canceled).
//
Function CancelOperation(OperationID) Export
EndFunction

// Attempts to obtain the number of free licenses for using a unique service in the service billing system.
// @skip-warning EmptyMethod - a feature of the implementation.
//
// Parameters:
//  VendorID - String - unique string identifier (code) of the service provider in the service.
//  ServiceID - String - unique string identifier (code) of the service in the service.
//
// Returns:
//  Structure - with keys:
//    * AvailableLicenses_ - Number - the maximum number of licenses available to the subscriber for the specified service (if "-1", it means an unlimited number).
//    * BusyLicenses - Number - the number of licenses already received (used) for the service.
//    * NumberOfLicenses - Number - the number of free licenses (if "-1", it means an unlimited number).
//
Function NumberOfLicensesForUniqueService(VendorID, ServiceID) Export
EndFunction

// Attempts to obtain the number of licenses for a limited service in the service.
// @skip-warning EmptyMethod - a feature of the implementation.
//
// Parameters:
//  VendorID - String - unique string identifier (code) of the service provider in the service.
//  ServiceID - String - unique string identifier (code) of the service in the service.
//  DataAreaCode - Number - code of the data area (if we call the function from an undivided session).
//
// Returns:
//  Structure - with keys:
//    * AvailableLicenses_ - Number - the maximum number of licenses available to the subscriber for the specified service (if "-1", it means an unlimited number).
//    * BusyLicenses - Number - the number of licenses already received (used) for the service.
//    * NumberOfLicenses - Number - the number of free licenses (if "-1", it means an unlimited number).
//
Function NumberOfLimitedServiceLicenses(VendorID, ServiceID, DataAreaCode = Undefined) Export
EndFunction

// Returns a flag indicating that the current session is blocked by billing.
// 
// Returns:
//  Boolean -
Function CurrentSessionBlocked() Export
	Return False;	
EndFunction

#EndRegion

#Region Internal

// See ExportImportDataOverridable.OnFillTypesExcludedFromExportImport.
// 
// Parameters:
// 	Types - See ExportImportDataOverridable.OnFillTypesExcludedFromExportImport.Types
// 
Procedure OnFillTypesExcludedFromExportImport(Types) Export
	
	Types.Add(Metadata.InformationRegisters.AvailableLicenses);
	Types.Add(Metadata.InformationRegisters.LockedLicenses);
	
	ExportImportData.AddTypeExcludedFromUploadingUploads(
		Types,
		Metadata.Catalogs.SaaSServices,
		ExportImportData.ActionWithLinksDoNotChange());	
	
	ExportImportData.AddTypeExcludedFromUploadingUploads(
		Types,
		Metadata.Catalogs.SaaSServicesSuppliers,
		ExportImportData.ActionWithLinksDoNotChange());	

	Types.Add(Metadata.Constants.UseTarifficationControl);
	
EndProcedure

// See ScheduledJobsOverridable.OnDefineScheduledJobSettings.
// @skip-warning EmptyMethod - a feature of the implementation.
// 
// Parameters:
// 	Settings - See ScheduledJobsOverridable.OnDefineScheduledJobSettings.Settings
//
Procedure OnDefineScheduledJobSettings(Settings) Export
EndProcedure

// See MessageInterfacesSaaSOverridable.FillInReceivedMessageHandlers.
// @skip-warning EmptyMethod - a feature of the implementation.
// 
// Parameters:
// 	HandlersArray - See MessageInterfacesSaaSOverridable.FillInReceivedMessageHandlers.HandlersArray
//
Procedure RecordingIncomingMessageInterfaces(HandlersArray) Export
EndProcedure

// See MessageInterfacesSaaSOverridable.FillInHandlersForSendingMessages.
// @skip-warning EmptyMethod - a feature of the implementation.
// 
// Parameters:
// 	HandlersArray - See MessageInterfacesSaaSOverridable.FillInHandlersForSendingMessages.HandlersArray
//
Procedure RecordingOutgoingMessageInterfaces(HandlersArray) Export
EndProcedure

// Handler for the event "When installing the end point of the Service Manager".
// @skip-warning EmptyMethod - a feature of the implementation.
//
Procedure OnSetServiceManagerEndpoint() Export
EndProcedure

// Adds the update handler procedures required by this subsystem.
// @skip-warning EmptyMethod - a feature of the implementation.
//
// Parameters:
//	Handlers - See InfobaseUpdate.NewUpdateHandlerTable
//
Procedure OnAddUpdateHandlers(Handlers) Export
EndProcedure

// Registers the billing services supported by this configuration in the MS.
// @skip-warning EmptyMethod - a feature of the implementation.
//
Procedure RegisterChargedServices_RoutineTask() Export
EndProcedure

// Tries to request unique service licenses from the Service Manager.
// @skip-warning EmptyMethod - a feature of the implementation.
//
Procedure RequestLicensesForUniqueServices_RoutineTask() Export
EndProcedure

// @skip-warning EmptyMethod - a feature of the implementation.
//
Procedure FormGetProcessing(Source, FormType, Parameters, SelectedForm, AdditionalInformation, StandardProcessing) Export
EndProcedure

#EndRegion
