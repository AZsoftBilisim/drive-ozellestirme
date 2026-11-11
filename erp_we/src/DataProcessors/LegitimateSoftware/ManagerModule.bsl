///////////////////////////////////////////////////////////////////////////////////////////////////////
// Copyright (c) 2025, OOO 1C-Soft
// All rights reserved. This software and the related materials 
// are licensed under a Creative Commons Attribution 4.0 International license (CC BY 4.0).
// To view the license terms, follow the link:
// https://creativecommons.org/licenses/by/4.0/legalcode
///////////////////////////////////////////////////////////////////////////////////////////////////////
//

#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region Internal

Function MustCheckLegitimateSoftware() Export
	
	Result = True;
	If StandardSubsystemsServer.IsBaseConfigurationVersion() 
		Or Common.DataSeparationEnabled()
		Or Common.IsSubordinateDIBNode() Then
		Return False;
	EndIf;
	
	Settings = New Structure;
	Settings.Insert("MustCheckLegitimateSoftware", Result);
	SoftwareLicenseCheckOverridable.OnDefineSettings(Settings);
	
	Result = Settings.MustCheckLegitimateSoftware;
	Return Result;
	
EndFunction

#EndRegion

#EndIf
