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
	
	If ValueIsFilled(EndDate) And EndDate < StartDate Then
		MessageText = NStr("vi = 'Ngày kết thúc ít hơn ngày bắt đầu. Nhiều khả năng, ngày kết thúc là không chính xác.';
							|ru = 'Дата окончания меньше даты начала. Скорее всего, дата окончания заполнена неверно.';
							|en = 'The end date is earlier than the start date. Probably the end date is incorrect.'; fa = 'The end date is earlier than the start date. Probably the end date is incorrect.';
							|it = 'La data di fine è antecedente alla data di inizio. Molto probabilmente, la data di fine è stata compilata in modo errato.';
							|pl = 'Data zakończenia jest mniejsza od daty rozpoczęcia. Najprawdopodobniej, data zakończenia została wypełniona nieprawidłowo.';
							|tr = 'Bitiş tarihi başlangıç tarihinden küçük. Büyük bir ihtimalle, bitiş tarihi yanlış dolduruldu.'");
		Common.MessageToUser(MessageText, Ref, , , Cancel);
	EndIf;
	
EndProcedure

Procedure BeforeWrite(Cancel)
	
	If DataExchange.Load Then
		Return;
	EndIf;
	
	If IsFolder Then
		Return;
	EndIf;
	
	InfobaseUpdate.CheckObjectProcessed("Catalog.Calendars");
	
	If Not ConsiderHolidays Then
		// If the work schedule does not consider holidays, delete pre-holiday intervals.
		PreholidaySchedule = WorkSchedule.FindRows(New Structure("DayNumber", 0));
		For Each ScheduleString In PreholidaySchedule Do
			WorkSchedule.Delete(ScheduleString);
		EndDo;
	EndIf;
	
EndProcedure

Procedure OnWrite(Cancel)
	
	If DataExchange.Load Then
		Return;
	EndIf;
	
	If IsFolder Then
		Return;
	EndIf;
	
	// If the end date is not specified, it will be picked by the business calendar.
	FillingEndDate = EndDate;

	FillParameters = InformationRegisters.CalendarSchedules.ScheduleFillingParameters();
	FillParameters.FillingMethod = FillingMethod;
	FillParameters.FillingTemplate = FillingTemplate;
	FillParameters.BusinessCalendar = BusinessCalendar;
	FillParameters.ConsiderHolidays = ConsiderHolidays;
	FillParameters.ConsiderNonWorkPeriods = ConsiderNonWorkPeriods;
	FillParameters.StartingDate = StartingDate;
	DaysIncludedInSchedule = InformationRegisters.CalendarSchedules.DaysIncludedInSchedule(
		StartDate, FillingEndDate, FillParameters);
									
	InformationRegisters.CalendarSchedules.WriteScheduleDataToRegister(
		Ref, DaysIncludedInSchedule, StartDate, FillingEndDate);
	
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