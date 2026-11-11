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
	
	If Not IsBlankString(Parameters.QuestionTitle) Then
		Title = Parameters.QuestionTitle;
	EndIf;
	
	If Not IsBlankString(Parameters.QueryText) Then
		Items.Explanation.Title = Parameters.QueryText;
	EndIf;
	
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure InstallAndContinue(Command)
	
	Close(True);
	
EndProcedure

&AtClient
Procedure Cancel(Command)
	
	Close(False);
	
EndProcedure

#EndRegion
