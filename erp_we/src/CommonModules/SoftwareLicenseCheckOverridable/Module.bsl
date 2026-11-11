///////////////////////////////////////////////////////////////////////////////////////////////////////
// Copyright (c) 2025, OOO 1C-Soft
// All rights reserved. This software and the related materials 
// are licensed under a Creative Commons Attribution 4.0 International license (CC BY 4.0).
// To view the license terms, follow the link:
// https://creativecommons.org/licenses/by/4.0/legalcode
///////////////////////////////////////////////////////////////////////////////////////////////////////
//

#Region Public

// Redefines the standard behavior of the subsystem.
//
// Parameters:
//  Settings - Structure:
//   * MustCheckLegitimateSoftware - Boolean - By default, it is set to "True" for new configuration versions.
//        It is set to "False" for basic versions, SaaS mode, and subordinate DIB nodes.
//        Set to "False" to disable the license verification during updates. 
//        For example, in case the infobase is rented.
//
Procedure OnDefineSettings(Settings) Export
	
EndProcedure

#EndRegion
