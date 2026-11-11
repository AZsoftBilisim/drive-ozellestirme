///////////////////////////////////////////////////////////////////////////////////////////////////////
// Copyright (c) 2025, OOO 1C-Soft
// All rights reserved. This software and the related materials 
// are licensed under a Creative Commons Attribution 4.0 International license (CC BY 4.0).
// To view the license terms, follow the link:
// https://creativecommons.org/licenses/by/4.0/legalcode
///////////////////////////////////////////////////////////////////////////////////////////////////////
//

#Region Private

Function AreClientNotificationsAvailable() Export
	
	If IsForTestingOnly() Then
		Return False;
	EndIf;
	
	SystemInfo = New SystemInfo;
	Version = SystemInfo.AppVersion;
	
	Return CommonClientServer.CompareVersions(Version, "8.3.27.1935") >= 0
	      And CommonClientServer.CompareVersions(Version, "8.5.1.0") < 0
	    Or CommonClientServer.CompareVersions(Version, "8.5.1.1119") >= 0;
	
EndFunction

Function IsForTestingOnly()
	
// ACC:547-off - Temporary solution for testing purposes.
#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then
	DataSeparationEnabled = Common.DataSeparationEnabled();
	CurrentSessionDate = CurrentSessionDate();
#Else
	DataSeparationEnabled = CommonClient.DataSeparationEnabled();
	CurrentSessionDate = CommonClient.SessionDate();
#EndIf
// ACC:547-on
	
	Return DataSeparationEnabled And CurrentSessionDate < '202601130900';
	
EndFunction

Function ServerNotificationsNotificationsKey() Export
	
	Return "StandardSubsystems.Core.ServerNotifications";
	
EndFunction

#EndRegion
