///////////////////////////////////////////////////////////////////////////////////////////////////////
// Copyright (c) 2025, OOO 1C-Soft
// All rights reserved. This software and the related materials 
// are licensed under a Creative Commons Attribution 4.0 International license (CC BY 4.0).
// To view the license terms, follow the link:
// https://creativecommons.org/licenses/by/4.0/legalcode
///////////////////////////////////////////////////////////////////////////////////////////////////////
//

#Region Private

// Returns command details by form item name.
Function CommandDetails(CommandNameInForm, SettingsAddress) Export
	Return AttachableCommands.CommandDetails(CommandNameInForm, SettingsAddress);
EndFunction

Function MainCommandsMarks(Val Ref, Val CommandsMarked) Export
	
	Result = New Structure;
	If Common.SubsystemExists("StandardSubsystems.Print") Then
		ModulePrintManager = Common.CommonModule("PrintManagement");
		ModulePrintManager.OnUpdateMainCommandsMarks(Ref, CommandsMarked, Result);
	EndIf;
	Return Result;
	
EndFunction

// Checks the posting status of the passed documents and returns the unposted documents.
//
// Parameters:
//  Var_Documents - Array of DocumentRef - Documents to check.
//
// Returns:
//  Structure:
//    * UnpostedDocuments - Array of DocumentRef
//    * HasPostingRight - Boolean
//
Function DocsPostInfoRecords(Val Var_Documents) Export
	
	Result = New Structure;
	Result.Insert("UnpostedDocuments", 
		Common.CheckDocumentsPosting(Var_Documents));
	Result.Insert("HasPostingRight", 
		StandardSubsystemsServer.HasRightToPost(Result.UnpostedDocuments));
	Return Result;
	
EndFunction

#EndRegion
