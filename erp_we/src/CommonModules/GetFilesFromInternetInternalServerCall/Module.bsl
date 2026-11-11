///////////////////////////////////////////////////////////////////////////////////////////////////////
// Copyright (c) 2025, OOO 1C-Soft
// All rights reserved. This software and the related materials 
// are licensed under a Creative Commons Attribution 4.0 International license (CC BY 4.0).
// To view the license terms, follow the link:
// https://creativecommons.org/licenses/by/4.0/legalcode
///////////////////////////////////////////////////////////////////////////////////////////////////////
//

#Region Private

#Region ObsoleteProceduresAndFunctions

Function DownloadFile(URL, ReceivingParameters, WriteError1) Export
	
	Result = New Structure;
	Result.Insert("Status", False);
	Result.Insert("ErrorMessage");
	Result.Insert("Headers", New Map);
	Result.Insert("StatusCode", 403);
	
	Return Result;
	
EndFunction

Function ProxySettingsState() Export
	
	Return GetFilesFromInternetInternal.ProxySettingsState();
	
EndFunction

#EndRegion

#EndRegion
