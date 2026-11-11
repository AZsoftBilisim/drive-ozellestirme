///////////////////////////////////////////////////////////////////////////////////////////////////////
// Copyright (c) 2025, OOO 1C-Soft
// All rights reserved. This software and the related materials 
// are licensed under a Creative Commons Attribution 4.0 International license (CC BY 4.0).
// To view the license terms, follow the link:
// https://creativecommons.org/licenses/by/4.0/legalcode
///////////////////////////////////////////////////////////////////////////////////////////////////////
//

#Region FormEventHandlers

&AtClient
Procedure BeforeWrite(Cancel, WriteParameters)
	
	If Record.Id <> IDAsString Then
		Record.Id = IDAsString;
	EndIf;
	
EndProcedure

&AtClient
Procedure OnOpen(Cancel)
	
	IDAsString = Record.Id;
	
EndProcedure

#EndRegion