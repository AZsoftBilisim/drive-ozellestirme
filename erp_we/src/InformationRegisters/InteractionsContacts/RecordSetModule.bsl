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
	
	If DataExchange.Load Then
		Return;
	EndIf;
	
	If Not Interactions.CalculateReviewedItems(AdditionalProperties) Then
		Return;
	EndIf;
	
	OldRecords = Common.SetRecordsFromDatabase(ThisObject, Replacing, "Contact");
	
	AdditionalProperties.Insert("RecordTable", OldRecords);
	
EndProcedure

Procedure OnWrite(Cancel, Replacing)
	
	If DataExchange.Load Then
		Return;
	EndIf;
	
	If Not Interactions.CalculateReviewedItems(AdditionalProperties) Then
		Return;
	EndIf;
	
	If Common.IsRecordSetDeletion(Replacing) Then
		NewRecords = Unload(New Array, "Contact");
	Else
		NewRecords = Unload(, "Contact");
	EndIf;
	
	Query = New Query;
	Query.Text = "
	|SELECT
	|	Old_Set.Contact AS Contact
	|INTO Old_Set
	|FROM
	|	&Old_Set AS Old_Set
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	NewSet.Contact AS Contact
	|INTO NewSet
	|FROM
	|	&NewSet AS NewSet
	|
	|INDEX BY
	|	Contact
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	NewSet.Contact AS CalculateBy
	|FROM
	|	NewSet AS NewSet
	|
	|UNION
	|
	|SELECT
	|	Old_Set.Contact
	|FROM
	|	Old_Set AS Old_Set";
	
	Query.SetParameter("Old_Set", AdditionalProperties.RecordTable);
	Query.SetParameter("NewSet",  NewRecords);
	Interactions.CalculateReviewedByContacts(Query.Execute().Unload())
	
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