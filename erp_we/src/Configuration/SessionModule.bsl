///////////////////////////////////////////////////////////////////////////////////////////////////////
// Copyright (c) 2019, 1C-Soft LLC
// All rights reserved. This program and accompanying materials are provided 
// in accordance with the terms of the Attribution 4.0 International (CC BY 4.0) license
// The license text is available at the link:
// https://creativecommons.org/licenses/by/4.0/legalcode
///////////////////////////////////////////////////////////////////////////////////////////////////////
//

#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region EventHandlers

Procedure SessionParametersSetting(SessionParametersNames)
		
	// StandardSubsystems
#If Not MobileStandaloneServer Then
	StandardSubsystemsServer.SessionParametersSetting(SessionParametersNames);
#Else
	MobileWarehouseKeeperWorkspace.SessionParametersSetting(SessionParametersNames);
#EndIf
	// End StandardSubsystems

EndProcedure

#EndRegion

#EndIf