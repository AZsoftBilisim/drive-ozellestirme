///////////////////////////////////////////////////////////////////////////////////////////////////////
// Copyright (c) 2025, OOO 1C-Soft
// All rights reserved. This software and the related materials 
// are licensed under a Creative Commons Attribution 4.0 International license (CC BY 4.0).
// To view the license terms, follow the link:
// https://creativecommons.org/licenses/by/4.0/legalcode
///////////////////////////////////////////////////////////////////////////////////////////////////////
//

#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region EventHandlers

//@skip-check data-exchange-load
Procedure BeforeWrite(Cancel, Replacing)
	
	RecordsCount = Count();
	
	For Cnt = 1 To RecordsCount Do
		
		IndexOf = RecordsCount - Cnt;
		
		If Not ValueIsFilled(ThisObject[IndexOf].Ref) Then
			Delete(IndexOf);
		EndIf;
		
	EndDo;
	
EndProcedure

#EndRegion

#EndIf


