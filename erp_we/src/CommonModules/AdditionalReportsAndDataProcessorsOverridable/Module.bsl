///////////////////////////////////////////////////////////////////////////////////////////////////////
// Copyright (c) 2025, OOO 1C-Soft
// All rights reserved. This software and the related materials 
// are licensed under a Creative Commons Attribution 4.0 International license (CC BY 4.0).
// To view the license terms, follow the link:
// https://creativecommons.org/licenses/by/4.0/legalcode
///////////////////////////////////////////////////////////////////////////////////////////////////////
//

#Region Public

// Defines the sections where the additional data processor calling command is available.
// Add the metadata of sections
// where the commands are available to the Sections array.
// For the start page, specify AdditionalReportsAndDataProcessorsClientServer.StartPageName.
//
// Parameters:
//   Sections - Array of MetadataObject - section (subsystem) metadata.
//           - Array of String - for the start page.
//
Procedure GetSectionsWithAdditionalDataProcessors(Sections) Export
	
	Sections.Add(AdditionalReportsAndDataProcessorsClientServer.StartPageName());
	
	AdditionalReportsAndDataProcessorsLocalization.GetSectionsWithAdditionalDataProcessors(Sections);
	
	If Not GetFunctionalOption("BaseVersion") Then
		
		TMCommonUse.AddSubsystemToCollection(Sections, "Purchases");
		TMCommonUse.AddSubsystemToCollection(Sections, "CRMAndMarketing");
		TMCommonUse.AddSubsystemToCollection(Sections, "FinancialResultAndControlling");
		TMCommonUse.AddSubsystemToCollection(Sections, "Sales");
		TMCommonUse.AddSubsystemToCollection(Sections, "Warehouse");
		TMCommonUse.AddSubsystemToCollection(Sections, "TreasuryAndARAPAccounting");
		TMCommonUse.AddSubsystemToCollection(Sections, "BudgetingAndPlanning");
		TMCommonUse.AddSubsystemToCollection(Sections, "NonCurrentAssets");
		TMCommonUse.AddSubsystemToCollection(Sections, "Production");
		TMCommonUse.AddSubsystemToCollection(Sections, "InternationalFinancialAccounting");
	EndIf;
	
EndProcedure

// Defines the sections where the command that opens additional reports is available.
// Add the metadata of sections 
// where the commands are available to the Sections array.
// For the start page, specify AdditionalReportsAndDataProcessorsClientServer.StartPageName.
//
// Parameters:
//   Sections - Array of MetadataObject - section (subsystem) metadata.
//           - Array of String - for the start page.
//
Procedure GetSectionsWithAdditionalReports(Sections) Export
	// Coincide with the sections of additional treatments
	GetSectionsWithAdditionalDataProcessors(Sections);
	
EndProcedure

#EndRegion
