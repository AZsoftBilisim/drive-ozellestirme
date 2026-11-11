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

Procedure FillCheckProcessing(Cancel, CheckedAttributes)
	CheckBasicCalendarUse(Cancel);
EndProcedure

Procedure OnWrite(Cancel)
	
	If DataExchange.Load Then
		Return;
	EndIf;
	
	CalendarSchedules.UpdateMultipleBusinessCalendarsUsage();
	
EndProcedure

#EndRegion

#Region Private

Procedure CheckBasicCalendarUse(Cancel)
	
	If Ref.IsEmpty() Or Not ValueIsFilled(BasicCalendar) Then
		Return;
	EndIf;
	
	// The reference to itself is prohibited.
	If Ref = BasicCalendar Then
		MessageText = NStr("vi = 'Không thể chọn cùng một lịch làm lịch cơ sở.';
							|ru = 'В качестве базового не может быть выбран тот же самый календарь.';
							|en = 'Cannot select a calendar as a source for itself.'; fa = 'Cannot select a calendar as a source for itself.';
							|it = 'Lo stesso calendario non può essere selezionato come base.';
							|pl = 'Jako podstawowy nie może być wybrany ten sam kalendarz.';
							|tr = 'Aynı takvim temel takvim olarak seçilemez.'");
		Common.MessageToUser(MessageText, , , "Object.BasicCalendar", Cancel);
		Return;
	EndIf;
	
	// If another calendar is based on this one, forbid populating it 
	// to avoid circular dependencies.
	
	Query = New Query;
	Query.SetParameter("Calendar", Ref);
	Query.Text = 
		"SELECT TOP 1
		|	Ref
		|FROM
		|	Catalog.BusinessCalendars AS BusinessCalendars
		|WHERE
		|	BusinessCalendars.BasicCalendar = &Calendar";
	QueryResult = Query.Execute();
	If QueryResult.IsEmpty() Then
		Return;
	EndIf;
	
	Selection = QueryResult.Select();
	Selection.Next();
	
	MessageText = StringFunctionsClientServer.SubstituteParametersToString(
		NStr("vi = 'Lịch là cơ sở đối với lịch ""%1"" và không thể phụ thuộc vào lịch khác.';
			|ru = 'Календарь уже является базовым для календаря ""%1"" и не может зависеть от другого.';
			|en = 'The calendar is a source for ""%1."" It cannot depend on another calendar.'; fa = 'The calendar is a source for ""%1."" It cannot depend on another calendar.';
			|it = 'Il calendario è già la base per il calendario ""%1"" e non può dipendere da un altro.';
			|pl = 'Kalendarz jest już podstawowym dla kalendarza ""%1"" i nie może zależeć od innego.';
			|tr = 'Takvim, ""%1"" takvimi için zaten temel takvimdir ve başka takvime bağlı olamaz.'"),
		Selection.Ref);
	Common.MessageToUser(MessageText, Selection.Ref, , "Object.BasicCalendar", Cancel);
	
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