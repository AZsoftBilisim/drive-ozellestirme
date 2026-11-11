#Region Public

// Registers billed configuration services from the Structure.
// @skip-warning EmptyMethod - Overridable method.
//
// Parameters:
//  ServiceProviders - Array of Structure - describes the service provider:
// 	 * Id - String - Service provider ID (type String - String(50)),
// 	 * Description - String - name of the service provider (type String - String(150)),
// 	 * Services - Array of Structure - provider services with required keys:
// 	   ** Id - String - Service ID (type String - String(50))
// 	   ** Description - String - service name (type String - String(150))
// 	   ** ServiceType - EnumRef.ServicesTypes - type of service.
//
Procedure OnCreateServicesList(ServiceProviders) Export
	
	
	
EndProcedure

// Event that is called when the license activation is changed.
// @skip-warning EmptyMethod - Overridable method.
//
// Parameters:
// 	LicenseInformation - Structure - License Information:
// 	 * OperationService - CatalogRef.SaaSServices - service.
// 	 * LicenseName - String - license name.
// 	 * LicenseContext - String - the context of the license.
// 	LicenseActivated - Boolean - the license is activated or deactivated.
//
Procedure OnChangeLicenseActivationState(LicenseInformation, LicenseActivated) Export
	
EndProcedure

// Event that is triggered when updating available licenses.
// @skip-warning EmptyMethod - Overridable method.
//
// Parameters:
//	LicenseParameters - Structure - corresponds to the composition of Attributes, measurements and resources of the pc "available licenses":
// 	 * SubscriptionID - UUID - internal ID of the subscription.
// 	 * OperationService - CatalogRef.SaaSServices - service.
// 	 * ValidityStartDate - Date - subscription start date.
// 	 * ValidityEndDate - Date - subscription expiration date.
// 	 * LicensesCount - Number - number of licenses.
// 	 * SubscriptionNumber - String - subscription number.
// 	 * ChangeDate - Date - date of change.
//
Procedure OnUpdateAvailableLicenses(LicenseParameters) Export
	
	
EndProcedure

// Event that is triggered when available licenses are deleted.
// @skip-warning EmptyMethod - Overridable method.
//
// Parameters:
//	LicenseParameters - See OnUpdateAvailableLicenses.LicenseParameters
//
Procedure OnDeleteAvailableLicenses(LicenseParameters) Export
	
	
EndProcedure

#EndRegion
