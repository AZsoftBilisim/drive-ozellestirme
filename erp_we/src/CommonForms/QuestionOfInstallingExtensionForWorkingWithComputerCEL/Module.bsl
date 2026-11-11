///////////////////////////////////////////////////////////////////////////////////////////////////////
// Copyright (c) 2024, 1C-Soft LLC
// All rights reserved. This program and accompanying materials are provided 
// in accordance with the terms of the Attribution 4.0 International (CC BY 4.0) license
// The license text is available at the link:
// https://creativecommons.org/licenses/by/4.0/legalcode
///////////////////////////////////////////////////////////////////////////////////////////////////////

#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	If Not IsBlankString(Parameters.SuggestionText) Then
		Items.DecorationNote.Title = Parameters.SuggestionText
			+ Chars.LF
			+ NStr("vi = 'Cài đặt?';
					|ru = 'Установить?';
					|en = 'Do you want to install it?'; fa = 'Do you want to install it?';
					|it = 'Установить?';
					|pl = 'Do you want to install it?';
					|tr = 'Yapılandırılsın mı?'");
		
	EndIf;
	
	
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure InstallAndContinue(Command)
	
	Close(DialogReturnCode.Yes);
	
EndProcedure

&AtClient
Procedure ContinueWithoutInstalling(Command)
	
	Close(DialogReturnCode.Cancel);
	
EndProcedure

#EndRegion

#Region Private


#EndRegion
