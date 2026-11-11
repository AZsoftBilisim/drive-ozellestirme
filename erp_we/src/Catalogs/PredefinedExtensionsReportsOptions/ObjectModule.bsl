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

Procedure BeforeWrite(Cancel)
	If AdditionalProperties.Property("PredefinedObjectsFilling") Then
		CheckPredefinedReportOptionFilling(Cancel);
	EndIf;
	If DataExchange.Load Then
		Return;
	EndIf;
	If Not AdditionalProperties.Property("PredefinedObjectsFilling") Then
		Raise NStr("vi = 'Danh mục ""Phương án định trước của báo cáo"" chỉ được thay đổi khi tự động điền dữ liệu báo cáo.';
					|ru = 'Справочник ""Предопределенные варианты отчетов"" изменяется только при автоматическом заполнении его данных.';
					|en = 'Predefined report options catalog is modified only during automatic population.'; fa = 'Predefined report options catalog is modified only during automatic population.';
					|it = 'Il manuale ""Opzioni predefinite dei report"" viene modificato solamente dopo la compilazione automatica dei suo dati.';
					|pl = 'Katalog ""Предопределенные варианты отчетов"" zmienia się tylko przy automatycznym wypełnieniu jego danych.';
					|tr = '""Öntanımlı rapor seçenekleri"" kataloğu sadece veriler otomatik doldurulduğunda değiştirilir.'");
	EndIf;
EndProcedure

// Basic validation of predefined report options.
Procedure CheckPredefinedReportOptionFilling(Cancel)
	If DeletionMark Then
		Return;
	EndIf;
	If Not ValueIsFilled(Report) Then
		Raise StringFunctionsClientServer.SubstituteParametersToString(NStr("vi = 'Chưa điền trường ""%1"".';
																			|ru = 'Не заполнено поле ""%1"".';
																			|en = 'Field %1 is required.'; fa = 'Field %1 is required.';
																			|it = 'Не заполнено поле ""%1"".';
																			|pl = 'Field %1 is required.';
																			|tr = '""%1"" alanı doldurulmadı.'"), "Report");
	EndIf;
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