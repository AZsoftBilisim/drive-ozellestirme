///////////////////////////////////////////////////////////////////////////////////////////////////////
// Copyright (c) 2025, OOO 1C-Soft
// All rights reserved. This software and the related materials 
// are licensed under a Creative Commons Attribution 4.0 International license (CC BY 4.0).
// To view the license terms, follow the link:
// https://creativecommons.org/licenses/by/4.0/legalcode
///////////////////////////////////////////////////////////////////////////////////////////////////////
//

#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region Public

#Region InterfaceImplementation

// StandardSubsystems.Interactions

// The procedure generates participant list rows.
//
// Parameters:
//  Contacts  - Array - an array containing interaction participants.
//
Procedure FillContacts(Contacts) Export
	
	Interactions.FillContactsForMeeting(Contacts, Attendees);
	
EndProcedure

// End StandardSubsystems.Interactions

// StandardSubsystems.AccessManagement

// Parameters:
//   Table - See AccessManagement.AccessValuesSetsTable
//
Procedure FillAccessValuesSets(Table) Export
	
	InteractionsEvents.FillAccessValuesSets(ThisObject, Table);
	
EndProcedure

// End StandardSubsystems.AccessManagement

#EndRegion

#EndRegion

#Region EventHandlers

Procedure Filling(FillingData, FillingText, StandardProcessing)

	SetDefaultDates();
	Interactions.FillDefaultAttributes(ThisObject, FillingData);

EndProcedure

Procedure BeforeWrite(Cancel, WriteMode, PostingMode)
	
	If DataExchange.Load Then
		Return;
	EndIf;
	
	Interactions.GenerateParticipantsList(ThisObject);
	
EndProcedure

Procedure OnCopy(CopiedObject)
	
	SetDefaultDates();
	EmployeeResponsible    = Users.CurrentUser();
	Author            = Users.CurrentUser();
	
EndProcedure

Procedure FillCheckProcessing(Cancel, CheckedAttributes)

	If EndDate < StartDate Then

		Common.MessageToUser(
			NStr("vi = 'Ngày kết thúc không thể nhỏ hơn ngày bắt đầu.';
				|ru = 'Дата окончания не может быть меньше даты начала.';
				|en = 'End date cannot be earlier than Start date.'; fa = 'End date cannot be earlier than Start date.';
				|it = 'La data di termine non può essere antecedente alla data di inizio.';
				|pl = 'Data zakończenia nie może być mniejsza niż data rozpoczęcia.';
				|tr = 'Bitiş tarihi başlangıç tarihinden önce olamaz.'"),
			,
			"EndDate",
			,
			Cancel);

	EndIf;

EndProcedure

Procedure OnWrite(Cancel)
	
	If DataExchange.Load Then
		Return;
	EndIf;
	
	Interactions.OnWriteDocument(ThisObject);
	
EndProcedure

#EndRegion

#Region Private

Procedure SetDefaultDates()

	StartDate = CurrentSessionDate();
	StartDate = BegOfHour(StartDate) + ?(Minute(StartDate) < 30, 1800, 3600);
	EndDate = StartDate + 1800;

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