///////////////////////////////////////////////////////////////////////////////////////////////////////
// Copyright (c) 2025, OOO 1C-Soft
// All rights reserved. This software and the related materials 
// are licensed under a Creative Commons Attribution 4.0 International license (CC BY 4.0).
// To view the license terms, follow the link:
// https://creativecommons.org/licenses/by/4.0/legalcode
///////////////////////////////////////////////////////////////////////////////////////////////////////
//

#Region Public

// I called to open the form to search for add-ins over the Internet.
//
// Parameters:
//  Notification - CallbackDescription
//  Context - Structure:
//      * ExplanationText - String
//      * Id - String
//      * Version        - String
//      * AutoUpdate - Boolean
//
Procedure OnSearchAddInsOnPortal(Notification, Context) Export
	
	
EndProcedure

// Called to open the form for updating add-ins over the Internet.
//
// Parameters:
//  Notification - CallbackDescription
//  AddInsToUpdate - Array of CatalogRef.AddIns
//
Procedure OnUpdateAddInsFromPortal(Notification, AddInsToUpdate) Export
	
	
EndProcedure

#EndRegion
