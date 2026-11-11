///////////////////////////////////////////////////////////////////////////////////////////////////////
// Copyright (c) 2025, OOO 1C-Soft
// All rights reserved. This software and the related materials 
// are licensed under a Creative Commons Attribution 4.0 International license (CC BY 4.0).
// To view the license terms, follow the link:
// https://creativecommons.org/licenses/by/4.0/legalcode
///////////////////////////////////////////////////////////////////////////////////////////////////////
//

#Region Internal

Function Connected2() Export
	
	Return ConversationsInternal.Connected2();
	
EndFunction

Procedure Unlock() Export 
	
	ConversationsInternal.Unlock();
	
EndProcedure

#EndRegion

#Region Private

Function AttachExternalDataProcessor(AddressInTempStorage) Export
	
	// ACC:552-off - An attaching attempt is made by a user who has the right to open external reports and data processors interactively.
	// ACC:556-off
	// ACC:553-off
	VerifyAccessRights("InteractiveOpenExtDataProcessors", Metadata);
	Return ExternalDataProcessors.Connect(AddressInTempStorage, , False);
	// ACC:552-on
	// ACC:556-on
	// ACC:552-on
	
EndFunction

Function AttachExternalReport(AddressInTempStorage) Export
	
	// ACC:552-off - An attaching attempt is made by a user who has the right to open external reports and data processors interactively.
	// ACC:556-off
	// ACC:553-off
	VerifyAccessRights("InteractiveOpenExtDataProcessors", Metadata);
	Return ExternalReports.Connect(AddressInTempStorage, , False);
	// ACC:552-on
	// ACC:556-on
	// ACC:552-on
	
EndFunction

Function CanOpenExternalReportsAndDataProcessors() Export

	Return AccessRight("InteractiveOpenExtDataProcessors", Metadata);

EndFunction

#EndRegion