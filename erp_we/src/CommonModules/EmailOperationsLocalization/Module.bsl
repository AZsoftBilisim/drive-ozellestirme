///////////////////////////////////////////////////////////////////////////////////////////////////////
// Copyright (c) 2025, OOO 1C-Soft
// All rights reserved. This software and the related materials 
// are licensed under a Creative Commons Attribution 4.0 International license (CC BY 4.0).
// To view the license terms, follow the link:
// https://creativecommons.org/licenses/by/4.0/legalcode
///////////////////////////////////////////////////////////////////////////////////////////////////////
//

#Region Public

// Sets the IP addresses of DNS servers that can be used to read MX records of domains.
//
// Parameters:
//  DNSServerAddresses - Array of String - IP addresses.
//  StandardProcessing - Boolean - Set to "False" if standard data processors should be excluded from the list.
//
Procedure OnGettingDNSServerAddresses(DNSServerAddresses, StandardProcessing) Export
	
	
EndProcedure

// Determines the address of the file containing email server connection settings.
//
// Parameters:
//  FileAddress - String - URL of the file containing email server connection settings.
//
Procedure OnReceivingAddressOfSettingsFile(FileAddress) Export
	
	
EndProcedure

// Determines the address of the file containing details of email server connection errors.
//
// Parameters:
//  FileAddress - String - URL of the file containing details of email server connection errors.
//
Procedure OnReceivingAddressOfFileWithDescriptionOfErrors(FileAddress) Export
	
	
EndProcedure

// Determines the address of an external resource for the security profile mechanism.
// See SafeModeManagerOverridable.OnFillPermissionsToAccessExternalResources.
//
// Parameters:
//  AddressOfExternalResource - String - Address of an external resource.
//
Procedure OnGettingAddressOfExternalResource(AddressOfExternalResource) Export
	
	
EndProcedure

#EndRegion