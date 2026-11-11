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

Procedure BeforeWrite(Cancel, Replacing)
	
	// Disabling standard object registration mechanism.
	AdditionalProperties.Insert("DisableObjectChangeRecordMechanism");
	
	// Delete all nodes that were added automatically if the autoregistration flag was incorrectly set to True.
	DataExchange.Recipients.Clear();
	
	// Filling the SourceUUIDString by the source reference.
	If Count() > 0 Then
		
		If ThisObject[0].ObjectExportedByRef = True 
			Or Not ValueIsFilled(ThisObject[0]["SourceUUID"]) Then
			Return;
		EndIf;
		
		ThisObject[0]["SourceUUIDString"] = String(ThisObject[0]["SourceUUID"].UUID());
		
	EndIf;
	
	If DataExchange.Load
		Or Not ValueIsFilled(Filter.InfobaseNode.Value)
		Or Not ValueIsFilled(Filter.DestinationUUID.Value)
		Or Not Common.RefExists(Filter.InfobaseNode.Value) Then
		Return;
	EndIf;
	
	// The record set must be registered only in the node that is specified in the filter.
	DataExchange.Recipients.Add(Filter.InfobaseNode.Value);
	
EndProcedure

#EndRegion

#Else
Raise NStr("vi = 'Lần gọi không hợp lệ đối tượng trên Client.';
			|ru = 'Недопустимый вызов объекта на клиенте.';
			|en = 'Invalid object call on the client.'; fa = 'Invalid object call on the client.';
			|it = 'Chiamata di oggetto non valida sul client.';
			|pl = 'Niedozwolone wezwanie obiektu na kliencie.';
			|tr = 'İstemcide geçersiz nesne çağrısı.'");
#EndIf