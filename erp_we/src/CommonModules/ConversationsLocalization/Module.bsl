///////////////////////////////////////////////////////////////////////////////////////////////////////
// Copyright (c) 2025, OOO 1C-Soft
// All rights reserved. This software and the related materials 
// are licensed under a Creative Commons Attribution 4.0 International license (CC BY 4.0).
// To view the license terms, follow the link:
// https://creativecommons.org/licenses/by/4.0/legalcode
///////////////////////////////////////////////////////////////////////////////////////////////////////
//

#Region Public

// Allows overriding the list of available integrations considering regional aspects.
// 
// Parameters:
//  ExternalSystemsTypes - Array of String - "Telegram", "WebChat", "Webhook", etc.
//
Procedure OnDefineAvailableIntegrations(ExternalSystemsTypes) Export
	
	
EndProcedure

// Allows specifying custom instructions for connecting integrations with
// various external systems in a specific country or region.
// 
// Parameters:
//  Instruction - FormattedString
//  ExternalSystemType - String - "Telegram", "WebChat" or "Webhook".
//
Procedure OnFillInstructionOnIntegrationConnect(Instruction, Val ExternalSystemType) Export
	
	
EndProcedure

#EndRegion

