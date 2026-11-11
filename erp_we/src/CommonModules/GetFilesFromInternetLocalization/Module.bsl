///////////////////////////////////////////////////////////////////////////////////////////////////////
// Copyright (c) 2025, OOO 1C-Soft
// All rights reserved. This software and the related materials 
// are licensed under a Creative Commons Attribution 4.0 International license (CC BY 4.0).
// To view the license terms, follow the link:
// https://creativecommons.org/licenses/by/4.0/legalcode
///////////////////////////////////////////////////////////////////////////////////////////////////////
//

#Region Public

// Called during the internet connectivity check. A custom connectivity check URL can be specified.
//
// Parameters:
//  ServerAddresses - String - Set the server address for connection testing. 
//                           By default, "google.com".
//
Procedure OnGetChecksumServerAddress(ServerAddresses) Export
	
	
EndProcedure

// Called during an internet availability check and allows adding detailed information about a known issue.
//
// Parameters:
//  LongDesc - Array of String - Brief details about an error that occurred during the internet availability check.
//  ErrorText - See GetFilesFromInternet.ConnectionDiagnostics
//
Procedure OnGenerateMessageAboutKnownIssue(LongDesc, ErrorText) Export
	
	If StrFind(Upper(ErrorText), Upper("Deleted node not passed_ checking2")) > 0 Then // ACC:1297 - A non-localizable piece of information about an exception error.
	EndIf;
	
EndProcedure


#EndRegion
