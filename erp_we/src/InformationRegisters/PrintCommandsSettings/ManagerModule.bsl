///////////////////////////////////////////////////////////////////////////////////////////////////////
// Copyright (c) 2025, OOO 1C-Soft
// All rights reserved. This software and the related materials 
// are licensed under a Creative Commons Attribution 4.0 International license (CC BY 4.0).
// To view the license terms, follow the link:
// https://creativecommons.org/licenses/by/4.0/legalcode
///////////////////////////////////////////////////////////////////////////////////////////////////////
//

#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region Private

Function DisabledCommands(Owner) Export
	
	ListOfDisabledItems = New Map;
	
	If Not Common.SeparatedDataUsageAvailable() Then 
		Return ListOfDisabledItems;
	EndIf;
	
	QueryText =
	"SELECT
	|	PrintCommandsSettings.UUID AS UUID
	|FROM
	|	InformationRegister.PrintCommandsSettings AS PrintCommandsSettings
	|WHERE
	|	PrintCommandsSettings.Owner = &Owner
	|	AND NOT PrintCommandsSettings.Visible";
	
	Query = New Query(QueryText);
	Query.SetParameter("Owner", Owner);
	Selection = Query.Execute().Select();
	
	While Selection.Next() Do
		ListOfDisabledItems.Insert(Selection.UUID, True);
	EndDo;
	
	Return ListOfDisabledItems;
	
EndFunction

#EndRegion

#EndIf
