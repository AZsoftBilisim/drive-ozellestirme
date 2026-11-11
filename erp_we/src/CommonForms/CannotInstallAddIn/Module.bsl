///////////////////////////////////////////////////////////////////////////////////////////////////////
// Copyright (c) 2025, OOO 1C-Soft
// All rights reserved. This software and the related materials 
// are licensed under a Creative Commons Attribution 4.0 International license (CC BY 4.0).
// To view the license terms, follow the link:
// https://creativecommons.org/licenses/by/4.0/legalcode
///////////////////////////////////////////////////////////////////////////////////////////////////////
//

#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	Items.FormResumeInstallationAttempt.Visible = Not Parameters.AfterConnectionErrorOccurred;
	
EndProcedure

&AtClient
Procedure OnOpen(Cancel)
	
	Items.DecorationNote.Title = AddInsInternalClient.TextCannotInstallAddIn(
		Parameters.ExplanationText);
	
EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

&AtClient
Procedure DecorationNoteURLProcessing(Item, FormattedStringURL, StandardProcessing)
	
	StandardProcessing = False;
	
	FormParameters = New Structure;
	FormParameters.Insert("SupportedClients", Parameters.SupportedClients);
	
	OpenForm("CommonForm.SupportedClientApplications", FormParameters);
	
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure ResumeInstallationAttempt(Command)
	
	Close(True);
	
EndProcedure

#EndRegion

