///////////////////////////////////////////////////////////////////////////////////////////////////////
// Copyright (c) 2025, OOO 1C-Soft
// All rights reserved. This software and the related materials 
// are licensed under a Creative Commons Attribution 4.0 International license (CC BY 4.0).
// To view the license terms, follow the link:
// https://creativecommons.org/licenses/by/4.0/legalcode
///////////////////////////////////////////////////////////////////////////////////////////////////////
//

#Region Public

// Start connection of the Collaboration system.
//
// Parameters:
//   CompletionDetails - CallbackDescription - Notification to show after the connection form closes. 
//                                             Notification parameters:
//                          * Result - Undefined
//                          * AdditionalParameters - Undefined
//                                                    - Structure
//
Procedure ShowConnection(CompletionDetails = Undefined) Export
	ConversationsInternalClient.ShowConnection(CompletionDetails);
EndProcedure

// Start disconnection of the Collaboration system.
//
Procedure ShowDisconnection() Export
	ConversationsInternalClient.ShowDisconnection();
EndProcedure

// Returns True if the Collaboration System is enabled and available. 
//
// Makes a server call to ensure getting the actual status in case
// registration data in the infobase were modified by the method 
// "CollaborationSystem.SetInfoBaseRegistrationData".
// 
// Returns:
//   Boolean
//
Function ConversationsAvailable() Export
	
	Return ConversationsInternalServerCall.Connected2();
	
EndFunction

#EndRegion