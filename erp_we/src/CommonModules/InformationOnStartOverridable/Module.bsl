///////////////////////////////////////////////////////////////////////////////////////////////////////
// Copyright (c) 2025, OOO 1C-Soft
// All rights reserved. This software and the related materials 
// are licensed under a Creative Commons Attribution 4.0 International license (CC BY 4.0).
// To view the license terms, follow the link:
// https://creativecommons.org/licenses/by/4.0/legalcode
///////////////////////////////////////////////////////////////////////////////////////////////////////
//

#Region Public

// Determine information display settings on startup.
//
// Parameters:
//   Settings - Structure:
//       * Show - Boolean - Flag indicating whether to show information in the current session.
//           If True, information will be shown after logging in.
//           If False, information will be hidden.
//
Procedure DefineSettings(Settings) Export
	
	If Not GetFunctionalOption("TradeManagement") Then
		Settings.Show = False;
	EndIf; 
	
EndProcedure

#EndRegion
