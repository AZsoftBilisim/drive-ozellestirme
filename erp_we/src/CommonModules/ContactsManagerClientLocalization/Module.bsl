///////////////////////////////////////////////////////////////////////////////////////////////////////
// Copyright (c) 2025, OOO 1C-Soft
// All rights reserved. This software and the related materials 
// are licensed under a Creative Commons Attribution 4.0 International license (CC BY 4.0).
// To view the license terms, follow the link:
// https://creativecommons.org/licenses/by/4.0/legalcode
///////////////////////////////////////////////////////////////////////////////////////////////////////
//

#Region Public

// Determines the URL of the mapping service.
// 
// Parameters:
//  MapServiceName - String - Mapping service name.
//  ResourceAddress - String - URL of the mapping service. This parameter must include %1, 
//          which will be replaced with the searched address for display on the map.
//          For example, "https://www.openstreetmap.org/search?query=%1".
//
//  Example:
//     If MappingServiceName = "OpenStreetMap" Then
//         ResourceAddress = "https://www.openstreetmap.org/search?query=%1";
//     EdnIf;
//
Procedure OnDefineMapServiceURL(MapServiceName, ResourceAddress) Export
	
	
EndProcedure

// Show the address on Yandex.Maps.
// 
// Parameters:
//  ContactInformation - See ContactsManagerClient.ParameterContactInfoForCommandExecution
//  AdditionalParameters - See ContactsManagerClient.CommandRuntimeAdditionalParameters
//
Procedure ShowAddressOnYandexMaps(ContactInformation, AdditionalParameters) Export
	
	
EndProcedure

// Determines the order of the address fields. 
// It is called only in the international library edition.
// 
// Parameters:
//  FieldsOrder - Array - A list of roles in the proper order. For example, "area", "ZIPcode", "city".
//  Country - CatalogRef.WorldCountries - Reference to the catalog of countries
//  IncludeCountryInPresentation - Boolean - Set to "True" if the contact information kind has a flag indicating that
//                                           the country should be included in the address presentation.
//
Procedure OnDefineAddressFieldsOrder(FieldsOrder, Country, IncludeCountryInPresentation) Export
	
	
EndProcedure

#EndRegion