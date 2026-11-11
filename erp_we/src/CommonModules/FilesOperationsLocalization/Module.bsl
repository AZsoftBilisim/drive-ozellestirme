///////////////////////////////////////////////////////////////////////////////////////////////////////
// Copyright (c) 2025, OOO 1C-Soft
// All rights reserved. This software and the related materials 
// are licensed under a Creative Commons Attribution 4.0 International license (CC BY 4.0).
// To view the license terms, follow the link:
// https://creativecommons.org/licenses/by/4.0/legalcode
///////////////////////////////////////////////////////////////////////////////////////////////////////
//

#Region Public

// Called to define the object's address in the cloud file service.
// 
// Parameters:
//  Service - String - Address of the cloud file service. For example, "https://dav.dropdav.com".
//  Href - String - Object's relative URL.
//  ObjectAddress - String - The return value. 
//
Procedure OnDefineAddressInCloudService(Val Service, Val Href, ObjectAddress) Export
	
	
EndProcedure

// Called to determine the list of cloud file services.
// 
// Parameters:
//  Services - ValueList:
//   * Value - Address of the cloud file service.
//   * Presentation - Name of the cloud file service.
//
Procedure OnDefineCloudServices(Services) Export
	
	
EndProcedure


#EndRegion